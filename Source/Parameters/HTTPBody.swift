import CoreGraphics
import Foundation

/// Represents an HTTP request body in various formats.
///
/// `Body` supports multiple content types, including raw `Data`, `Encodable` models, multipart forms,
/// x-www-form-urlencoded, JSON, and platform-specific image formats. It provides utilities for encoding
/// the body and generating appropriate headers for transmission.
public enum HTTPBody: ExpressibleByNilLiteral {
    /// Internal encoding control characters.
    public enum EncodingCharacters {
        static let crlf = "\r\n"
    }

    /// An empty request body.
    case empty
    /// Raw binary body data.
    case data(Data, contentType: String?)
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

public extension HTTPBody {
    /// Encodable body
    static func encode(_ encodable: some Encodable) -> Self {
        return .encode(encodable, with: JSONEncoder.init)
    }

    /// Encodable body
    static func encode(_ encodable: some Encodable, with encoding: @escaping @autoclosure () -> JSONEncoder) -> Self {
        return .encode(encodable, with: encoding)
    }

    static func data(_ data: Data) -> Self {
        return .data(data, contentType: nil)
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
}

/// Encodes an optional `Body` into an `EncodedBody`, returning an empty result if `nil`.
public extension HTTPBody? {
    /// Encodes optional body value into concrete body bytes and headers.
    ///
    /// Returns an empty body when optional is `nil`.
    func encode() throws -> EncodedBody {
        return try (self?.encode()) ?? .init(httpBody: nil, [:])
    }
}

public extension HTTPBody {
    /// Encodes the body into `Data` and generates the appropriate `Content-Type` and `Content-Length` headers.
    ///
    /// - Throws: An error if encoding fails.
    /// - Returns: An `EncodedBody` containing the HTTP body and headers.
    func encode() throws -> EncodedBody {
        switch self {
        case .empty:
            return .init(httpBody: .init(), [:])

        case let .data(data, contentType):
            if let contentType {
                return .init(httpBody: data, [
                    "Content-Type": contentType,
                    "Content-Length": "\(data.count)"
                ])
            }
            return .init(httpBody: data, [
                "Content-Length": "\(data.count)"
            ])

        case let .image(image):
            return try image.encode()

        case let .encode(object, encoder):
            let encoder = encoder()
            let data = try encoder.encode(object)
            return .init(httpBody: data, [
                "Content-Type": "application/json",
                "Content-Length": "\(data.count)"
            ])

        case let .json(json, options):
            // sometimes it crashes the app on 'try JSONSerialization...' without that check
            guard JSONSerialization.isValidJSONObject(json) else {
                throw RequestEncodingError.invalidJSON
            }

            let data = try JSONSerialization.data(withJSONObject: json, options: options)
            return .init(httpBody: data, [
                "Content-Type": "application/json",
                "Content-Length": "\(data.count)"
            ])

        case let .form(form):
            let data = form.encode()
            return .init(httpBody: data, [
                "Content-Type": form.contentType,
                "Content-Length": "\(form.contentLength)"
            ])

        case let .xform(parameters):
            let data = HTTPBody.XFormEncoder.encodeParameters(parameters: parameters)
            return .init(httpBody: data, [
                "Content-Type": "application/x-www-form-urlencoded",
                "Content-Length": "\(data?.count ?? 0)"
            ])
        }
    }
}

#if swift(>=6.0)
extension HTTPBody: @unchecked Sendable {}
#endif
