import Foundation

public protocol ResponseQueue: class {
    func async(_ workItem: @escaping () -> Void)
}

extension DispatchQueue: ResponseQueue {
    public func async(_ workItem: @escaping () -> Void) {
        async(execute: workItem)
    }
}
