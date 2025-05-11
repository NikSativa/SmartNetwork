import Foundation

public extension Task where Success == Never, Failure == Never {
    /// Suspends the current task for a specified number of seconds.
    ///
    /// This is a convenience method that abstracts away platform version differences and provides a uniform interface
    /// for suspending asynchronous tasks. It does not block the underlying thread.
    ///
    /// - Parameter seconds: The number of seconds to sleep. Can include fractional values for subsecond delays.
    ///
    /// - Throws: `CancellationError` if the task is cancelled before the delay completes.
    ///
    /// - Example:
    /// ```swift
    /// try await Task.sleep(seconds: 3)
    /// ```
    static func sleep(seconds: Double) async throws {
        if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
            try await Task.sleep(for: .seconds(seconds))
        } else {
            let duration = UInt64(seconds * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }
}
