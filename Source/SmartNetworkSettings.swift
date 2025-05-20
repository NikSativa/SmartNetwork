import Foundation
import Threading

@available(*, deprecated, renamed: "SmartNetworkSettings", message: "Use 'SmartNetworkSettings' instead.")
public typealias RequestSettings = SmartNetworkSettings

#if swift(>=6.0)
/// Centralized configuration for default networking behavior used by SmartNetwork.
///
/// `SmartNetworkSettings` defines shared defaults such as session behavior, request formatting, and cURL representation
/// preferences. These values apply globally unless explicitly overridden at the request level.
public enum SmartNetworkSettings: Sendable {
    /// The default URL session used for all requests unless overridden in individual parameters.
    /// Defaults to `URLSession.shared`.
    public nonisolated(unsafe) static var sharedSession: URLSession = .shared

    /// The default queue on which response callbacks are delivered. Defaults to the main queue.
    public nonisolated(unsafe) static var defaultCompletionQueue: DelayedQueue = .async(Queue.main)

    /// The default queue used to defer request startup execution. Always runs asynchronously on the main queue.
    public nonisolated(unsafe) static var deferredStartQueue: Queueable = Queue.main

    /// Appends a trailing slash to the URL endpoint if missing when constructing URLs using `URLComponents`.
    ///
    /// This is helpful for consistency in request URLs such as converting `https://host.com/endpoint` to
    /// `https://host.com/endpoint/` before adding query parameters.
    public nonisolated(unsafe) static var shouldAddSlashAfterEndpoint: Bool = false

    /// Removes leading slashes (`//`) when constructing URLs with an empty scheme.
    ///
    /// Use with caution. It's recommended to always specify a valid URL scheme to avoid malformed URLs.
    public nonisolated(unsafe) static var shouldRemoveSlashesForEmptyScheme: Bool = false

    /// The default timeout interval for all network requests, in seconds.
    public nonisolated(unsafe) static var timeoutInterval: TimeInterval = 30

    /// Adds a `$` symbol at the beginning of generated `cURL` commands, useful for shell demonstration output.
    public nonisolated(unsafe) static var curlStartsWithDollar: Bool = false

    /// Generated `cURL` commands for pretty-printing JSON output in compatible shells.
    ///
    /// This improves readability of JSON responses when pasting cURL commands into terminal environments.
    public nonisolated(unsafe) static var curlPrettyPrinted: Bool = false

    /// Enables pretty-printing of JSON output in generated `cURL` commands using `json_pp`.
    ///
    /// When enabled, the `cURL` output will append `| json_pp`, improving readability of JSON responses in terminal environments.
    public nonisolated(unsafe) static var curlAddJSON_PP: Bool = false

    /// Adds JSON-specific headers to generated `cURL` commands.
    ///
    /// When enabled, appends `-H "Accept: application/json"` and `-H "Content-Type: application/json"` to ensure correct server handling of JSON payloads.
    public nonisolated(unsafe) static var curlAddJSONHeaders: Bool = false

    /// A set of headers to exclude from generated `cURL` commands.
    ///
    /// These are typically added automatically by the networking stack or not useful for reproduction.
    ///
    /// - Important: `Content-Length` must be removed and always disallowed because `httpBodyData` is modified during cURL formatting
    public nonisolated(unsafe) static var curlDisallowedHeaders: [String] = [
        "Accept-Encoding",
        "Content-Length",
        "Connection",
        "Accept",
        "Host"
    ]
}
#else
/// Centralized configuration for default networking behavior used by SmartNetwork.
///
/// `SmartNetworkSettings` defines shared defaults such as session behavior, request formatting, and cURL representation
/// preferences. These values apply globally unless explicitly overridden at the request level.
public enum SmartNetworkSettings {
    /// The default URL session used for all requests unless overridden in individual parameters.
    /// Defaults to `URLSession.shared`.
    public static var sharedSession: URLSession = .shared

    /// The default queue on which response callbacks are delivered. Defaults to the main queue.
    public static var defaultCompletionQueue: DelayedQueue = .async(Queue.main)

    /// The default queue used to defer request startup execution. Always runs asynchronously on the main queue.
    public static var deferredStartQueue: Queueable = Queue.main

    /// Appends a trailing slash to the URL endpoint if missing when constructing URLs using `URLComponents`.
    ///
    /// This is helpful for consistency in request URLs such as converting `https://host.com/endpoint` to
    /// `https://host.com/endpoint/` before adding query parameters.
    public static var shouldAddSlashAfterEndpoint: Bool = false

    /// Removes leading slashes (`//`) when constructing URLs with an empty scheme.
    ///
    /// Use with caution. It's recommended to always specify a valid URL scheme to avoid malformed URLs.
    public static var shouldRemoveSlashesForEmptyScheme: Bool = false

    /// The default timeout interval for all network requests, in seconds.
    public static var timeoutInterval: TimeInterval = 30

    /// Adds a `$` symbol at the beginning of generated `cURL` commands, useful for shell demonstration output.
    public static var curlStartsWithDollar: Bool = false

    /// Generated `cURL` commands for pretty-printing JSON output in compatible shells.
    ///
    /// This improves readability of JSON responses when pasting cURL commands into terminal environments.
    public static var curlPrettyPrinted: Bool = false

    /// Enables pretty-printing of JSON output in generated `cURL` commands using `json_pp`.
    ///
    /// When enabled, the `cURL` output will append `| json_pp`, improving readability of JSON responses in terminal environments.
    public static var curlAddJSON_PP: Bool = false

    /// Adds JSON-specific headers to generated `cURL` commands.
    ///
    /// When enabled, appends `-H "Accept: application/json"` and `-H "Content-Type: application/json"` to ensure correct server handling of JSON payloads.
    public static var curlAddJSONHeaders: Bool = false

    /// A set of headers to exclude from generated `cURL` commands.
    ///
    /// These are typically added automatically by the networking stack or not useful for reproduction.
    ///
    /// - Important: `Content-Length` must be removed and always disallowed because `httpBodyData` is modified during cURL formatting
    public static var curlDisallowedHeaders: [String] = [
        "Accept-Encoding",
        "Content-Length",
        "Connection",
        "Accept",
        "Host"
    ]
}
#endif
