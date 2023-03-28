import Foundation

public typealias ProgressHandler = (Progress) -> Void

public protocol SessionTask {
    var progress: Progress { get }

    var isRunning: Bool { get }

    func resume()
    func cancel()
}

public protocol Session {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask
}
