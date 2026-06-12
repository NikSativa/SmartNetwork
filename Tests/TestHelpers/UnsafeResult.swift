import Foundation

final class UnsafeValue<T> {
    var value: T!

    init(value: T! = nil) {
        self.value = value
    }
}

final class UnsafeResult<T> {
    var value: Result<T, Error>!

    init() {
        self.value = nil
    }

    init(value: T) {
        self.value = .success(value)
    }

    init(error: Error) {
        self.value = .failure(error)
    }
}

extension UnsafeResult: @unchecked Sendable {}
extension UnsafeValue: @unchecked Sendable {}
