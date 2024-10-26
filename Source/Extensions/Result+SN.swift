import Foundation

internal extension Result {
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
