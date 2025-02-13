import Foundation

/// The priority of the plugins is used to determine the order in which they will be executed.
///
/// The default priority of the plugins is as follows:
///   - `curl`
///   - `authBasic`
///   - `authBearer`
///   - `statusCode`.
///   - `jsonHeaders`
///
///  - Important: The higher the value, the faster the plugin will executed. The lower the value, the later the plugin will be executed.
///  - Note: If you want to change the priority of the plugins, you can create a new instance of this struct with a different value and assign it to the plugin.
public struct PluginPriority: Comparable, Hashable, RawRepresentable {
    public let rawValue: Int

    /// Creates a new instance with the given raw value.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The priority of the `Plugins.AuthBasic` plugin.
    public static let authBasic: Self = .init(rawValue: 400)

    /// The priority of the `Plugins.AuthBearer` plugin.
    public static let authBearer: Self = .init(rawValue: 300)

    /// The priority of the `Plugins.Log` plugin.
    public static let curl: Self = .init(rawValue: .max - 200)

    /// The priority of the `Plugins.LogOS` plugin.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public static let curlOS: Self = curl - 1

    /// The priority of the `Plugins.StatusCode` plugin.
    public static let statusCode: Self = .init(rawValue: 100)

    /// The priority of the `Plugins.JSONHeaders` plugin.
    ///
    /// - Note: min priority to ensure that the headers are set after the other plugins.
    public static let jsonHeaders: Self = .init(rawValue: .min + 100)

    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - AdditiveArithmetic

public extension PluginPriority {
    static func +(lhs: Self, rhs: Self) -> PluginPriority {
        return .init(rawValue: lhs.rawValue + rhs.rawValue)
    }

    static func -(lhs: Self, rhs: Self) -> PluginPriority {
        return .init(rawValue: lhs.rawValue - rhs.rawValue)
    }

    static func +(lhs: Self, rhs: Int) -> PluginPriority {
        return .init(rawValue: lhs.rawValue + rhs)
    }

    static func -(lhs: Self, rhs: Int) -> PluginPriority {
        return .init(rawValue: lhs.rawValue - rhs)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension PluginPriority: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(rawValue: value)
    }
}

#if swift(>=6.0)
extension PluginPriority: Sendable {}
#endif
