import Foundation

extension Body {
    /// Encodes a dictionary of key-value pairs into `application/x-www-form-urlencoded` format.
    ///
    /// Used to serialize request bodies for form submissions. Percent-encodes keys and values according to standard rules.
    enum XFormEncoder {
        /// Percent-encodes a string using URL-safe characters for form encoding.
        ///
        /// Spaces are replaced with `+` symbols after encoding.
        ///
        /// - Parameter string: The input string to encode.
        /// - Returns: A percent-escaped string suitable for form data.
        private static func percentEscapeString(_ string: String) -> String? {
            var characterSet = CharacterSet.alphanumerics
            characterSet.insert(charactersIn: "-._* ")

            return string
                .addingPercentEncoding(withAllowedCharacters: characterSet)?
                .replacingOccurrences(of: " ", with: "+")
                .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
        }

        /// Converts a value to a string and percent-encodes it using form encoding rules.
        ///
        /// - Parameter value: Any value convertible to a string.
        /// - Returns: A percent-escaped string representation of the value.
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

        /// Encodes a dictionary of parameters into `application/x-www-form-urlencoded` data.
        ///
        /// - Parameter parameters: A dictionary of form fields to encode.
        /// - Returns: A `Data` object containing the encoded key-value pairs, or `nil` if encoding fails.
        static func encodeParameters(parameters: [String: Any]) -> Data? {
            return parameters
                .map { key, value -> String in
                    return [key, percentEscapeString(value)].filterNils().joined(separator: "=")
                }
                .joined(separator: "&").data(using: String.Encoding.utf8)
        }
    }
}
