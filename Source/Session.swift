import Foundation

#if swift(>=6.0)
/// A type representing the progress of a task.
public typealias ProgressHandler = @Sendable (Progress) -> Void

/// A type representing a network session which you can override for your own behaviours.
public protocol Session: Sendable {
    typealias CompletionHandler = @Sendable (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask
}
#else
/// A type representing the progress of a task.
public typealias ProgressHandler = (Progress) -> Void

/// A type representing a network session which you can override for your own behaviours.
public protocol Session {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask
}
#endif

/// A type representing a task in a network session.
public protocol SessionTask {
    var progress: Progress { get }

    var isRunning: Bool { get }

    func resume()
    func cancel()
}
