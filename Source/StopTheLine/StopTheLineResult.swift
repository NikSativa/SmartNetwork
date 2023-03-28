import Foundation

public enum StopTheLineResult {
    /// pass over new response
    case passOver(RequestResult)

    /// use original response
    case useOriginal

    /// ignore current response and retry request
    case retry
}
