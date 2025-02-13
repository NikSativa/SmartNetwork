import Foundation
import Threading

/// A struct that represents a request with any type of response.
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

    public func async() async -> SmartResponse {
        return await base.request(address: address, parameters: parameters, userInfo: userInfo)
    }

    /// Completes the request with the given completion closure.
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
    /// Requests a ``Decodable`` object.
    func decode<T>(_ type: T.Type = T.self, with decoder: JSONDecoder, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: { decoder }, keyPath: keyPath))
    }

    /// Requests a ``Decodable`` object.
    func decode<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath))
    }

    /// Requests a ``Decodable`` object.
    func decode<T>(_ type: T.Type = T.self, with decoder: JSONDecoder, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable & ExpressibleByNilLiteral {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: { decoder }, keyPath: keyPath))
    }

    /// Requests a ``Decodable`` object.
    func decode<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) -> TypedRequest<T>
    where T: Decodable & ExpressibleByNilLiteral {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath))
    }

    /// Requests a ``Decodable`` object asynchronously.
    func decodeAsync<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async -> Result<T, Error>
    where T: Decodable {
        return await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).async()
    }

    /// Requests a ``Decodable`` object asynchronously with throwing error.
    func decodeAsyncWithThrowing<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async throws -> T
    where T: Decodable {
        return try await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).asyncWithThrowing()
    }

    /// Requests a ``Decodable`` object asynchronously.
    func decodeAsync<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async -> Result<T, Error>
    where T: Decodable & ExpressibleByNilLiteral {
        return await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).async()
    }

    /// Requests a ``Decodable`` object asynchronously with throwing error.
    func decodeAsyncWithThrowing<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: DecodableKeyPath<T> = []) async throws -> T
    where T: Decodable & ExpressibleByNilLiteral {
        return try await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).asyncWithThrowing()
    }

    /// Requests a ``Image`` object.
    func image() -> TypedRequest<SmartImage> {
        return custom(ImageContent())
    }

    /// Requests a ``Data`` object.
    func data() -> TypedRequest<Data> {
        return custom(DataContent())
    }

    /// Requests a ``JSON`` object.
    func json() -> TypedRequest<Any> {
        return custom(JSONContent())
    }

    /// Requests a ``Void`` object.
    func void() -> TypedRequest<Void> {
        return custom(VoidContent())
    }

    /// Requests a ``Deserializable`` object.
    func custom<D: Deserializable>(_ d: D) -> TypedRequest<D.Object> {
        return .init(anyRequest: self, decoder: d)
    }
}

#if swift(>=6.0)
extension AnyRequest: Sendable {}
#endif
