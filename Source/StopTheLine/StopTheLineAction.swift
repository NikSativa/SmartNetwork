import Foundation

public enum StopTheLineAction: Hashable {
    case stopTheLine
    case passOver
    case retry
}

#if swift(>=6.0)
extension StopTheLineAction: Sendable {}
#endif
