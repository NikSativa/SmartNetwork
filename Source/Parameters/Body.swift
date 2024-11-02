import CoreGraphics
import Foundation

/// Type representing request body. It can be empty, data, image, encodable, form, xform, or json.
public enum Body: ExpressibleByNilLiteral {
    public enum ImageFormat: Hashable {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        case png(Image)
        #endif

        #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
        case jpeg(Image, compressionQuality: CGFloat)
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

extension Optional where Wrapped == Body {
    func fill(_ tempRequest: inout URLRequest) throws {
        switch self {
        case .none:
            tempRequest.httpBody = nil
        case .empty:
            tempRequest.httpBody = Data()
        case .data(let data):
            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
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

            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.addValue("application/image", forHTTPHeaderField: "Content-Type")
            }

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        case .encode(let object, let encoder):
            let encoder = encoder()
            let data = try encoder.encode(object)

            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        case .json(let json, let options):
            // sometimes it crashes the app on 'try JSONSerialization...' without that check
            guard JSONSerialization.isValidJSONObject(json) else {
                throw RequestEncodingError.invalidJSON
            }
            let data = try JSONSerialization.data(withJSONObject: json, options: options)

            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        case .form(let form):
            tempRequest.httpBody = form.encode()

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            }

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(form.contentLength)", forHTTPHeaderField: "Content-Length")
            }
        case .xform(let parameters):
            let data = Body.XFormEncoder.encodeParameters(parameters: parameters)
            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }

            if let data,
               tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        }
    }
}

#if swift(>=6.0)
extension Body: @unchecked Sendable {}
extension Body.ImageFormat: @unchecked Sendable {}
#endif
