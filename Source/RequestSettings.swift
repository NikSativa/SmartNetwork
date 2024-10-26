import Foundation
import Threading

/// shortname only for internal usage
internal typealias RS = RequestSettings

#if swift(>=6.0)
/// Global settings for every request
/// - can override in Parameters for individual tasks
public enum RequestSettings: Sendable {
    public nonisolated(unsafe) static var sharedSession: SmartURLSession = URLSession.shared

    /// Default queue for responses
    public nonisolated(unsafe) static var defaultResponseQueue: DelayedQueue = .async(Queue.main)

    /// Default queue for `requestingTask.defferedStart()` command - always async
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
}
#else
/// Global settings for every request
/// - can override in Parameters for individual tasks
public enum RequestSettings {
    public static var sharedSession: SmartURLSession = URLSession.shared

    /// Default queue for responses
    public static var defaultResponseQueue: DelayedQueue = .async(Queue.main)

    /// Default queue for `requestingTask.defferedStart()` command - always async
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
}
#endif
