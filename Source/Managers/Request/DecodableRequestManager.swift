import Foundation
import Threading

/// A class that manages requests and responses for a ``Decodable`` type.
public struct DecodableRequestManager {
    private let parent: RequestManager

    public init(parent: RequestManager) {
        self.parent = parent
    }
}

public extension DecodableRequestManager {
    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    keyPath: DecodableKeyPath<T> = [],
                    address: Address,
                    parameters: Parameters = .init(),
                    decoding: JSONDecoding? = nil,
                    completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> SmartTasking
    where T: Decodable {
        return parent.request(address: address,
                              parameters: parameters,
                              completionQueue: completionQueue) { result in
            let decoder = DecodableContent<T>(decoder: decoding, keyPath: keyPath)
            let obj = decoder.decode(with: result, parameters: parameters)
            completion(obj)
        }
    }

    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    keyPath: DecodableKeyPath<T> = [],
                    address: Address,
                    parameters: Parameters = .init(),
                    decoding: JSONDecoding? = nil,
                    completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> SmartTasking
    where T: Decodable & ExpressibleByNilLiteral {
        return parent.request(address: address,
                              parameters: parameters,
                              completionQueue: completionQueue) { result in
            let decoder = DecodableContent<T>(decoder: decoding, keyPath: keyPath)
            let obj = decoder.decode(with: result, parameters: parameters)
            let recovered = obj.recoverResult(nil)
            completion(recovered)
        }
    }

    // MARK: - async

    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    keyPath: DecodableKeyPath<T> = [],
                    address: Address,
                    parameters: Parameters = .init(),
                    decoding: JSONDecoding? = nil) async -> Result<T, Error>
    where T: Decodable {
        return await withCheckedContinuation { [self] completion in
            request(type,
                    keyPath: keyPath,
                    address: address,
                    parameters: parameters,
                    decoding: decoding,
                    completionQueue: .absent) { data in
                let sendable = USendable(data)
                completion.resume(returning: sendable.value)
            }
            .detach().deferredStart()
        }
    }

    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    keyPath: DecodableKeyPath<T> = [],
                    address: Address,
                    parameters: Parameters = .init(),
                    decoding: JSONDecoding? = nil) async -> Result<T, Error>
    where T: Decodable & ExpressibleByNilLiteral {
        return await withCheckedContinuation { [self] completion in
            request(type,
                    keyPath: keyPath,
                    address: address,
                    parameters: parameters,
                    decoding: decoding,
                    completionQueue: .absent) { data in
                let sendable = USendable(data)
                completion.resume(returning: sendable.value)
            }
            .detach().deferredStart()
        }
    }

    // MARK: - async throws

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                keyPath: DecodableKeyPath<T> = [],
                                address: Address,
                                parameters: Parameters = .init(),
                                decoding: JSONDecoding? = nil) async throws -> T
    where T: Decodable {
        return try await withCheckedThrowingContinuation { [self] completion in
            request(type,
                    keyPath: keyPath,
                    address: address,
                    parameters: parameters,
                    decoding: decoding,
                    completionQueue: .absent) { data in
                let sendable = USendable(data)
                completion.resume(with: sendable.value)
            }
            .detach().deferredStart()
        }
    }

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                keyPath: DecodableKeyPath<T> = [],
                                address: Address,
                                parameters: Parameters = .init(),
                                decoding: JSONDecoding? = nil) async throws -> T
    where T: Decodable & ExpressibleByNilLiteral {
        return try await withCheckedThrowingContinuation { [self] completion in
            request(type,
                    keyPath: keyPath,
                    address: address,
                    parameters: parameters,
                    decoding: decoding,
                    completionQueue: .absent) { data in
                let sendable = USendable(data)
                completion.resume(with: sendable.value)
            }
            .detach().deferredStart()
        }
    }
}
