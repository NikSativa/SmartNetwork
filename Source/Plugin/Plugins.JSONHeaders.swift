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
    public func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async {
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

    public func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {}
    public func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, data: SmartResponse) {}
    public func verify(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) throws {}
    public func didFinish(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) {}
}
