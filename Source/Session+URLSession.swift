import Foundation

extension URLSession: Session {
    public func task(with request: URLRequest,
                     completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionTask {
        return dataTask(with: request, completionHandler: completionHandler)
    }

    public func copy(with delegate: SessionDelegate) -> Session {
        return URLSession(configuration: configuration,
                          delegate: delegate,
                          delegateQueue: nil)
    }
}

extension URLSessionDataTask: SessionTask {
    public var isRunning: Bool {
        return state == .running
    }

    @available(iOS 11, *)
    public var progressContainer: Progress {
        return .init(fractionCompleted: progress.fractionCompleted)
    }

    @available(iOS 11, *)
    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return progress.observe(progressHandler)
    }
}

extension Foundation.Progress: ProgressObservable {
    @available(iOS 11, *)
    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return observe(\.fractionCompleted, changeHandler: { progress, _ in
            progressHandler(.init(fractionCompleted: progress.fractionCompleted))
        })
    }
}
