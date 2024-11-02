import Foundation
import Threading

/// A struct that represents a request with any type of response.
public struct AnyRequest {
    private let pure: RequestManager
    private let address: Address
    internal let parameters: Parameters

    internal init(pure: RequestManager, address: Address, parameters: Parameters) {
        self.pure = pure
        self.address = address
        self.parameters = parameters
    }
}

// MARK: - RequestCompletion

extension AnyRequest: RequestCompletion {
    public typealias Object = RequestResult

    /// Completes the request with the given completion closure.
    public func complete(in completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                         completion: @escaping CompletionClosure) -> SmartTasking {
        return pure.request(address: address,
                            parameters: parameters,
                            completionQueue: completionQueue,
                            completion: completion)
    }
}

public extension AnyRequest {
    /// Requests a ``Decodable`` object.
    func decode<T>(_ type: T.Type = T.self, with decoder: JSONDecoder, keyPath: [String] = []) -> TypedRequest<T>
    where T: Decodable {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: { decoder }, keyPath: keyPath))
    }

    /// Requests a ``Decodable`` object.
    func decode<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: [String] = []) -> TypedRequest<T>
    where T: Decodable {
        return .init(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath))
    }

    /// Requests a ``Decodable`` object asynchronously.
    func decodeAsync<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: [String] = []) async -> Result<T, Error>
    where T: Decodable {
        return await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).async()
    }

    /// Requests a ``Decodable`` object asynchronously with throwing error.
    func decodeAsyncWithThrowing<T>(_ type: T.Type = T.self, with decoder: JSONDecoding? = nil, keyPath: [String] = []) async throws -> T
    where T: Decodable {
        return try await TypedRequest<T>(anyRequest: self, decoder: DecodableContent<T>(decoder: decoder, keyPath: keyPath)).asyncWithThrowing()
    }

    /// Requests a ``Image`` object.
    func image() -> TypedRequest<Image> {
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
