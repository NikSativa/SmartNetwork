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
}

// MARK: - Foundation.Progress

public extension Progress {
    func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return observe(\.fractionCompleted, changeHandler: { progress, _ in
            progressHandler(progress)
        })
    }
}
