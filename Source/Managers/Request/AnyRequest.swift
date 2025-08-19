import Foundation
import Threading

/// Represents a request that returns a raw `SmartResponse`, with optional decoding into typed results.
///
/// `AnyRequest` encapsulates a flexible, type-erased request pipeline and supports response decoding
/// into strongly typed models using `.decode(...)`, `.json()`, `.image()`, and similar methods.
public struct AnyRequest {
    // all properties are only for `internal` uasge
    internal let base: RequestManager
    internal let address: Address
    internal let parameters: Parameters
    internal let userInfo: UserInfo

    internal init(pure: RequestManager,
                  address: Address,
                  parameters: Parameters,
                  userInfo: UserInfo) {
        self.base = pure
        self.address = address
        self.parameters = parameters
        self.userInfo = userInfo
    }
}

// MARK: - RequestCompletion

extension AnyRequest: RequestCompletion {
    public typealias Object = SmartResponse

    /// Asynchronously performs the request and returns the raw `SmartResponse`.
    public func async() async -> SmartResponse {
        return await base.request(address: address, parameters: parameters, userInfo: userInfo)
    }

    /// Performs the request using a completion closure.
    ///
    /// - Parameters:
    ///   - completionQueue: The queue on which to call the completion closure.
    ///   - completion: A closure that receives the completed `SmartResponse`.
    /// - Returns: A `SmartTasking` instance representing the running request.
    public func complete(in completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                         completion: @escaping CompletionClosure) -> SmartTasking {
        return base.request(address: address,
                            parameters: parameters,
                            userInfo: userInfo,
                            completionQueue: completionQueue,
                            completion: completion)
    }
}

public extension AnyRequest {
    /// Converts the raw request into a typed request that decodes a `Decodable` result.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The JSON decoder or decoding strategy.
    ///   - keyPath: Optional key path for decoding nested values.
    /// - Returns: A `TypedRequest` instance that decodes the response.
    func decode<T>(_: T.Type = T.self, with decoder: JSONDecoder, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: { decoder }, keyPath: keyPath))
    }

    /// Converts the raw request into a typed request that decodes a `Decodable` result.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The JSON decoder or decoding strategy.
    ///   - keyPath: Optional key path for decoding nested values.
    /// - Returns: A `TypedRequest` instance that decodes the response.
    func decode<T>(_: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath))
    }

    /// Converts the raw request into a typed request that decodes a `Decodable` result.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The JSON decoder or decoding strategy.
    ///   - keyPath: Optional key path for decoding nested values.
    /// - Returns: A `TypedRequest` instance that decodes the response.
    func decode<T>(_: T.Type = T.self, with decoder: JSONDecoder, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable & ExpressibleByNilLiteral {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: { decoder }, keyPath: keyPath))
    }

    /// Converts the raw request into a typed request that decodes a `Decodable` result.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The JSON decoder or decoding strategy.
    ///   - keyPath: Optional key path for decoding nested values.
    /// - Returns: A `TypedRequest` instance that decodes the response.
    func decode<T>(_: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable & ExpressibleByNilLiteral {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath))
    }

    /// Asynchronously sends the request and decodes the response into the expected type.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The decoding strategy or JSON decoder.
    ///   - keyPath: Optional key path for nested decoding.
    /// - Returns: A result containing the decoded value or an error.
    func decodeAsync<T>(_: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async -> Result<T, Error>
    where T: Decodable {
        return await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).async()
    }

    /// Asynchronously sends the request and decodes the response into the expected type or throws.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The decoding strategy or JSON decoder.
    ///   - keyPath: Optional key path for nested decoding.
    /// - Throws: An error if decoding fails.
    /// - Returns: The decoded result.
    func decodeAsyncWithThrowing<T>(_: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async throws -> T
    where T: Decodable {
        return try await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).asyncWithThrowing()
    }

    /// Asynchronously sends the request and decodes the response into the expected type.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The decoding strategy or JSON decoder.
    ///   - keyPath: Optional key path for nested decoding.
    /// - Returns: A result containing the decoded value or an error.
    func decodeAsync<T>(_: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async -> Result<T, Error>
    where T: Decodable & ExpressibleByNilLiteral {
        return await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).async()
    }

    /// Asynchronously sends the request and decodes the response into the expected type or throws.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - decoder: The decoding strategy or JSON decoder.
    ///   - keyPath: Optional key path for nested decoding.
    /// - Throws: An error if decoding fails.
    /// - Returns: The decoded result.
    func decodeAsyncWithThrowing<T>(_: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async throws -> T
    where T: Decodable & ExpressibleByNilLiteral {
        return try await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).asyncWithThrowing()
    }

    /// Converts the request into a typed request that decodes the response as a platform-specific image.
    func image() -> TypedRequest<SmartImage> {
        return custom(ImageContent())
    }

    /// Converts the request into a typed request that decodes the response as raw `Data`.
    func data() -> TypedRequest<Data> {
        return custom(DataContent())
    }

    /// Converts the request into a typed request that decodes the response as a JSON object.
    func json() -> TypedRequest<Any> {
        return custom(JSONContent())
    }

    /// Converts the request into a typed request that expects no response body.
    func void() -> TypedRequest<Void> {
        return custom(VoidContent())
    }

    /// Converts the request into a typed request using a custom deserializer.
    ///
    /// - Parameter d: The deserializer used to decode the response.
    /// - Returns: A `TypedRequest` configured with the specified deserialization logic.
    func custom<D: Deserializable>(_ d: D) -> TypedRequest<D.Object> {
        return .init(anyRequest: self, decoder: d)
    }
}

#if swift(>=6.0)
extension AnyRequest: Sendable {}
#endif
