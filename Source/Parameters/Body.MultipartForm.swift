import Foundation

// MARK: - Body.MultipartForm

/// Encodes multipart/form-data for use in HTTP requests with file uploads.
///
/// This class builds a multipart body using configurable boundaries and headers, allowing
/// the inclusion of multiple parts (e.g., files or fields) with appropriate MIME types and metadata.
public extension HTTPBody {
    /// Builder for `multipart/form-data` request bodies.
    final class MultipartForm {
        /// The `Content-Type` header string used for multipart/form-data requests.
        ///
        /// Includes the dynamically generated boundary.
        var contentType: String {
            return "multipart/form-data; boundary=\(boundary.rawValue)"
        }

        /// The total size in bytes of the body content, excluding boundary markers.
        var contentLength: UInt64 {
            return bodyParts.reduce(0) { partialResult, part in
                let headersLength = UInt64(encodeHeaders(for: part).count)
                let bodyLength = UInt64(part.data.count)
                return partialResult + headersLength + bodyLength
            }
        }

        /// The boundary used to separate the body parts in the encoded form data.
        private let boundary: Boundary

        /// The body parts.
        private var bodyParts: [BodyPart]

        /// Creates an instance.
        ///
        /// - Parameters:
        ///   - boundary: Boundary `String` used to separate body parts.
        public init(boundary: Boundary? = nil,
                    parts: [DataContent] = []) {
            self.boundary = boundary ?? .generateRandom()
            self.bodyParts = []

            for part in parts {
                append(part.data, withName: part.name, fileName: part.fileName, mimeType: part.mimeType)
            }
        }

        /// Appends a new part to the multipart body.
        ///
        /// - Parameters:
        ///   - data: The raw data to include.
        ///   - name: The form field name.
        ///   - fileName: An optional file name to include in the header.
        ///   - mimeType: An optional MIME type to include in the header.
        public func append(_ data: Data, withName name: Name, fileName: String? = nil, mimeType: MimeType? = nil) {
            let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
            let bodyPart = BodyPart(headers: headers, data: data)
            bodyParts.append(bodyPart)
        }

        /// Combines all appended parts into a single `Data` object with boundaries and headers.
        ///
        /// - Returns: Encoded multipart form body as `Data`.
        internal func encode() -> Data {
            var encoded = Data()

            bodyParts.first?.hasInitialBoundary = true
            bodyParts.last?.hasFinalBoundary = true

            for bodyPart in bodyParts {
                let encodedData = encode(bodyPart)
                encoded.append(encodedData)
            }

            return encoded
        }

        private func encode(_ bodyPart: BodyPart) -> Data {
            var encoded = Data()

            let initialData = bodyPart.hasInitialBoundary ? initialBoundaryData() : encapsulatedBoundaryData()
            encoded.append(initialData)

            let headerData = encodeHeaders(for: bodyPart)
            encoded.append(headerData)

            let bodyStreamData = bodyPart.data
            encoded.append(bodyStreamData)

            if bodyPart.hasFinalBoundary {
                encoded.append(finalBoundaryData())
            }

            return encoded
        }

        private func encodeHeaders(for bodyPart: BodyPart) -> Data {
            let headerText = bodyPart.headers
                .map { "\($0.name): \($0.value)\(EncodingCharacters.crlf)" }
                .joined()
                + EncodingCharacters.crlf

            return Data(headerText.utf8)
        }

        private func contentHeaders(withName name: Name, fileName: String? = nil, mimeType: MimeType? = nil) -> [Header] {
            var disposition = "form-data; name=\"\(name.rawValue)\""
            if let fileName {
                disposition += "; filename=\"\(fileName)\""
            }

            var headers: [Header] = [
                .init(name: "Content-Disposition", value: disposition)
            ]

            if let mimeType {
                headers.append(.init(name: "Content-Type", value: mimeType.rawValue))
            }

            return headers
        }

        private func initialBoundaryData() -> Data {
            BoundaryGenerator.boundaryData(forBoundaryType: .initial, boundary: boundary)
        }

        private func encapsulatedBoundaryData() -> Data {
            BoundaryGenerator.boundaryData(forBoundaryType: .encapsulated, boundary: boundary)
        }

        private func finalBoundaryData() -> Data {
            BoundaryGenerator.boundaryData(forBoundaryType: .final, boundary: boundary)
        }
    }
}

// MARK: - Body.MultipartForm + Equatable

extension HTTPBody.MultipartForm: Equatable {
    public static func ==(lhs: HTTPBody.MultipartForm, rhs: HTTPBody.MultipartForm) -> Bool {
        return lhs.boundary == rhs.boundary && lhs.bodyParts == rhs.bodyParts
    }
}

// MARK: - Body.MultipartForm.Boundary

public extension HTTPBody.MultipartForm {
    /// Represents the boundary string used to separate parts in multipart data.
    struct Boundary: RawRepresentable, ExpressibleByStringLiteral, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        /// Generates a random boundary string suitable for multipart requests.
        public static func generateRandom() -> Self {
            let name = ["smartnetwork", "boundary", randomBoundaryKey()].joined(separator: ".")
            return .init(rawValue: name)
        }

