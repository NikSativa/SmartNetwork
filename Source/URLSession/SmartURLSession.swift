import Foundation

#if swift(>=6.0)
/// A type representing the progress of a task.
public typealias ProgressHandler = @Sendable (Progress) -> Void
#else
/// A type representing the progress of a task.
public typealias ProgressHandler = (Progress) -> Void
#endif

/// An abstraction over URL session behavior, allowing custom implementations of network sessions.
///
/// `SmartURLSession` defines the minimal interface required to perform asynchronous network requests
/// using a `URLRequest`, returning streamed bytes and a corresponding response. This is especially useful
/// for injecting custom sessions (e.g., mocks, logging wrappers, or metrics collectors) into network layers
/// without relying on `URLSession` directly.
public protocol SmartURLSession {
    /// The configuration object defining behavior and policies for the session.
    ///
    /// This includes options like caching policy, timeout durations, cookie handling, and more.
    var configuration: URLSessionConfiguration { get }

    /// Creates and starts a network task for the specified request.
    ///
    /// This method performs the network operation asynchronously and returns a tuple containing the streamed byte response
    /// and the associated `URLResponse`.
    ///
    /// - Parameter request: The `URLRequest` to perform.
    /// - Returns: A tuple of `(URLSession.AsyncBytes, URLResponse)` representing the streamed response and metadata.
    /// - Throws: An error if the request fails.
    func task(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse)
}
