import CoreGraphics
import Foundation

public enum Body: ExpressibleByNilLiteral {
    public enum ImageFormat: Equatable {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        case png(Image)
        #endif

        #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
        case jpeg(Image, compressionQuality: CGFloat)
        #endif
    }

    public struct Form: Equatable {
        public enum Name: String {
            case file
            case photo
        }

        public enum MimeType: String {
            case binary = "application/x-binary"
            case jpg = "image/jpg"
            case png = "image/png"
        }

        public let parameters: [String: String]
        public let boundary: String
        public let mimeType: MimeType
        public let name: Name
        public let fileName: String
        public let data: Data

        public init(parameters: [String: String] = [:],
                    boundary: String,
                    mimeType: MimeType,
                    name: Name,
                    fileName: String,
                    data: Data) {
            self.parameters = parameters
            self.boundary = boundary
            self.mimeType = mimeType
            self.fileName = fileName
            self.data = data
            self.name = name
        }
    }

    case empty
    case data(Data)
    case image(ImageFormat)
    case encodable(any Encodable)
    /// form-data
    case form(Form)
    /// x-www-form-urlencoded
    case xform([String: Any])
    /// JSONSerialization
    case json(Any, options: JSONSerialization.WritingOptions)

    public init(_ encodable: some Encodable) {
        self = .encodable(encodable)
    }

    /// ExpressibleByNilLiteral
    public init(nilLiteral: ()) {
        self = .empty
    }
}

extension Body {
    func fill(_ tempRequest: inout URLRequest, encoder: @autoclosure () -> JSONEncoder) throws {
        switch self {
        case .empty:
            break
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
        case .encodable(let object):
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
            let data = FormEncoder.createBody(form)
            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.setValue("multipart/form-data; boundary=\(form.boundary)", forHTTPHeaderField: "Content-Type")
            }

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        case .xform(let parameters):
            let data = XFormEncoder.encodeParameters(parameters: parameters)
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

public extension Body {
    static func xform(_ object: some Encodable, encoder: JSONEncoder) throws -> Self {
        let originalData = try encoder.encode(object)
        let json = try JSONSerialization.jsonObject(with: originalData)

        if let parameters = json as? [String: Any] {
            return .xform(parameters)
        }
        throw RequestEncodingError.invalidJSON
    }
}

private enum FormEncoder {
    static func createBody(_ form: Body.Form, isLogging: Bool = false) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(form.boundary)\r\n"

        for (key, value) in form.parameters {
            appendString(&body, boundaryPrefix)
            appendString(&body, "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            appendString(&body, "\(value)\r\n")
        }

        appendString(&body, boundaryPrefix)
        appendString(&body, "Content-Disposition: form-data; name=\"\(form.name.rawValue)\"; filename=\"\(form.fileName)\"\r\n")
        appendString(&body, "Content-Type: \(form.mimeType.rawValue)\r\n\r\n")

        if isLogging {
            appendString(&body, form.data.base64EncodedString())
        } else {
            body.append(form.data)
        }

        appendString(&body, "\r\n")
        appendString(&body, "--".appending(form.boundary.appending("--")))
        appendString(&body, "\r\n")

        return body
    }

    private static func appendString(_ mdata: inout Data, _ string: String) {
        if let data = string.data(using: .utf8, allowLossyConversion: false) {
            mdata.append(data)
        }
    }
}

private enum XFormEncoder {
    private static func percentEscapeString(_ string: String) -> String? {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")

        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)?
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }

    private static func percentEscapeString(_ value: Any) -> String? {
        switch value {
        case let value as String:
            return percentEscapeString(value)
        case let value as Int:
            return percentEscapeString("\(value)")
        default:
            return percentEscapeString("\(String(describing: value))")
        }
    }

    static func encodeParameters(parameters: [String: Any]) -> Data? {
        return parameters
            .map { key, value -> String in
                return [key, percentEscapeString(value)].compactMap { $0 }.joined(separator: "=")
            }
            .joined(separator: "&").data(using: String.Encoding.utf8)
    }
}

#if swift(>=6.0)
extension Body: @unchecked Sendable {}
extension Body.ImageFormat: @unchecked Sendable {}
extension Body.Form: Sendable {}
extension Body.Form.Name: Sendable {}
extension Body.Form.MimeType: Sendable {}
#endif