        /// Builds a boundary from a partial prefix.
        ///
        /// - Parameters:
        ///   - part: Prefix part for the boundary.
        ///   - hasRandomLastPart: Appends random suffix when `true`.
        public static func partial(_ part: String, hasRandomLastPart: Bool = true) -> Self {
            var parts = [part, "boundary"]
            if hasRandomLastPart {
                parts.append(randomBoundaryKey())
            }
            let name = parts.joined(separator: ".")
            return .init(rawValue: name)
        }

        /// Builds a boundary from custom parts.
        ///
        /// - Parameters:
        ///   - parts: Ordered boundary parts.
        ///   - hasRandomLastPart: Appends random suffix when `true`.
        public static func full(_ parts: [String], hasRandomLastPart: Bool = true) -> Self {
            var parts = parts
            if hasRandomLastPart {
                parts.append(randomBoundaryKey())
            }
            let name = parts.joined(separator: ".")
            return .init(rawValue: name)
        }

        private static func randomBoundaryKey() -> String {
            let first = UInt32.random(in: UInt32.min...UInt32.max)
            let second = UInt32.random(in: UInt32.min...UInt32.max)

            return String(format: "%08x%08x", first, second)
        }
    }

    /// Represents the name of a multipart form field.
    struct Name: RawRepresentable, ExpressibleByStringLiteral, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        /// Conventional multipart field name used for generic file uploads.
        public static let file: Self = "file"
        /// Conventional multipart field name used for photos.
        public static let photo: Self = "photo"
        /// Conventional multipart field name used for images.
        public static let image: Self = "image"
    }

    /// Represents a MIME type for a form part (e.g., image/jpeg).
    struct MimeType: RawRepresentable, ExpressibleByStringLiteral, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        /// Generic binary payload MIME type.
        public static let binary: Self = "application/x-binary"
        /// JPEG image MIME type.
        public static let jpg: Self = "image/jpg"
        /// PNG image MIME type.
        public static let png: Self = "image/png"
    }

    /// Represents a single unit of data to include in a multipart form upload.
    struct DataContent: Hashable {
        /// Form field name.
        public let name: Name
        /// Optional filename advertised in `Content-Disposition`.
        public let fileName: String?
        /// Optional MIME type for part content.
        public let mimeType: MimeType?
        /// Raw part payload.
        public let data: Data

        /// Creates multipart part metadata using strongly typed name and MIME type.
        ///
        /// - Parameters:
        ///   - name: Form field name.
        ///   - fileName: Optional filename.
        ///   - mimeType: Optional MIME type.
        ///   - data: Raw payload bytes.
        public init(name: Name,
                    fileName: String? = nil,
                    mimeType: MimeType? = nil,
                    data: Data) {
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
            self.data = data
        }

        /// Creates multipart part metadata using raw string name and MIME type.
        ///
        /// - Parameters:
        ///   - name: Form field name.
        ///   - fileName: Optional filename.
        ///   - mimeType: Optional MIME type string.
        ///   - data: Raw payload bytes.
        public init(name: String,
                    fileName: String? = nil,
                    mimeType: String? = nil,
                    data: Data) {
            self.name = .init(rawValue: name)
            self.fileName = fileName
            self.mimeType = mimeType.map(MimeType.init(rawValue:))
            self.data = data
        }
    }
}

private extension HTTPBody.MultipartForm {
    enum BoundaryGenerator {
        enum BoundaryType {
            case initial
            case encapsulated
            case final
        }

        static func boundaryData(forBoundaryType boundaryType: BoundaryType, boundary: Boundary) -> Data {
            let boundary: String = boundary.rawValue
            let boundaryText: String
            let crlf = HTTPBody.EncodingCharacters.crlf

            switch boundaryType {
            case .initial:
                boundaryText = "--\(boundary)\(crlf)"
            case .encapsulated:
                boundaryText = "\(crlf)--\(boundary)\(crlf)"
            case .final:
                boundaryText = "\(crlf)--\(boundary)--\(crlf)"
            }

            return Data(boundaryText.utf8)
        }
    }

    struct Header: Equatable, Hashable {
        let name: String
        let value: String
    }

    final class BodyPart: Equatable {
        let headers: [Header]
        let data: Data
        var hasInitialBoundary = false
        var hasFinalBoundary = false

        init(headers: [Header], data: Data) {
            self.headers = headers
            self.data = data
        }

        static func ==(lhs: HTTPBody.MultipartForm.BodyPart, rhs: HTTPBody.MultipartForm.BodyPart) -> Bool {
            return lhs.headers == rhs.headers && lhs.data == rhs.data
        }
    }
}

#if swift(>=6.0)
extension HTTPBody.MultipartForm: @unchecked Sendable {}
extension HTTPBody.MultipartForm.Name: Sendable {}
extension HTTPBody.MultipartForm.Header: Sendable {}
extension HTTPBody.MultipartForm.MimeType: Sendable {}
extension HTTPBody.MultipartForm.Boundary: Sendable {}
extension HTTPBody.MultipartForm.DataContent: Sendable {}
extension HTTPBody.MultipartForm.BodyPart: @unchecked Sendable {}
#endif
