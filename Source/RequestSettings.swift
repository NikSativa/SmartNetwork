import Foundation
import Threading

#if swift(>=6.0)
/// Global settings for every request
/// - can override in Parameters for individual tasks
public enum RequestSettings: Sendable {
    /// Shared session for all requests which you can override for individual requests in ``Parameters``. Default is `URLSession.shared`
    public nonisolated(unsafe) static var sharedSession: SmartURLSession = URLSession.shared

    /// Default queue for responses
    public nonisolated(unsafe) static var defaultResponseQueue: DelayedQueue = .async(Queue.main)

    /// Default queue for `SmartTasking.defferedStart()` command - always async
    public nonisolated(unsafe) static var defferedStartQueue: Queueable = Queue.main

    /// URLComponents is require scheme and generates url like 'https://some.com/end?param=value'
    /// this parameter will add '/' after domain or andpoint 'https://some.com/end/?param=value'
    public nonisolated(unsafe) static var shouldAddSlashAfterEndpoint: Bool = false

    /// URLComponents is require scheme and generates url like '//some.com/end/?param=value'
    /// this parameter will remove '//' from the begining of new URL
    /// - change this setting on your own risk. I always recommend using the "Address" with the correct "Scheme"
    public nonisolated(unsafe) static var shouldRemoveSlashesForEmptyScheme: Bool = false

    /// Default timeout for every request (in seconds)
    public nonisolated(unsafe) static var timeoutInterval: TimeInterval = 30

    /// If you want to use cURL representation with '$' at the beginning of the line, you can set this parameter to 'true'
    public nonisolated(unsafe) static var curlStartsWithDollar: Bool = false

    /// If you want to use cURL representation with '| json\_pp' in the end of the line, you can set this parameter to 'true'
    public nonisolated(unsafe) static var curlPrettyPrinted: Bool = false

    /// Disallowed headers for cURL representation. Default is ["Accept-Encoding"]. You can add your own headers here to exclude them from cURL representation.
    public nonisolated(unsafe) static var curlDisallowedHeaders: Set<String> = ["Accept-Encoding"]
}
#else
/// Global settings for every request
/// - can override in Parameters for individual tasks
public enum RequestSettings {
    /// Shared session for all requests which you can override for individual requests in ``Parameters``. Default is `URLSession.shared`
    public static var sharedSession: SmartURLSession = URLSession.shared

    /// Default queue for responses
    public static var defaultResponseQueue: DelayedQueue = .async(Queue.main)

    /// Default queue for `SmartTasking.defferedStart()` command - always async
    public static var defferedStartQueue: Queueable = Queue.main

    /// URLComponents is require scheme and generates url like 'https://some.com/end?param=value'
    /// this parameter will add '/' after domain or andpoint 'https://some.com/end/?param=value'
    public static var shouldAddSlashAfterEndpoint: Bool = false

    /// URLComponents is require scheme and generates url like '//some.com/end/?param=value'
    /// this parameter will remove '//' from the begining of new URL
    /// - change this setting on your own risk. I always recommend using the "Address" with the correct "Scheme"
    public static var shouldRemoveSlashesForEmptyScheme: Bool = false

    /// Default timeout for every request (in seconds)
    public static var timeoutInterval: TimeInterval = 30

    /// If you want to use cURL representation with '$' at the beginning of the line, you can set this parameter to 'true'
    public static var curlStartsWithDollar: Bool = false

    /// If you want to use cURL representation with '| json\_pp' in the end of the line, you can set this parameter to 'true'
    public static var curlPrettyPrinted: Bool = false

    /// Disallowed headers for cURL representation. Default is ["Accept-Encoding"]. You can add your own headers here to exclude them from cURL representation.
    public static var curlDisallowedHeaders: Set<String> = ["Accept-Encoding"]
}
#endif
