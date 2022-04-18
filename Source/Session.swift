import Foundation

public typealias ProgressHandler = (Progress) -> Void

// sourcery: fakable
public protocol ProgressObservable {
    @available(iOS 11, *)
    func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject
}

// sourcery: fakable
public protocol SessionTask: ProgressObservable {
    @available(iOS 11, *)
    var progressContainer: Progress { get }

    var isRunning: Bool { get }

    func resume()
    func cancel()
}

// sourcery: fakable
public protocol SessionDelegate: URLSessionDataDelegate {}

// sourcery: fakable
public protocol Session: AnyObject {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask

    func copy(with delegate: SessionDelegate) -> Session
    func finishTasksAndInvalidate()
}
