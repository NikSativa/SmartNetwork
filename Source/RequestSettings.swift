import Foundation
import Threading

/// shortname only for internal usage
internal typealias RS = RequestSettings

/// Global settings for every request
/// - can override in Parameters for individual tasks
public enum RequestSettings {
    public static var sharedSession: Session = URLSession.shared

    /// Default queue
    public static var defaultResponseQueue: DelayedQueue = .async(Queue.main)

    /// URLComponents is require scheme and generates url like 'https://some.com/end?param=value'
    /// this parameter will add '/' after domain or andpoint 'https://some.com/end/?param=value'
    public static var shouldAddSlashAfterEndpoint: Bool = false

    /// URLComponents is require scheme and generates url like '//some.com/end/?param=value'
    /// this parameter will remove '//' from the begining of new URL
    /// - change this setting on your own risk. I always recommend using the "Address" with the correct "Scheme"
    public static var shouldRemoveSlashesForEmptyScheme: Bool = false
}
