import Foundation

public enum ResponseQueue: Equatable {
    case absent
    case sync(DispatchResponseQueue)
    case async(DispatchResponseQueue)

    public static func == (lhs: ResponseQueue, rhs: ResponseQueue) -> Bool {
        switch (lhs, rhs) {
        case (.absent, .absent):
            return true
        case (.sync(let a), .sync(let b)),
             (.async(let a), .async(let b)):
            return a === b
        case (.absent, _),
             (.sync, _),
             (.async, _):
            return false
        }
    }

    public static let `default`: ResponseQueue = .async(DispatchQueue.main)
}

public protocol DispatchResponseQueue: class {
    func async(_ workItem: @escaping () -> Void)
    func sync(_ workItem: @escaping () -> Void)
}

extension DispatchQueue: DispatchResponseQueue {
    public func async(_ workItem: @escaping () -> Void) {
        async(execute: workItem)
    }

    public func sync(_ workItem: @escaping () -> Void) {
        sync(execute: workItem)
    }
}

extension ResponseQueue {
    func fire(_ workItem: @escaping () -> Void) {
        switch self {
        case .absent:
            workItem()
        case .async(let queue):
            queue.async(workItem)
        case .sync(let queue):
            queue.sync(workItem)
        }
    }
}
