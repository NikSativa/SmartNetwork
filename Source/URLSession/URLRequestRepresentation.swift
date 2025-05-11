import Foundation

/// An abstraction for working with `URLRequest` values in a uniform and testable way.
///
/// `URLRequestRepresentation` provides a standardized interface for accessing and modifying components of an
/// HTTP request—such as its headers, URL, and body—without directly exposing the underlying `URLRequest` value.
/// This protocol supports dependency injection and testing by allowing mocking and inspection of requests
/// without requiring actual network transmission.
public protocol URLRequestRepresentation: SmartSendable, CURLConvertible {
    /// The underlying URL request.
    var sdk: URLRequest { get set }

    /// The request’s HTTP header fields.
    var allHTTPHeaderFields: [String: String]? { get set }

    /// The request URL.
    var url: URL? { get set }

    /// The body data of the request.
    var httpBody: Data? { get set }

    /// Returns the value for the specified HTTP header field.
    ///
    /// - Parameter field: The name of the header field.
    /// - Returns: The value for the specified field, or `nil` if not present.
    func value(forHTTPHeaderField field: String) -> String?

    /// Adds a value to the existing values of the specified HTTP header field.
    ///
    /// - Parameters:
    ///   - value: The value to add.
    ///   - field: The name of the header field.
    mutating func addValue(_ value: String, forHTTPHeaderField field: String)

    /// Sets the value of the specified HTTP header field, replacing any existing value.
    ///
    /// - Parameters:
    ///   - value: The value to set. Use `nil` to remove the field.
    ///   - field: The name of the header field.
    mutating func setValue(_ value: String?, forHTTPHeaderField field: String)
}

// MARK: - URLRequest + URLRequestRepresentation

/// Extends `URLRequest` to conform to `URLRequestRepresentation`, enabling unified request handling and inspection.
///
/// This extension allows `URLRequest` instances to be used wherever a `URLRequestRepresentation` is expected,
/// supporting mutation, inspection, and conversion to cURL commands for debugging or testing purposes.
extension URLRequest: URLRequestRepresentation {
    /// Provides a self-referential getter and setter for the underlying `URLRequest`.
    ///
    /// This enables mutating operations via the `URLRequestRepresentation` interface.
    public var sdk: URLRequest {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}

public extension URLRequestRepresentation {
    /// Generates a `cURL` command string representing this request instance.
    ///
    /// This method uses the `sdk` property to extract request details and generate an equivalent `cURL` command.
    /// It supports optional pretty-printing for JSON responses and uses the shared session by default.
    ///
    /// - Parameters:
    ///   - session: The session whose configuration is used to resolve headers, cookies, and credentials. Defaults to `SmartNetworkSettings.sharedSession`.
    ///   - prettyPrinted: If `true`, appends `| json_pp` to the command for JSON output formatting. Defaults to `false`.
    /// - Returns: A `String` representing the equivalent `cURL` command.
    func cURLDescription(with session: SmartURLSession = SmartNetworkSettings.sharedSession, prettyPrinted: Bool = false) -> String {
        return cURLDescription(with: session, request: sdk, prettyPrinted: prettyPrinted)
    }
}
