import Foundation
import Threading

/// A type-safe wrapper for sending requests and decoding responses into `Decodable` types.
///
/// `DecodableRequestManager` supports both completion-based and async workflows, with optional decoding customization.
public struct DecodableRequestManager {
    private let base: RequestManager

    public init(base: RequestManager) {
        self.base = base
    }
}

public extension DecodableRequestManager {
    /// Sends a request and decodes the response into the specified `Decodable` type.
    ///
    /// - Parameters:
    ///   - type: The expected response type conforming to `Decodable`.
    ///   - keyPath: Optional key path for decoding nested structures.
    ///   - address: The request target.
    ///   - parameters: Configuration values for the request.
    ///   - userInfo: Additional request metadata.
    ///   - decoding: An optional JSON decoding strategy.
    ///   - completionQueue: The queue for delivering the result.
    ///   - completion: A closure called with the decoded result or error.
    /// - Returns: A `SmartTasking` instance representing the request.
    func request<T>(_: T.Type = T.self,
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

    /// Sends a request and decodes the response into the specified `Decodable` type.
    ///
    /// - Parameters:
    ///   - type: The expected response type conforming to `Decodable`.
    ///   - keyPath: Optional key path for decoding nested structures.
    ///   - address: The request target.
    ///   - parameters: Configuration values for the request.
    ///   - userInfo: Additional request metadata.
    ///   - decoding: An optional JSON decoding strategy.
    ///   - completionQueue: The queue for delivering the result.
    ///   - completion: A closure called with the decoded result or error.
    /// - Returns: A `SmartTasking` instance representing the request.
    /// If decoding fails, returns `.success(nil)` instead of an error.
    func request<T>(_: T.Type = T.self,
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

    /// Sends a request asynchronously and decodes the result into the expected type.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - keyPath: Optional key path for decoding nested structures.
    ///   - address: The request target.
    ///   - parameters: Request configuration.
    ///   - userInfo: Metadata to pass through the request pipeline.
    ///   - decoding: Optional decoding customization.
    /// - Returns: A `Result` containing the decoded value or an error.
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

    /// Sends a request asynchronously and decodes the result into the expected type.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - keyPath: Optional key path for decoding nested structures.
    ///   - address: The request target.
    ///   - parameters: Request configuration.
    ///   - userInfo: Metadata to pass through the request pipeline.
    ///   - decoding: Optional decoding customization.
    /// - Returns: A `Result` containing the decoded value or an error.
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

    /// Sends a request asynchronously and throws if decoding fails.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - keyPath: Optional key path to extract the nested result.
    ///   - address: The request target.
    ///   - parameters: Request configuration.
    ///   - userInfo: Metadata to pass through the request pipeline.
    ///   - decoding: Optional decoding configuration.
    /// - Returns: The successfully decoded object.
    /// - Throws: An error if the request fails or decoding is unsuccessful.
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

    /// Sends a request asynchronously and throws if decoding fails.
    ///
    /// - Parameters:
    ///   - type: The expected response type.
    ///   - keyPath: Optional key path to extract the nested result.
    ///   - address: The request target.
    ///   - parameters: Request configuration.
    ///   - userInfo: Metadata to pass through the request pipeline.
    ///   - decoding: Optional decoding configuration.
    /// - Returns: The successfully decoded object.
    /// - Throws: An error if the request fails or decoding is unsuccessful.
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
