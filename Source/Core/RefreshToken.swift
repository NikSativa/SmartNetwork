import Foundation

public protocol RefreshToken {
    func canSend(_ info: RequestInfo) -> Bool
}

extension Impl {
    class RefreshToken {
        typealias Request = () -> Void

        private var queue: [(Parameters, Request)] = []
    }
}

extension Impl.RefreshToken: RefreshToken {
    func canSend(_ info: RequestInfo) -> Bool {
        return true
    }
}
