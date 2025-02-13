import Foundation

public extension Task where Success == Never, Failure == Never {
    /// Suspends the current task for the given duration.
    ///
    /// If the task is cancelled before the time ends, this function throws
    /// `CancellationError`.
    ///
    /// This function doesn't block the underlying thread.
    ///
    /// ```swift
    /// try await Task.sleep(for: .seconds(3))
    /// ```
    ///
    static func sleep(seconds: Double) async throws {
        if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
            try await Task.sleep(for: .seconds(seconds))
        } else {
            let duration = UInt64(seconds * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }
}
