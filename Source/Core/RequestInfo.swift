import Foundation

public struct RequestInfo {
    public var request: URLRequestable
    public let parameters: Parameters
}

extension RequestInfo {
    init(request: URLRequest,
         parameters: Parameters) {
        self.request = Impl.URLRequestable(request)
        self.parameters = parameters
    }
}
