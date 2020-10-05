import Foundation

public struct PluginInfo {
    public let request: URLRequest
    public let parameters: Parameters

    public init(request: URLRequest,
                parameters: Parameters) {
        self.request = request
        self.parameters = parameters
    }
}

public protocol Plugin {
    typealias Info = PluginInfo

    func prepare(_ info: Info) -> URLRequest
    func willSend(_ info: Info)
    func didFinish(_ info: Info, response: URLResponse?, with error: Error?, statusCode: Int?)

    func should(wait info: Info, response: URLResponse?, with error: Error?, forRetryCompletion: @escaping (_ shouldRetry: Bool) -> Void) -> Bool

    func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws
}

public extension Plugin {
    func prepare(_ info: Info) -> URLRequest {
        return info.request
    }

    func willSend(_ info: Info) {
    }

    func didFinish(_ info: Info, response: URLResponse?, with error: Error?, statusCode: Int?) {
    }

    func should(wait info: Info, response: URLResponse?, with error: Error?, forRetryCompletion: @escaping (_ shouldRetry: Bool) -> Void) -> Bool {
        return false
    }

    func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
    }
}
