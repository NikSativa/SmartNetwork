import Foundation

/// Namespace for plugins. You can create your own plugins and add them to this namespace.
public enum Plugins {}

/// Protocol that defines the mechanism of request interception and response validation.
///
/// See detailed scheme how network works:
/// ![Network scheme](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/SmartNetwork.jpg)
///
/// See the diagram of how the plugins work:
/// ![Plugins behavior](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/Plugins_behavior.jpg)
public protocol Plugin: SmartSendable {
    typealias ID = String

    /// A unique ID that guarantees that plugins are not duplicated
    ///
    /// - Note: you can use helpers **makeHash()** or **makeHash(withAdditionalHash:...)** to generate a unique ID
    var id: ID { get }

    /// The priority in which the plugin will be executed in the list of plugins.
    var priority: PluginPriority { get }

    /// A function that will be called before the request is sent.
    func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async

    /// Super internal level which can be called multiple time based on your 'StopTheLine' implementation.
    func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession)

    /// Super internal level which can be called multiple time based on your 'StopTheLine' implementation.
    func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, data: SmartResponse)

    /// A function that will be called after the response is received.
    ///
    /// - Note: if the response is not successful, you can throw an error here.
    /// - Important: only the first error thrown will be passed to the completion block and the rest will be ignored.
    func verify(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) throws

    /// Just before the completion call
    func didFinish(parameters: Parameters, userInfo: UserInfo, data: SmartResponse)

    /// Just a notification that the request was somehow cancelled. can be called at any time and multiple times. for debug purposes or your own logic
    ///
    /// - Note: has an empty default implementation
    func wasCancelled(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession)
}

public extension Plugin {
    var id: ID {
        return Self.makeHash()
    }

    /// Creates a unique ID for the plugin
    static func makeHash() -> ID {
        return makeHashStr()
    }

    /// Creates a unique ID for the plugin with additional hash value.
    static func makeHash(withAdditionalHash hash: ID) -> ID {
        return [makeHashStr(), hash].joined(separator: ".")
    }

    /// Creates a unique ID for the plugin with additional hash value.
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
