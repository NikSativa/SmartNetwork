import Foundation
import Threading

#if swift(>=6.0)
/// A class that manages requests and responses for a ``Decodable`` type.
public protocol DecodableRequestManager: Sendable {
    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping @Sendable (Result<T, Error>) -> Void) -> SmartTasking
        where T: Decodable & Sendable

    // Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping @Sendable (Result<T?, Error>) -> Void) -> SmartTasking
        where T: Decodable & Sendable

    // MARK: - async

    // Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T, Error>
        where T: Decodable & Sendable

    // Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T?, Error>
        where T: Decodable & Sendable

    // MARK: - async throws

    // Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T
        where T: Decodable & Sendable

    // Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(opt type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T?
        where T: Decodable & Sendable
}

public extension DecodableRequestManager {
    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping @Sendable (Result<T, Error>) -> Void) -> SmartTasking
    where T: Decodable & Sendable {
        return request(type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    /// Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping @Sendable (Result<T?, Error>) -> Void) -> SmartTasking
    where T: Decodable & Sendable {
        return request(opt: type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    // MARK: - async

    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T, Error>
    where T: Decodable & Sendable {
        return await withCheckedContinuation { [self] completion in
            request(type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(returning: data)
            }
            .detach().deferredStart()
        }
    }

    /// Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T?, Error>
    where T: Decodable & Sendable {
        return await withCheckedContinuation { [self] completion in
            request(opt: type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(returning: data)
            }
            .detach().deferredStart()
        }
    }

    // MARK: - async throws

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T
    where T: Decodable & Sendable {
        return try await withCheckedThrowingContinuation { [self] completion in
            request(type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(with: data)
            }
            .detach().deferredStart()
        }
    }

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(opt type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T?
    where T: Decodable & Sendable {
        return try await withCheckedThrowingContinuation { [self] completion in
            request(opt: type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(with: data)
            }
            .detach().deferredStart()
        }
    }
}
#else
/// A class that manages requests and responses for a ``Decodable`` type.
public protocol DecodableRequestManager {
    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> SmartTasking
        where T: Decodable

    // Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping (Result<T?, Error>) -> Void) -> SmartTasking
        where T: Decodable

    // MARK: - async

    // Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T, Error>
        where T: Decodable

    // Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T?, Error>
        where T: Decodable

    // MARK: - async throws

    // Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T
        where T: Decodable

    // Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(opt type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T?
        where T: Decodable
}

public extension DecodableRequestManager {
    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> SmartTasking
    where T: Decodable {
        return request(type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    /// Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping (Result<T?, Error>) -> Void) -> SmartTasking
    where T: Decodable {
        return request(opt: type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    // MARK: - async

    /// Sends a request to the specified address with the given parameters.
    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T, Error>
    where T: Decodable {
        return await withCheckedContinuation { [self] completion in
            request(type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(returning: data)
            }
            .detach().deferredStart()
        }
    }

    /// Sends a request to the specified address with the given parameters.
    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T?, Error>
    where T: Decodable {
        return await withCheckedContinuation { [self] completion in
            request(opt: type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(returning: data)
            }
            .detach().deferredStart()
        }
    }

    // MARK: - async throws

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T
    where T: Decodable {
        return try await withCheckedThrowingContinuation { [self] completion in
            request(type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(with: data)
            }
            .detach().deferredStart()
        }
    }

    /// Sends a request to the specified address with the given parameters.
    func requestWithThrowing<T>(opt type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T?
    where T: Decodable {
        return try await withCheckedThrowingContinuation { [self] completion in
            request(opt: type,
                    address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(with: data)
            }
            .detach().deferredStart()
        }
    }
}
#endif
