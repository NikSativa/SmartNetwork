import Foundation

#if swift(>=6.0)
public typealias ProgressHandler = @Sendable (Progress) -> Void

public protocol Session: Sendable {
    typealias CompletionHandler = @Sendable (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask
}
#else
public typealias ProgressHandler = (Progress) -> Void

public protocol Session {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask
}
#endif

public protocol SessionTask {
    var progress: Progress { get }

    var isRunning: Bool { get }

    func resume()
    func cancel()
}
