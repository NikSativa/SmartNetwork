import CoreGraphics
import Foundation

public enum Body {
    public enum Image: Equatable {
        case png(NRequest.Image)
        #if !os(macOS)
        case jpeg(NRequest.Image, compressionQuality: CGFloat)
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
    case image(Image)
    case encodable(any Encodable)
    case form(Form) // form-data
    case xform([String: Any]) // x-www-form-urlencoded
}

extension Body {
    private func tolog(_ isLoggingEnabled: Bool,
                       file: String = #file,
                       method: String = #function,
                       line: Int = #line,
                       _ text: () -> String) {
        guard isLoggingEnabled else {
            return
        }

        Logger.log(text(),
                   file: file,
                   method: method,
                   line: line)
    }

    func fill(_ tempRequest: inout URLRequest, isLoggingEnabled: Bool, encoder: @autoclosure () -> JSONEncoder) throws {
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
            case .png(let image):
                data = try PlatformImage(image).pngData().unwrap(orThrow: EncodingError.cantEncodeImage)
            #if !os(macOS)
            case .jpeg(let image, let quality):
                data = try PlatformImage(image).jpegData(compressionQuality: quality).unwrap(orThrow: EncodingError.cantEncodeImage)
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
            do {
                let data = try encoder.encode(object)

                tempRequest.httpBody = data
                tolog(isLoggingEnabled) {
                    let res = "Encodable object:\n" + (String(data: data, encoding: .utf8) ?? "<empty>")
                    return res
                }

                if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    tempRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                }

                if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                    tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
                }
            } catch {
                throw EncodingError.generic(.init(error))
            }
        case .form(let form):
            let data = FormEncoder.createBody(form)
            tolog(isLoggingEnabled) {
                let data = FormEncoder.createBody(form, isLogging: true)
                return String(data: data, encoding: .utf8) ?? ""
            }

            tempRequest.httpBody = data

            if tempRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                tempRequest.setValue("multipart/form-data; boundary=\(form.boundary)", forHTTPHeaderField: "Content-Type")
            }

            if tempRequest.value(forHTTPHeaderField: "Content-Length") == nil {
                tempRequest.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            }
        case .xform(let parameters):
            let data = XFormEncoder.encodeParameters(parameters: parameters)
            tolog(isLoggingEnabled) {
                return "Body: " + (String(data: data, encoding: .utf8) ?? "")
            }

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

public extension Body {
    static func xform(_ object: some Encodable, encoder: JSONEncoder) throws -> Self {
        do {
            let originalData = try encoder.encode(object)
            let parameters = try JSONSerialization.jsonObject(with: originalData)

            if let parameters = parameters as? [String: Any] {
                return .xform(parameters)
            } else {
                throw EncodingError.invalidJSON
            }
        } catch {
            throw EncodingError.generic(.init(error))
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
            .map { key, value -> String in
                return "\(key)=\(percentEscapeString(value))"
            }
            .joined(separator: "&").data(using: String.Encoding.utf8) ?? Data()
    }
}
