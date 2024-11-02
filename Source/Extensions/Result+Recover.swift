import Foundation

internal extension Result where Failure == Error {
    func recoverResult() -> Result<Success?, Failure> {
        switch self {
        case .success(let obj):
            return .success(obj)
        case .failure(RequestDecodingError.emptyResponse),
             .failure(RequestDecodingError.nilResponse):
            return .success(nil)
        case .failure(let error):
            return .failure(error)
        }
    }
}
