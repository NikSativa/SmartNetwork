import Foundation

public protocol URLRequestRepresentation: SmartSendable, CURLConvertible {
    var sdk: URLRequest { get }
    var allHTTPHeaderFields: [String: String]? { get }
    var url: URL? { get set }
    var httpBody: Data? { get }

    func value(forHTTPHeaderField field: String) -> String?
    mutating func addValue(_ value: String, forHTTPHeaderField field: String)
    mutating func setValue(_ value: String?, forHTTPHeaderField field: String)
}

// MARK: - URLRequest + URLRequestRepresentation

extension URLRequest: URLRequestRepresentation {
    public var sdk: URLRequest {
        return self
    }
}

public extension URLRequestRepresentation {
    /// cURL representation of the instance.
    ///
    /// - Returns: The cURL equivalent of the instance.
    func cURLDescription(with session: SmartURLSession = SmartNetworkSettings.sharedSession) -> String {
        return cURLDescription(with: session, request: sdk)
    }
}
