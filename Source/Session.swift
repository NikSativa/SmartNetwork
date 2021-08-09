import Foundation

public typealias ProgressHandler = (Progress) -> Void

public protocol ProgressObservable {
    @available(iOS 11, *)
    func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject
}

public protocol SessionTask: ProgressObservable {
    @available(iOS 11, *)
    var progressContainer: Progress { get }

    var isRunning: Bool { get }

    func resume()
    func cancel()
}

public protocol SessionDelegate: URLSessionDataDelegate {
}

public protocol Session: AnyObject {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask

    func copy(with delegate: SessionDelegate) -> Session
    func finishTasksAndInvalidate()
}
