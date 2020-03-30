import Foundation
import UIKit

public enum Body {
    public struct AnyEncodable: Encodable {
        private let encodable: Encodable

        public init(_ encodable: Encodable) {
            self.encodable = encodable
        }

        public func encode(to encoder: Encoder) throws {
            try encodable.encode(to: encoder)
        }
    }

    public enum Image: Equatable {
        case png(UIImage)
        case jpeg(UIImage, compressionQuality: CGFloat)
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
    case json(Any)
    case data(Data)
    case image(Image)
    case encodable(AnyEncodable)
    case form(Form)  // form-data
    case xform([String: Any]) // x-www-form-urlencoded

    public init<T: Encodable>(with object: T) {
        self = .encodable(AnyEncodable(object))
    }
}

extension Body {
    func fill(_ tempRequest: inout URLRequest) throws {
        switch self {
        case .empty:
            break
        case .data(let data):
            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        case .json(let json):
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: [])
                tempRequest.httpBody = data
                Configuration.log("JSON object:" + String(describing: try? JSONSerialization.jsonObject(with: data, options: [])))

                if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    tempRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                }

                if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                    tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
                }
            } catch let error {
                throw EncodingError.body(.cantSerialize(error))
            }
        case .image(let image):
            let data: Data
            switch image {
            case .png(let image):
                data = try image.pngData().unwrap(EncodingError.body(.cantEncodeImage))
            case .jpeg(let image, let quality):
                data = try image.jpegData(compressionQuality: quality).unwrap(EncodingError.body(.cantEncodeImage))
            }

            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.addValue("application/image", forHTTPHeaderField: "Content-Type")
            }

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        case .encodable(let object):
            let encoder = (type(of: object) as? CustomizedEncodable.Type)?.encoder ?? JSONEncoder()
            do {
                let data = try encoder.encode(object)

                tempRequest.httpBody = data
                Configuration.log("Encodable object:" + String(describing: try? JSONSerialization.jsonObject(with: data, options: [])))

                if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    tempRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                }

                if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                    tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
                }
            } catch let error {
                throw EncodingError.body(.cantEncode(error))
            }
        case .form(let form):
            let data = FormEncoder.createBody(form)
            Configuration.log(String(data: FormEncoder.createBody(form, isLogging: true), encoding: .utf8) ?? "")

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

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        }
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
    private static func percentEscapeString(_ string: String) -> String {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")

        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)?
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil) ?? ""
    }

    private static func percentEscapeString(_ value: Any) -> String {
        switch value {
        case let value as String:
            return percentEscapeString(value)
        case let value as Int:
            return percentEscapeString("\(value)")
        default:
            return percentEscapeString("\(String(describing: value))")
        }
    }

    static func encodeParameters(parameters: [String: Any]) -> Data {
        return parameters
            .map { (key, value) -> String in
                return "\(key)=\(self.percentEscapeString(value))"
        }
        .joined(separator: "&").data(using: String.Encoding.utf8) ?? Data()
    }
}

private extension Optional {
    func unwrap<T: Error>(_ error: T) throws -> Wrapped {
        switch self {
        case .none:
            throw error
        case .some(let t):
            return t
        }
    }
}
