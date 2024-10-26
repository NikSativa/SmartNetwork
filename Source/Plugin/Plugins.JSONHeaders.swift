import Foundation

// MARK: - Plugins.JSONHeaders

extension Plugins {
    struct JSONHeaders {
        let priority: PluginPriority

        init(priority: PluginPriority = .jsonHeaders) {
            self.priority = priority
        }
    }
}

// MARK: - Plugins.JSONHeaders + Plugin

extension Plugins.JSONHeaders: Plugin {
    func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation) {
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

    func didFinish(withData data: RequestResult, userInfo: UserInfo) {}
    func verify(data: RequestResult, userInfo: UserInfo) throws {}
    func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo) {}
    func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {}
}
