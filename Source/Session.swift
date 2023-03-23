import Foundation

public typealias ProgressHandler = (Progress) -> Void

public protocol ProgressObservable {
    func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject
}

public protocol SessionTask: ProgressObservable {
    var progress: Progress { get }

    var isRunning: Bool { get }

    func resume()
    func cancel()
}

public protocol Session {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask
}
