import Foundation

// MARK: - Plugins.JSONHeaders

public extension Plugins {
    struct JSONHeaders {
        public let priority: PluginPriority

        public init(priority: PluginPriority = .jsonHeaders) {
            self.priority = priority
        }
    }
}

// MARK: - Plugins.JSONHeaders + Plugin

extension Plugins.JSONHeaders: Plugin {
    public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation, session: SmartURLSession) {
        if let host = request.url?.host,
           request.value(forHTTPHeaderField: "Host") == nil {
            request.setValue(host, forHTTPHeaderField: "Host")
        }

        if request.value(forHTTPHeaderField: "Accept") == nil {
            request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        }

        if request.value(forHTTPHeaderField: "Accept-Encoding") == nil {
            request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        }

        if request.value(forHTTPHeaderField: "Connection") == nil {
            request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        }
    }

    public func didFinish(withData data: RequestResult, userInfo: UserInfo) {}
    public func verify(data: RequestResult, userInfo: UserInfo) throws {}
    public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo, session: SmartURLSession) {}
    public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {}
}
