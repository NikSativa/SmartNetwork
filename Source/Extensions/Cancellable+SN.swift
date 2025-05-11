import Combine
import Foundation

public extension Cancellable {
    /// Stores this `Cancellable` instance in the specified collection of `AnyCancellable`.
    ///
    /// This method provides syntactic convenience when working with Combine pipelines.
    ///
    /// Example:
    /// ```swift
    /// manager.request(with: parameters)
    ///     .storing(in: &bag)
    ///     .start()
    /// ```
    ///
    /// - Parameter collection: A mutable collection in which to store this `Cancellable`.
    /// - Returns: The cancellable instance, allowing for fluent chaining.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func storing<C>(in collection: inout C) -> Self
    where C: RangeReplaceableCollection, C.Element == AnyCancellable {
        store(in: &collection)
        return self
    }

    /// Stores this `Cancellable` instance in the specified set of `AnyCancellable`.
    ///
    /// This method provides syntactic convenience when managing Combine subscriptions.
    ///
    /// Example:
    /// ```swift
    /// manager.request(with: parameters)
    ///     .storing(in: &bag)
    ///     .start()
    /// ```
    ///
    /// - Parameter set: A mutable set in which to store this `Cancellable`.
    /// - Returns: The cancellable instance, allowing for fluent chaining.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func storing(in set: inout Set<AnyCancellable>) -> Self {
        store(in: &set)
        return self
    }
}
