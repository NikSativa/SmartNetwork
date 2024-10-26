import Foundation

// MARK: - URLSession + SmartURLSession

extension URLSession: SmartURLSession {
    public func task(with request: URLRequest,
                     completionHandler: @escaping CompletionHandler) -> SessionTask {
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
