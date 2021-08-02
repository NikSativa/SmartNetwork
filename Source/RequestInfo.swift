import Foundation

public struct RequestInfo {
    public var request: URLRequestable
    private(set) public var parameters: Parameters

    /// used only on client side. best practice to use it to identify request in the Plugin's
    public var userInfo: [String: Any] {
        get {
            parameters.userInfo
        }
        set {
            parameters.userInfo = newValue
        }
    }
}

extension RequestInfo {
    init(request: URLRequest,
         parameters: Parameters) {
        self.request = Impl.URLRequestable(request)
        self.parameters = parameters
    }
}
