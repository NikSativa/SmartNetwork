import Foundation
import NCallback

public extension Callback {
    func tryMap<NewResponse, Response, Error: AnyError>(_ mapper: @escaping (Response) throws -> NewResponse) -> ResultCallback<NewResponse, Error>
    where ResultType == Result<Response, Error> {
        return flatMap {
            do {
                switch $0 {
                case .success(let response):
                    return .success(try mapper(response))
                case .failure(let error):
                    return .failure(error)
                }
            } catch let error as Error {
                return .failure(error)
            } catch {
                return .failure(.wrap(error))
            }
        }
    }
}
