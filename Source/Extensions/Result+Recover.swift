import Foundation

internal extension Result where Failure: Error {
    func recoverResult(_ defaultValue: Success) -> Result<Success, Failure> {
        switch self {
        case .success(let obj):
            return .success(obj)
        case .failure(let error):
            return error.isRecoverable ? .success(defaultValue) : .failure(error)
        }
    }

    func recoverResult() -> Result<Success?, Failure> {
        switch self {
        case .success(let obj):
            return .success(obj)
        case .failure(let error):
            return error.isRecoverable ? .success(nil) : .failure(error)
        }
    }
}

private extension Error {
    var isRecoverable: Bool {
        switch requestError {
        case .decoding:
            return true
        default:
            return false
        }
    }
}
