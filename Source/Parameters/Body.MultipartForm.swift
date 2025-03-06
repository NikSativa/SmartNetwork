import Foundation

// MARK: - Body.MultipartForm

public extension Body {
    final class MultipartForm {
        /// The `Content-Type` header value containing the boundary used to generate the `multipart/form-data`.
        var contentType: String {
            return "multipart/form-data; boundary=\(boundary.rawValue)"
        }

        /// The content length of all body parts used to generate the `multipart/form-data` not including the boundaries.
        var contentLength: UInt64 {
            return bodyParts.reduce(0) { $0 + UInt64($1.data.count) }
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

        /// Creates a body part from the data and appends it to the instance.
        ///
        /// The body part data will be encoded using the following format:
        ///
        /// - `Content-Disposition: form-data; name=#{name}; filename=#{filename}` (HTTP Header)
        /// - `Content-Type: #{mimeType}` (HTTP Header)
        /// - Encoded file data
        /// - Multipart form boundary
        ///
        /// - Parameters:
        ///   - data:     `Data` to encoding into the instance.
        ///   - name:     Name to associate with the `Data` in the `Content-Disposition` HTTP header.
        ///   - fileName: Filename to associate with the `Data` in the `Content-Disposition` HTTP header.
        ///   - mimeType: MIME type to associate with the data in the `Content-Type` HTTP header.
        public func append(_ data: Data, withName name: Name, fileName: String? = nil, mimeType: MimeType? = nil) {
            let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
            let bodyPart = BodyPart(headers: headers, data: data)
            bodyParts.append(bodyPart)
        }

        /// Encodes all appended body parts into a single `Data` value.
        ///
        /// - Returns: The encoded `Data`, if encoding is successful.
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
            let headerText = bodyPart.headers.map { "\($0.name): \($0.value)\(EncodingCharacters.crlf)" }
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

extension Body.MultipartForm: Equatable {
    public static func ==(lhs: Body.MultipartForm, rhs: Body.MultipartForm) -> Bool {
        return lhs.boundary == rhs.boundary && lhs.bodyParts == rhs.bodyParts
    }
}

// MARK: - Body.MultipartForm.Boundary

public extension Body.MultipartForm {
    struct Boundary: RawRepresentable, ExpressibleByStringLiteral, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        public static func generateRandom() -> Self {
            let name = ["smartnetwork", "boundary", randomBoundaryKey()].joined(separator: ".")
            return .init(rawValue: name)
        }

        public static func partial(_ part: String, hasRandomLastPart: Bool = true) -> Self {
            var parts = [part, "boundary"]
            if hasRandomLastPart {
                parts.append(randomBoundaryKey())
            }
            let name = parts.joined(separator: ".")
            return .init(rawValue: name)
        }

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

    struct Name: RawRepresentable, ExpressibleByStringLiteral, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        public static let file: Self = "file"
        public static let photo: Self = "photo"
        public static let image: Self = "image"
    }

    struct MimeType: RawRepresentable, ExpressibleByStringLiteral, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        public static let binary: Self = "application/x-binary"
        public static let jpg: Self = "image/jpg"
        public static let png: Self = "image/png"
    }

    struct DataContent: Hashable {
        public let name: Name
        public let fileName: String?
        public let mimeType: MimeType?
        public let data: Data

        public init(name: Name,
                    fileName: String? = nil,
                    mimeType: MimeType? = nil,
                    data: Data) {
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
            self.data = data
        }

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

private extension Body.MultipartForm {
    enum BoundaryGenerator {
        enum BoundaryType {
            case initial
            case encapsulated
            case final
        }

        static func boundaryData(forBoundaryType boundaryType: BoundaryType, boundary: Boundary) -> Data {
            let boundary: String = boundary.rawValue
            let boundaryText: String
            let crlf = Body.EncodingCharacters.crlf

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

        static func ==(lhs: Body.MultipartForm.BodyPart, rhs: Body.MultipartForm.BodyPart) -> Bool {
            return lhs.headers == rhs.headers && lhs.data == rhs.data
        }
    }
}

#if swift(>=6.0)
extension Body.MultipartForm: @unchecked Sendable {}
extension Body.MultipartForm.Name: Sendable {}
extension Body.MultipartForm.Header: Sendable {}
extension Body.MultipartForm.MimeType: Sendable {}
extension Body.MultipartForm.Boundary: Sendable {}
extension Body.MultipartForm.DataContent: Sendable {}
extension Body.MultipartForm.BodyPart: @unchecked Sendable {}
#endif
