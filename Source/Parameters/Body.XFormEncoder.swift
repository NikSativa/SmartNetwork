import Foundation

extension Body {
    enum XFormEncoder {
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
                    return [key, percentEscapeString(value)].filterNils().joined(separator: "=")
                }
                .joined(separator: "&").data(using: String.Encoding.utf8)
        }
    }
}
