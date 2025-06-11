import CoreGraphics
import Foundation

/// Represents an HTTP request body in various formats.
///
/// `Body` supports multiple content types, including raw `Data`, `Encodable` models, multipart forms,
/// x-www-form-urlencoded, JSON, and platform-specific image formats. It provides utilities for encoding
/// the body and generating appropriate headers for transmission.
public enum Body: ExpressibleByNilLiteral {
    /// Represents supported image formats for use in HTTP body payloads.
    public enum ImageFormat: Hashable {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        case png(SmartImage)
        #endif

        #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
        case jpeg(SmartImage, compressionQuality: CGFloat)
        #endif
    }

    enum EncodingCharacters {
        static let crlf = "\r\n"
    }

    /// An empty request body.
    case empty
    /// Raw binary body data.
    case data(Data)
    /// An image formatted as PNG or JPEG.
    case image(ImageFormat)
    /// A body created from an `Encodable` object and custom encoder.
    case encode(any Encodable, with: () -> JSONEncoder)
    /// A multipart/form-data body.
    case form(MultipartForm)
    /// A body encoded using application/x-www-form-urlencoded.
    case xform([String: Any])
    /// A JSON object to be serialized for the request body.
    case json(Any, options: JSONSerialization.WritingOptions)
}

public extension Body {
    /// Encodable body
    static func encode(_ encodable: some Encodable) -> Self {
        return .encode(encodable, with: { .init() })
    }

    /// Encodable body
    static func encode(_ encodable: some Encodable, with encoding: @escaping @autoclosure () -> JSONEncoder) -> Self {
        return .encode(encodable, with: encoding)
    }

    /// ExpressibleByNilLiteral
    init(nilLiteral: ()) {
        self = .empty
    }

    /// Encodes an `Encodable` object into x-www-form-urlencoded format using an optional encoder.
    ///
    /// - Parameters:
    ///   - object: The object to encode.
    ///   - encoder: An optional `JSONEncoder` to convert the object before transformation.
    /// - Throws: `RequestEncodingError.invalidJSON` if the object can't be converted.
    static func xform(_ object: some Encodable, encoder: JSONEncoder? = nil) throws -> Self {
        let encoder = encoder ?? .init()
        let originalData = try encoder.encode(object)
        let json = try JSONSerialization.jsonObject(with: originalData)

        if let parameters = json as? [String: Any] {
            return .xform(parameters)
        }
        throw RequestEncodingError.invalidJSON
    }

    @available(*, deprecated, renamed: "encode", message: "Use 'encode' instead.")
    init(_ encodable: some Encodable) {
        self = .encode(encodable)
    }
}

/// Encodes an optional `Body` into an `EncodedBody`, returning an empty result if `nil`.
public extension Body? {
    func encode() throws -> Body.EncodedBody {
        return try (self?.encode()) ?? .init(httpBody: nil, [:])
    }
}

public extension Body {
    /// Represents the result of encoding a `Body` instance into data and HTTP headers.
    struct EncodedBody {
        public let httpBody: Data?
        public let headers: HeaderFields

        public init(httpBody: Data?, _ headers: HeaderFields) {
            self.httpBody = httpBody
            self.headers = headers
        }

        /// Populates the given URL request with the encoded body and its associated headers.
        ///
        /// - Parameter request: The request to modify.
        public func fill(_ request: inout URLRequest) {
            request.httpBody = httpBody
            for item in headers {
                if request.value(forHTTPHeaderField: item.key) == nil {
                    request.setValue(item.value, forHTTPHeaderField: item.key)
                }
            }
        }
    }

    /// Encodes the body into `Data` and generates the appropriate `Content-Type` and `Content-Length` headers.
    ///
    /// - Throws: An error if encoding fails.
    /// - Returns: An `EncodedBody` containing the HTTP body and headers.
    func encode() throws -> EncodedBody {
        switch self {
        case .empty:
            return .init(httpBody: .init(), [:])

        case .data(let data):
            return .init(httpBody: data, [
                "Content-Length": "\(data.count)"
            ])

        case .image(let image):
            let data: Data
            switch image {
            #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            case .png(let image):
                data = try PlatformImage(image).pngData().unwrap(orThrow: RequestEncodingError.cantEncodeImage)
            #endif

            #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
            case .jpeg(let image, let quality):
                data = try PlatformImage(image).jpegData(compressionQuality: quality).unwrap(orThrow: RequestEncodingError.cantEncodeImage)
            #endif
            }
            return .init(httpBody: data, [
                "Content-Type": "application/image",
                "Content-Length": "\(data.count)"
            ])

        case .encode(let object, let encoder):
            let encoder = encoder()
            let data = try encoder.encode(object)
            return .init(httpBody: data, [
                "Content-Type": "application/json",
                "Content-Length": "\(data.count)"
            ])

        case .json(let json, let options):
            // sometimes it crashes the app on 'try JSONSerialization...' without that check
            guard JSONSerialization.isValidJSONObject(json) else {
                throw RequestEncodingError.invalidJSON
            }

            let data = try JSONSerialization.data(withJSONObject: json, options: options)
            return .init(httpBody: data, [
                "Content-Type": "application/json",
                "Content-Length": "\(data.count)"
            ])

        case .form(let form):
            let data = form.encode()
            return .init(httpBody: data, [
                "Content-Type": form.contentType,
                "Content-Length": "\(form.contentLength)"
            ])

        case .xform(let parameters):
            let data = Body.XFormEncoder.encodeParameters(parameters: parameters)
            return .init(httpBody: data, [
                "Content-Type": "application/x-www-form-urlencoded",
                "Content-Length": "\(data?.count ?? 0)"
            ])
        }
    }
}

#if swift(>=6.0)
extension Body: @unchecked Sendable {}
extension Body.ImageFormat: @unchecked Sendable {}
extension Body.EncodedBody: Sendable {}
#endif
