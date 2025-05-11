import Foundation

/// A deserializer that decodes a `SmartResponse` body into a `Decodable` type.
///
/// Supports decoding with optional key paths for nested JSON structures and fallback behavior
/// if decoding fails. Uses a provided or default `JSONDecoder`.
///
struct DecodableContent<Response: Decodable>: Deserializable {
    /// An optional closure that returns a `JSONDecoder` for decoding.
    ///
    /// If `nil`, a default `JSONDecoder` is used.
    let decoder: JSONDecoding?
    /// Defines the key path to the target value within the response body and fallback behavior.
    let keyPath: DecodableKeyPath<Response>

    /// Attempts to decode the response body into the expected type using a decoder and optional key path.
    ///
    /// - Parameters:
    ///   - data: The response containing the body and any error.
    ///   - parameters: Request parameters (unused in this context).
    /// - Returns: A result containing either the decoded value or an error.
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Response, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            do {
                let decoder = decoder?() ?? .init()
                let result: Response
                if keyPath.path.isEmpty {
                    result = try decoder.decode(Response.self, from: data)
                } else {
                    result = try data.decode(Response.self, keyPath: keyPath.path, decoder: decoder)
                }
                return .success(result)
            } catch {
                switch keyPath.fallback {
                case .error(let error):
                    return .failure(error)
                case .value(let value):
                    return .success(value)
                case .none:
                    return .failure(error)
                }
            }
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
