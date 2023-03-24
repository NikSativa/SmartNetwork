import Foundation

public protocol RequestManagering {
    typealias ResponseClosure = (ResponseData) -> Void

    static func map<T: CustomDecodable>(data: ResponseData,
                                        to _: T.Type,
                                        with parameters: Parameters) -> Result<T.Object, Error>
    func request(with parameters: Parameters,
                 completion: @escaping ResponseClosure) -> LoadingTask

    // MARK: - extension

    func request(with parameters: Parameters) async -> ResponseData
    func request<T: CustomDecodable>(_ type: T.Type,
                                     with parameters: Parameters) async -> Result<T.Object, Error>

    func request<T: CustomDecodable>(_ type: T.Type,
                                     with parameters: Parameters,
                                     completion: @escaping (Result<T.Object, Error>) -> Void) -> LoadingTask
}

public extension RequestManagering {
    func request(with parameters: Parameters) async -> ResponseData {
        return await withCheckedContinuation { completion in
            let task = request(with: parameters) { [parameters] result in
                parameters.queue.fire {
                    completion.resume(returning: result)
                }
            }
            task.resume()
        }
    }

    func request<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) async -> Result<T.Object, Error> {
        return await withCheckedContinuation { completion in
            let task = request(with: parameters) { [parameters] data in
                let result = Self.map(data: data, to: type, with: parameters)
                parameters.queue.fire {
                    completion.resume(returning: result)
                }
            }
            task.resume()
        }
    }

    func request<T: CustomDecodable>(_ type: T.Type,
                                     with parameters: Parameters,
                                     completion: @escaping (Result<T.Object, Error>) -> Void) -> LoadingTask {
        let task = request(with: parameters) { [parameters] data in
            let result = Self.map(data: data, to: type, with: parameters)
            parameters.queue.fire {
                completion(result)
            }
        }
        return task
    }
}
