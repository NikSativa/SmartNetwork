#if canImport(os)
import Foundation
import os

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public extension Plugins {
    #if swift(>=6.0)
    /// A type that maps the ID and URL to a loggable strings.
    ///
    /// - Important: If returning `nil`, it will not be logged.
    typealias CurlOSMapper = @Sendable (_ id: String, _ url: String) -> String?

    /// Logger generator
    typealias LoggerGenerator = @Sendable (_ data: Plugins.Log.DataCollection) -> os.Logger
    #else
    /// A type that maps the ID and URL to a loggable strings.
    ///
    /// - Important: If returning `nil`, it will not be logged.
    typealias CurlOSMapper = (_ id: String, _ url: String) -> String?

    /// Logger generator
    typealias LoggerGenerator = (_ data: Plugins.Log.DataCollection) -> os.Logger
    #endif

    enum LoggerProvider: SmartSendable {
        case `default`
        case custom(os.Logger)
        case generator(LoggerGenerator)
        case identifiable
    }

    /// A plugin that logs the request in the `curl` format.
    /// - Parameters:
    ///  - priority: The priority of the plugin.
    ///  - logger: The `os.Logger` which will make logging, if you want override destination. The default value is `nil`.
    ///  - shouldPrintBody: A flag that indicates whether the response body should be printed to the console or to the logger. The default value is `false`.
    ///  - options: The options for the `Curl` plugin. The default value is `.all`.
    ///  - mapID: A closure that maps the ID and URL to a loggable string. The default value is `nil`.
    ///
    /// - Note: Sometimes the response body can be very large, so it is better to print it to the console for debugging purposes.
    static func LogOS(priority: PluginPriority = .curlOS,
                      logger: LoggerProvider = .default,
                      shouldPrintBody: Bool = false,
                      options: Plugins.Log.Options = .all,
                      mapID: CurlOSMapper? = nil) -> Plugins.Log {
        return .init(id: Plugins.Log.makeHash(withAdditionalHash: "OS"),
                     priority: priority,
                     options: options) { [mapID, shouldPrintBody] data in
            let logger = logger.get(data)

            let id: String?
            if let mapID,
               let uuid = data.get(safe: .id, ofType: UUID.self)?.uuidString,
               let url = data.get(safe: .url, ofType: String.self),
               let str = mapID(uuid, url) {
                id = str
            } else {
                id = nil
            }

            for (component, value) in data {
                let text: String
                let value = value()
                if let value = value as? String {
                    text = value
                } else if let value = rawable(value) {
                    text = value
                } else {
                    continue
                }

                if component == .body, shouldPrintBody {
                    #if DEBUG
                    print(text)
                    #endif
                } else if let id {
                    logger.log(level: component == .error ? .error : .info, "\(text) - \(id)")
                } else {
                    logger.log(level: component == .error ? .error : .info, "\(text)")
                }
            }
        }
    }
}

internal func rawable(_ value: Any) -> String? {
    let mirror = Mirror(reflecting: value)
    return mirror.children.first(where: { $0.label == "rawValue" })?.value as? String
}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public extension Plugins.LoggerProvider {
    private static let defaultLogger: os.Logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "SmartNetwork", category: "Plugins.LogOS")

    func get(_ data: Plugins.Log.DataCollection) -> os.Logger {
        switch self {
        case .default:
            return Self.defaultLogger
        case .custom(let logger):
            return logger
        case .generator(let generator):
            return generator(data)
        case .identifiable:
            let url = data[.url, ofType: String.self]
            let uuid = data[.id, ofType: UUID.self].uuidString
            let identity = PluginsLogIdentity(uuid, url)
            return .init(subsystem: Bundle.main.bundleIdentifier ?? "SmartNetwork", category: "Plugins.LogOS.\(identity)")
        }
    }
}

@inline(__always)
public func PluginsLogIdentity(_ uuid: String, _ url: String) -> String {
    let path: String = ((try? AddressDetails(string: url))?.path).map { $0.isEmpty ? "< root >" : $0.joined(separator: "/") } ?? "< unknown path >"
    let id: String = uuid.components(separatedBy: "-").first ?? uuid
    let identity = path + " " + id
    return identity
}
#endif
