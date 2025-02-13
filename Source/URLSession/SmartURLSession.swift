import Foundation

#if swift(>=6.0)
/// A type representing the progress of a task.
public typealias ProgressHandler = @Sendable (Progress) -> Void
#else
/// A type representing the progress of a task.
public typealias ProgressHandler = (Progress) -> Void
#endif

/// A type representing a network session which you can override for your own behaviours.
public protocol SmartURLSession {
    var configuration: URLSessionConfiguration { get }
    func task(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse)
}
