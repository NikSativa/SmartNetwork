import Foundation

// MARK: - URLSession + Session

extension URLSession: Session {
    public func task(with request: URLRequest,
                     completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionTask {
        return dataTask(with: request, completionHandler: completionHandler)
    }
}

// MARK: - URLSessionDataTask + SessionTask

extension URLSessionDataTask: SessionTask {
    public var isRunning: Bool {
        return state == .running
    }

    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return progress.observe(progressHandler)
    }
}

// MARK: - Foundation.Progress + ProgressObservable

extension Foundation.Progress: ProgressObservable {
    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return observe(\.fractionCompleted, changeHandler: { progress, _ in
            progressHandler(progress)
        })
    }
}
