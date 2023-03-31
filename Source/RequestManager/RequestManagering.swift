import Foundation
import NQueue

public protocol RequestManagering {
    typealias ResponseClosure = (RequestResult) -> Void

    static func map<T: CustomDecodable>(data: RequestResult,
                                        to _: T.Type,
                                        with parameters: Parameters) -> Result<T.Object, Error>
    func request(with parameters: Parameters,
                 inQueue completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> RequestingTask
}

// MARK: - defult queue

public extension RequestManagering {
    func request(with parameters: Parameters,
                 completion: @escaping ResponseClosure) -> RequestingTask {
        request(with: parameters,
                inQueue: RS.defaultResponseQueue,
                completion: completion)
    }
}

// MARK: - CustomDecodable

public extension RequestManagering {
    func requestCustomDecodable<T: CustomDecodable>(_ type: T.Type,
                                                    with parameters: Parameters) async -> Result<T.Object, Error> {
        return await withCheckedContinuation { completion in
            let task = request(with: parameters, inQueue: .absent) { [parameters] data in
                let result = Self.map(data: data, to: type, with: parameters)
                completion.resume(returning: result)
            }
            task.start()
        }
    }

    func requestCustomDecodable<T: CustomDecodable>(_ type: T.Type,
                                                    with parameters: Parameters,
                                                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                                                    completion: @escaping (Result<T.Object, Error>) -> Void) -> RequestingTask {
        let task = request(with: parameters, inQueue: .absent) { [parameters] data in
            let result = Self.map(data: data, to: type, with: parameters)
            completionQueue.fire {
                completion(result)
            }
        }
        return task
    }
}

// MARK: - async

public extension RequestManagering {
    // MARK: - ResponseData

    func request(with parameters: Parameters) async -> RequestResult {
        return await withCheckedContinuation { completion in
            let task = request(with: parameters, inQueue: .absent) { result in
                completion.resume(returning: result)
            }
            task.start()
        }
    }

    // MARK: - Void

    func requestVoid(with parameters: Parameters) async -> Result<Void, Error> {
        return await requestCustomDecodable(VoidContent.self, with: parameters)
    }

    // MARK: - Decodable

    func requestDecodable<T: Decodable>(_: T.Type, with parameters: Parameters) async -> Result<T, Error> {
        return await requestCustomDecodable(DecodableContent<T>.self, with: parameters).recoverResponse()
    }

    func requestOptionalDecodable<T: Decodable>(_: T.Type, with parameters: Parameters) async -> Result<T?, Error> {
        return await requestCustomDecodable(DecodableContent<T>.self, with: parameters)
    }

    // MARK: - Image

    func requestImage(with parameters: Parameters) async -> Result<Image, Error> {
        return await requestCustomDecodable(ImageContent.self, with: parameters).recoverResponse()
    }

    func requestOptionalImage(with parameters: Parameters) async -> Result<Image?, Error> {
        return await requestCustomDecodable(ImageContent.self, with: parameters)
    }

    // MARK: - Data

    func requestData(with parameters: Parameters) async -> Result<Data, Error> {
        return await requestCustomDecodable(DataContent.self, with: parameters).recoverResponse()
    }

    func requestOptionalData(with parameters: Parameters) async -> Result<Data?, Error> {
        return await requestCustomDecodable(DataContent.self, with: parameters)
    }

    // MARK: - Any/JSON

    func requestAny(with parameters: Parameters) async -> Result<Any, Error> {
        return await requestCustomDecodable(JSONContent.self, with: parameters).recoverResponse()
    }

    func requestOptionalAny(with parameters: Parameters) async -> Result<Any?, Error> {
        return await requestCustomDecodable(JSONContent.self, with: parameters)
    }
}

// MARK: - closure

public extension RequestManagering {
    // MARK: - Void

    func requestVoid(with parameters: Parameters,
                     inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                     completion: @escaping (Result<Void, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(VoidContent.self,
                                      with: parameters,
                                      inQueue: completionQueue,
                                      completion: completion)
    }

    // MARK: - Decodable

    func requestDecodable<T: Decodable>(_ type: T.Type,
                                        with parameters: Parameters,
                                        inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                                        completion: @escaping (Result<T, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(DecodableContent<T>.self,
                                      with: parameters,
                                      inQueue: completionQueue) { result in
            let new = result.recoverResponse()
            completion(new)
        }
    }

    func requestOptionalDecodable<T: Decodable>(_ type: T.Type,
                                                with parameters: Parameters,
                                                inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                                                completion: @escaping (Result<T?, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(DecodableContent<T>.self,
                                      with: parameters,
                                      inQueue: completionQueue,
                                      completion: completion)
    }

    // MARK: - Image

    func requestImage(with parameters: Parameters,
                      inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                      completion: @escaping (Result<Image, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(ImageContent.self,
                                      with: parameters,
                                      inQueue: completionQueue) { result in
            let new = result.recoverResponse()
            completion(new)
        }
    }

    func requestOptionalImage(with parameters: Parameters,
                              inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                              completion: @escaping (Result<Image?, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(ImageContent.self,
                                      with: parameters,
                                      inQueue: completionQueue,
                                      completion: completion)
    }

    // MARK: - Data

    func requestData(with parameters: Parameters,
                     inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                     completion: @escaping (Result<Data, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(DataContent.self,
                                      with: parameters,
                                      inQueue: completionQueue) { result in
            let new = result.recoverResponse()
            completion(new)
        }
    }

    func requestOptionalData(with parameters: Parameters,
                             inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                             completion: @escaping (Result<Data?, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(DataContent.self,
                                      with: parameters,
                                      inQueue: completionQueue,
                                      completion: completion)
    }

    // MARK: - Any/JSON

    func requestAny(with parameters: Parameters,
                    inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                    completion: @escaping (Result<Any, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(JSONContent.self,
                                      with: parameters,
                                      inQueue: completionQueue) { result in
            let new = result.recoverResponse()
            completion(new)
        }
    }

    func requestOptionalAny(with parameters: Parameters,
                            inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                            completion: @escaping (Result<Any?, Error>) -> Void) -> RequestingTask {
        return requestCustomDecodable(JSONContent.self,
                                      with: parameters,
                                      inQueue: completionQueue,
                                      completion: completion)
    }
}

private extension Result {
    func recoverResponse<T>() -> Result<T, Error> where Success == T? {
        switch self {
        case .success(.some(let response)):
            return .success(response)
        case .success(.none):
            return .failure(RequestDecodingError.nilResponse)
        case .failure(let error):
            return .failure(error)
        }
    }
}
