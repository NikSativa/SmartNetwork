import Foundation

/// A deserializer that decodes a `SmartResponse` body into a concrete `Decodable` model.
///
/// `DecodableContent` supports:
/// - Decoding the top-level body or a nested value via a JSON key path.
/// - Supplying a custom `JSONDecoder` (via a closure) or using a default one.
/// - Fallback behavior when decoding fails: return a specific error, a default value, or the thrown decoding error.
///
/// The instance is value-typed and thread-safe as long as the provided `decoder` closure is pure and thread-safe.
///
/// - SeeAlso: `DecodableKeyPath`, `SmartResponse`, `RequestDecodingError`
public struct DecodableContent<Response: Decodable>: Deserializable {
    /// Optional factory for the `JSONDecoder` used during decoding.
    ///
    /// If `nil`, a fresh `JSONDecoder()` is constructed for each decode. Provide a closure
    /// if you need custom strategies (dates, keys, data) or performance optimizations via
    /// a reused decoder instance.
    public let decoder: JSONDecoding?
    /// Describes the JSON key path of the target value and the fallback strategy when decoding fails.
    ///
    /// Use an empty path to decode the top-level body. Non-empty paths navigate into nested JSON.
    public let keyPath: DecodableKeyPath<Response>

    /// Creates a `DecodableContent` deserializer.
    /// - Parameters:
    ///   - decoder: Optional closure that supplies a `JSONDecoder` per decode call.
    ///   - keyPath: Key-path descriptor and fallback policy for decoding.
    public init(decoder: JSONDecoding?, keyPath: DecodableKeyPath<Response>) {
        self.decoder = decoder
        self.keyPath = keyPath
    }

    /// Attempts to decode the `SmartResponse` body into `Response` using the configured decoder and key path.
    ///
    /// Error precedence is as follows:
    /// 1. If `data.error` is non-`nil`, return `.failure` with that error.
    /// 2. If `data.body` is `nil`, return `.failure(RequestDecodingError.nilResponse)`.
    /// 3. If `data.body` is empty, return `.failure(RequestDecodingError.emptyResponse)`.
    /// 4. If JSON decoding throws, apply `keyPath.fallback`:
    ///    - `.error(e)`: return `.failure(e)`
    ///    - `.value(v)`: return `.success(v)`
    ///    - `.none`: return `.failure` with the thrown decoding error
    ///
    /// - Parameters:
    ///   - data: The response containing the raw body bytes and/or an error.
    ///   - parameters: Request parameters. Unused by this type.
    /// - Returns: `.success` with a decoded `Response` or `.failure` describing why decoding was not possible.
    ///
    /// # Example
    /// Decode top-level JSON:
    /// ```swift
    /// struct User: Decodable { let id: Int; let name: String }
    /// let content = DecodableContent<User>(decoder: nil, keyPath: .root())
    /// let result = content.decode(with: response, parameters: [:])
    /// ```
    ///
    /// Decode a nested field using a key path and default value on failure:
    /// ```swift
    /// let kp = DecodableKeyPath<[User]>(path: ["data", "users"], fallback: .value([]))
    /// let content = DecodableContent<[User]>(decoder: { JSONDecoder() }, keyPath: kp)
    /// let result = content.decode(with: response, parameters: [:])
    /// ```
    public func decode(with data: SmartResponse, parameters: Parameters) -> Result<Response, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            do {
                let decoder = decoder?() ?? .init()
                let result: Response =
                if keyPath.path.isEmpty {
                    try decoder.decode(Response.self, from: data)
                } else {
                    try data.decode(Response.self, keyPath: keyPath.path, decoder: decoder)
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
