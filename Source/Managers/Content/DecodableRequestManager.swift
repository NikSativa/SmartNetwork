import Foundation
import Threading

#if swift(>=6.0)
public protocol DecodableRequestManager: Sendable {
    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping @Sendable (Result<T, Error>) -> Void) -> RequestingTask
        where T: Decodable & Sendable
    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping @Sendable (Result<T?, Error>) -> Void) -> RequestingTask
        where T: Decodable & Sendable

    // MARK: - async

    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T, Error>
        where T: Decodable & Sendable

    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T?, Error>
        where T: Decodable & Sendable

    // MARK: - async throws

    func requestWithThrowing<T>(_ type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T
        where T: Decodable & Sendable

    func requestWithThrowing<T>(opt type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T?
        where T: Decodable & Sendable
}

public extension DecodableRequestManager {
    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping @Sendable (Result<T, Error>) -> Void) -> RequestingTask
    where T: Decodable & Sendable {
        return request(type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping @Sendable (Result<T?, Error>) -> Void) -> RequestingTask
    where T: Decodable & Sendable {
        return request(opt: type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    // MARK: - async

    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T, Error>
    where T: Decodable & Sendable {
        return await withCheckedContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { data in
                    holder.task = nil
                    completion.resume(returning: data)
                }
            }
        }
    }

    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T?, Error>
    where T: Decodable & Sendable {
        return await withCheckedContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(opt: type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { data in
                    holder.task = nil
                    completion.resume(returning: data)
                }
            }
        }
    }

    // MARK: - async throws

    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T
    where T: Decodable & Sendable {
        return try await withCheckedThrowingContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { data in
                    holder.task = nil
                    completion.resume(with: data)
                }
            }
        }
    }

    func requestWithThrowing<T>(opt type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T?
    where T: Decodable & Sendable {
        return try await withCheckedThrowingContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(opt: type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { [holder] data in
                    holder.task = nil
                    completion.resume(with: data)
                }
            }
        }
    }
}
#else
public protocol DecodableRequestManager {
    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> RequestingTask
        where T: Decodable
    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue,
                    completion: @escaping (Result<T?, Error>) -> Void) -> RequestingTask
        where T: Decodable

    // MARK: - async

    func request<T>(_ type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T, Error>
        where T: Decodable

    func request<T>(opt type: T.Type,
                    address: Address,
                    with parameters: Parameters) async -> Result<T?, Error>
        where T: Decodable

    // MARK: - async throws

    func requestWithThrowing<T>(_ type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T
        where T: Decodable

    func requestWithThrowing<T>(opt type: T.Type,
                                address: Address,
                                with parameters: Parameters) async throws -> T?
        where T: Decodable
}

public extension DecodableRequestManager {
    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping (Result<T, Error>) -> Void) -> RequestingTask
    where T: Decodable {
        return request(type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init(),
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping (Result<T?, Error>) -> Void) -> RequestingTask
    where T: Decodable {
        return request(opt: type,
                       address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    // MARK: - async

    func request<T>(_ type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T, Error>
    where T: Decodable {
        return await withCheckedContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { data in
                    holder.task = nil
                    completion.resume(returning: data)
                }
            }
        }
    }

    func request<T>(opt type: T.Type = T.self,
                    address: Address,
                    with parameters: Parameters = .init()) async -> Result<T?, Error>
    where T: Decodable {
        return await withCheckedContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(opt: type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { data in
                    holder.task = nil
                    completion.resume(returning: data)
                }
            }
        }
    }

    // MARK: - async throws

    func requestWithThrowing<T>(_ type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T
    where T: Decodable {
        return try await withCheckedThrowingContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { data in
                    holder.task = nil
                    completion.resume(with: data)
                }
            }
        }
    }

    func requestWithThrowing<T>(opt type: T.Type = T.self,
                                address: Address,
                                with parameters: Parameters = .init()) async throws -> T?
    where T: Decodable {
        return try await withCheckedThrowingContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(opt: type,
                        address: address,
                        with: parameters,
                        inQueue: .absent) { [holder] data in
                    holder.task = nil
                    completion.resume(with: data)
                }
            }
        }
    }
}
#endif
