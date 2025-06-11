#if canImport(os)
import Foundation
import os

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public extension Plugins {
    #if swift(>=6.0)
    /// A closure that maps a request ID and URL to a loggable string.
    ///
    /// If `nil` is returned, the log entry will be skipped.
    typealias CurlOSMapper = @Sendable (_ id: String, _ url: String) -> String?

    /// A closure that generates a custom `os.Logger` instance for a given logging data context.
    typealias LoggerGenerator = @Sendable (_ data: Plugins.Log.DataCollection) -> os.Logger
    #else
    /// A closure that maps a request ID and URL to a loggable string.
    ///
    /// If `nil` is returned, the log entry will be skipped.
    typealias CurlOSMapper = (_ id: String, _ url: String) -> String?

    /// A closure that generates a custom `os.Logger` instance for a given logging data context.
    typealias LoggerGenerator = (_ data: Plugins.Log.DataCollection) -> os.Logger
    #endif

    /// A strategy for selecting the `os.Logger` used to emit log messages.
    enum LoggerProvider: SmartSendable {
        case `default`
        case custom(os.Logger)
        case generator(LoggerGenerator)
        case identifiable
    }

    /// Creates a plugin that logs network requests using Apple's unified logging system (`os.Logger`).
    ///
    /// The plugin supports structured logging of request/response data, including optional body printing.
    ///
    /// - Parameters:
    ///   - priority: The execution priority of the plugin. Default is `.curlOS`.
    ///   - logger: The logger configuration used to determine the logging destination.
    ///   - shouldPrintBody: Whether to print the response body to the console in debug builds.
    ///   - options: A set of logging options for controlling which parts of the request are logged.
    ///   - mapID: An optional closure for converting request identifiers and URLs into a log-friendly string.
    ///
    /// - Note: In debug builds, large response bodies may be printed to the console instead of being logged.
    static func LogOS(priority: PluginPriority = .curlOS,
                      logger: LoggerProvider = .default,
                      shouldPrintBody: Bool = false,
                      options: Plugins.Log.Options = .all,
                      mapID: CurlOSMapper? = nil) -> Plugins.Log {
        return .init(id: Plugins.Log.makeHash(withAdditionalHash: "OS"),
                     priority: priority,
                     options: options) { [mapID, shouldPrintBody] data in
            let logger = logger.get(data)

            let id: String? =
                if let mapID,
                let uuid = data.get(safe: .id, ofType: UUID.self)?.uuidString,
                let url = data.get(safe: .url, ofType: String.self),
                let str = mapID(uuid, url) {
                    str
                } else {
                    nil
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

/// Attempts to extract a `rawValue` string from an arbitrary value using reflection.
///
/// - Parameter value: The value to inspect.
/// - Returns: A string if a `rawValue` is found; otherwise, `nil`.
internal func rawable(_ value: Any) -> String? {
    let mirror = Mirror(reflecting: value)
    return mirror.children.first(where: { $0.label == "rawValue" })?.value as? String
}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public extension Plugins.LoggerProvider {
    private static let defaultLogger: os.Logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "SmartNetwork", category: "Plugins.LogOS")

    /// Resolves the appropriate `os.Logger` instance based on the current logger configuration.
    ///
    /// - Parameter data: The logging context data for the request.
    /// - Returns: An `os.Logger` for emitting log entries.
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

/// Constructs a unique log identity string based on a request UUID and URL path.
///
/// - Parameters:
///   - uuid: A request identifier.
///   - url: The request URL.
/// - Returns: A string combining the parsed path and a shortened UUID prefix.
@inline(__always)
public func PluginsLogIdentity(_ uuid: String, _ url: String) -> String {
    let path: String = ((try? AddressDetails(string: url))?.path).map { $0.isEmpty ? "< root >" : $0.joined(separator: "/") } ?? "< unknown path >"
    let id: String = uuid.components(separatedBy: "-").first ?? uuid
    let identity = path + " " + id
    return identity
}
#endif
