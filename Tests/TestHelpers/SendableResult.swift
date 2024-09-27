import Foundation

final class SendableResult<T> {
    var value: T!

    init(value: T! = nil) {
        self.value = value
    }
}

#if swift(>=6.0)
extension SendableResult: @unchecked Sendable {}
#endif
