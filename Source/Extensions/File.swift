import Combine
import Foundation

public extension Cancellable {
    /// Stores this cancellable instance in the specified collection.
    ///
    /// Only for the convenience of the Combine interface
    /// ```swift
    /// manager.request(with: parameters)
    ///     .storing(in: &bag)
    ///     .start()
    /// ```
    ///
    /// - Parameter collection: The collection in which to store this ``Cancellable``.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func storing<C>(in collection: inout C) -> Self
    where C: RangeReplaceableCollection, C.Element == AnyCancellable {
        store(in: &collection)
        return self
    }

    /// Stores this cancellable instance in the specified set.
    ///
    /// Only for the convenience of the Combine interface
    /// ```swift
    /// manager.request(with: parameters)
    ///     .storing(in: &bag)
    ///     .start()
    /// ```
    ///
    /// - Parameter set: The set in which to store this ``Cancellable``.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func storing(in set: inout Set<AnyCancellable>) -> Self {
        store(in: &set)
        return self
    }
}
