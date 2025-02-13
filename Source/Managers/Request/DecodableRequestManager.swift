import Foundation
import Threading

/// A class that manages requests and responses for a ``Decodable`` type.
public struct DecodableRequestManager {
    private let base: RequestManager

    public init(base: RequestManager) {
        self.base = base
    }
}

public extension DecodableRequestManager {
    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    keyPath: DecodableKeyPath<T> = [],
                    address: Address,
                    parameters: Parameters = .init(),
                    userInfo: UserInfo = .init(),
                    decoding: JSONDecoding? = nil,
                    completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> SmartTasking
    where T: Decodable {
        return base.request(address: address,
                            parameters: parameters,
                            userInfo: userInfo,
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
                    userInfo: UserInfo = .init(),
                    decoding: JSONDecoding? = nil,
                    completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> SmartTasking
    where T: Decodable & ExpressibleByNilLiteral {
        return base.request(address: address,
                            parameters: parameters,
                            userInfo: userInfo,
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
                    userInfo: UserInfo = .init(),
                    decoding: JSONDecoding? = nil) async -> Result<T, Error>
    where T: Decodable {
        let request: AnyRequest = base.request(address: address, parameters: parameters, userInfo: userInfo)
        return await request.decodeAsync(type, with: decoding, keyPath: keyPath)
    }

    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    keyPath: DecodableKeyPath<T> = [],
                    address: Address,
                    parameters: Parameters = .init(),
                    userInfo: UserInfo = .init(),
                    decoding: JSONDecoding? = nil) async -> Result<T, Error>
    where T: Decodable & ExpressibleByNilLiteral {
        let request: AnyRequest = base.request(address: address, parameters: parameters, userInfo: userInfo)
        return await request.decodeAsync(type, with: decoding, keyPath: keyPath)
    }

    // MARK: - async throws

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                keyPath: DecodableKeyPath<T> = [],
                                address: Address,
                                parameters: Parameters = .init(),
                                userInfo: UserInfo = .init(),
                                decoding: JSONDecoding? = nil) async throws -> T
    where T: Decodable {
        let request: AnyRequest = base.request(address: address, parameters: parameters, userInfo: userInfo)
        return try await request.decodeAsyncWithThrowing(type, with: decoding, keyPath: keyPath)
    }

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                keyPath: DecodableKeyPath<T> = [],
                                address: Address,
                                parameters: Parameters = .init(),
                                userInfo: UserInfo = .init(),
                                decoding: JSONDecoding? = nil) async throws -> T
    where T: Decodable & ExpressibleByNilLiteral {
        let request: AnyRequest = base.request(address: address, parameters: parameters, userInfo: userInfo)
        return try await request.decodeAsyncWithThrowing(type, with: decoding, keyPath: keyPath)
    }
}
