#if canImport(os)
import Foundation
import os

public extension PluginPriority {
    /// The priority of the `Plugins.curlOS` plugin.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    static let curlOS: Self = curl - 1
}

public extension Plugins {
    /// A plugin that logs the request in the `curl` format.
    /// - Parameters:
    ///  - priority: The priority of the plugin.
    ///  - shouldPrintBody: A flag that indicates whether the response body should be printed to the console or to the logger. The default value is `false`.
    ///  - options: The options for the `Curl` plugin. The default value is `.all`.
    ///
    /// - Note: Sometimes the response body can be very large, so it is better to print it to the console for debugging purposes.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    static func CurlOS(priority: PluginPriority = .curlOS,
                       logger: Logger? = nil,
                       shouldPrintBody: Bool = false,
                       options: Plugins.Curl.Options = .all) -> Plugins.Curl {
        let logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "SmartNetwork.curlOS", category: "Network")
        return Plugins.Curl(id: Plugins.Curl.makeHash(withAdditionalHash: "OS"),
                            priority: priority) { component, text in
            let text: String? = text()
            switch component {
            case .phase:
                let text = text ?? "< unknown phase >"
                logger.log(level: .info, "\(text)")
            case .curl:
                let new = text?.replacingOccurrences(of: "-H \"Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8\"", with: "")
                if let new {
                    logger.log(level: .info, "\(new)")
                } else {
                    logger.log(level: .error, "< can't create curl >")
                }
            case .error:
                if let text {
                    logger.log(level: .error, "error: \(text)")
                }
            case .body:
                let text = text ?? "< body is nil >"
                if shouldPrintBody {
                    print(text)
                } else {
                    logger.log(level: .info, "\(text)")
                }
            }
        }
    }
}
#endif
