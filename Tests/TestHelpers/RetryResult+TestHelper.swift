import Foundation
import SmartNetwork

// MARK: - RetryResult + Equatable

extension RetryResult: Equatable {
    public static func ==(lhs: SmartNetwork.RetryResult, rhs: SmartNetwork.RetryResult) -> Bool {
        switch (lhs, rhs) {
        case (.doNotRetry, .doNotRetry),
             (.retry, .retry):
            return true
        case (.retryWithDelay(let a), .retryWithDelay(let b)):
            return a == b
        case (.doNotRetryWithError(let a), .doNotRetryWithError(let b)):
            return (a as NSError) == (b as NSError)
        case (.doNotRetry, _),
             (.doNotRetryWithError, _),
             (.retry, _),
             (.retryWithDelay, _):
            return false
        }
    }
}
