import Foundation

/// Namespace for plugins. You can create your own plugins and add them to this namespace.
public enum Plugins {}

/// Defines a modular plugin interface for request interception and response validation in SmartNetwork.
///
/// Plugins conforming to this protocol can modify requests, validate responses, handle cancellations,
/// or observe network flow at different stages of a request's lifecycle.
///
/// ![Network scheme](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/SmartNetwork.jpg)
/// ![Plugins behavior](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/Plugins_behavior.jpg)
public protocol Plugin: SmartSendable {
    typealias ID = String

    /// A unique ID that guarantees that plugins are not duplicated
    ///
    /// - Note: you can use helpers **makeHash()** or **makeHash(withAdditionalHash:...)** to generate a unique ID
    var id: ID { get }

    /// The priority in which the plugin will be executed in the list of plugins.
    var priority: PluginPriority { get }

    /// Called before the request is sent, allowing modification of the request or its metadata.
    ///
    /// - Parameters:
    ///   - parameters: The request configuration.
    ///   - userInfo: User-defined metadata associated with the request.
    ///   - request: The mutable request representation.
    ///   - session: The session used to send the request.
    func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async

    /// Called right before the request is dispatched. Can be invoked multiple times depending on StopTheLine logic.
    func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession)

    /// Called immediately after a response is received. Can be invoked multiple times depending on StopTheLine logic.
    func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, data: SmartResponse)

    /// Called after the response is received to perform custom validation.
    ///
    /// - Throws: An error if the response should be treated as a failure. Only the first thrown error will be passed forward.
    func verify(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) throws

    /// Called once the request completes successfully or fails. Runs just before completion is dispatched.
    func didFinish(parameters: Parameters, userInfo: UserInfo, data: SmartResponse)

    /// Called when the request is cancelled. May be invoked multiple times. Used for debugging or cleanup logic.
    ///
    /// - Note: This method has a default empty implementation.
    func wasCancelled(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession)
}

public extension Plugin {
    var id: ID {
        return Self.makeHash()
    }

    /// Generates a unique ID for the plugin based on its type.
    static func makeHash() -> ID {
        return makeHashStr()
    }

    /// Generates a unique ID for the plugin using an additional hash component.
    ///
    /// - Parameter hash: A string or integer to include in the plugin's hash identifier.
    static func makeHash(withAdditionalHash hash: ID) -> ID {
        return [makeHashStr(), hash].joined(separator: ".")
    }

    /// Generates a unique ID for the plugin using an additional hash component.
    ///
    /// - Parameter hash: A string or integer to include in the plugin's hash identifier.
    static func makeHash(withAdditionalHash hash: PluginPriority.RawValue) -> ID {
        return makeHash(withAdditionalHash: "\(hash)")
    }

    func wasCancelled(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {
        // nothing to do
    }

    private static func makeHashStr() -> String {
        return String(reflecting: self)
    }
}

internal extension [Plugin] {
    /// Returns a deduplicated list of plugins based on their `id` property.
    func unified() -> [Plugin] {
        var unique: [Plugin] = []
        var s: Set<AnyHashable> = []
        for element in self {
            if s.insert(element.id).inserted {
                unique.append(element)
            }
        }

        return unique
    }
}
