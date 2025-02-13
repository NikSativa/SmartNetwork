import CoreGraphics
import Foundation

/// Type representing request body. It can be empty, data, image, encodable, form, xform, or json.
public enum Body: ExpressibleByNilLiteral {
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

    /// Empty body
    case empty
    /// Data body
    case data(Data)
    /// Image body
    case image(ImageFormat)
    /// Encodable body
    case encode(any Encodable, with: () -> JSONEncoder)
    /// form-data
    case form(MultipartForm)
    /// x-www-form-urlencoded
    case xform([String: Any])
    /// JSONSerialization
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

    /// x-www-form-urlencoded from ``Encodable`` object
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

public extension Optional where Wrapped == Body {
    func encode() throws -> Body.EncodedBody {
        return try (self?.encode()) ?? .init(httpBody: nil, [:])
    }
}

public extension Body {
    struct EncodedBody {
        public let httpBody: Data?
        public let headers: HeaderFields

        public init(httpBody: Data?, _ headers: HeaderFields) {
            self.httpBody = httpBody
            self.headers = headers
        }

        public func fill(_ request: inout URLRequest) {
            request.httpBody = httpBody
            for item in headers {
                if request.value(forHTTPHeaderField: item.key) == nil {
                    request.setValue(item.value, forHTTPHeaderField: item.key)
                }
            }
        }
    }

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
