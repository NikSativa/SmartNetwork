import Foundation

internal extension Result where Failure: Error {
    func recoverResult() -> Result<Success?, Failure> {
        switch self {
        case .success(let obj):
            return .success(obj)
        case .failure(let error):
            // prevent `indirect` compiler error
            if let error = error as? RequestDecodingError {
                switch error {
                case .emptyResponse,
                     .nilResponse:
                    return .success(nil)
                case .brokenImage,
                     .brokenResponse,
                     .other:
                    break
                }
            }
            return .failure(error)
        }
    }
}
