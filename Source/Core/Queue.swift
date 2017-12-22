import Foundation

public protocol Queue {
    func async(_ workItem: @escaping () -> Void)
}

extension DispatchQueue: Queue {
    public func async(_ workItem: @escaping () -> Void) {
        async(execute: workItem)
    }
}
