import Foundation

/// The priority of the plugins is used to determine the order in which they will be executed.
///
/// The default priority of the plugins is as follows:
///   - `authBasic`
///   - `authBearer`
///   - `statusCode`.
///   - `curl`
///   - `jsonHeaders`
///
///  - Important: The value is indicating the index the plugin will executed. The lower the value, the faster the plugin will be executed.
///  - Note: If you want to change the priority of the plugins, you can create a new instance of this struct with a different value and assign it to the plugin.
public struct PluginPriority: Comparable, Hashable, RawRepresentable, SmartSendable {
    public typealias RawValue = Int

    public let rawValue: RawValue

    /// Creates a new instance with the given raw value.
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    /// The priority of the `Plugins.AuthBasic` plugin.
    public static let authBasic: Self = .init(rawValue: 100)

    /// The priority of the `Plugins.AuthBearer` plugin.
    public static let authBearer: Self = .init(rawValue: 200)

    /// The priority of the `Plugins.StatusCode` plugin.
    public static let statusCode: Self = .init(rawValue: 300)

    /// The priority of the `Plugins.Log` plugin.
    public static let curl: Self = .init(rawValue: .max - 200)

    /// The priority of the `Plugins.LogOS` plugin.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public static let curlOS: Self = curl - 1

    /// The priority of the `Plugins.JSONHeaders` plugin.
    ///
    /// - Note: min priority to ensure that the headers are set after the other plugins.
    public static let jsonHeaders: Self = .init(rawValue: .max - 100)

    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public extension [Plugin] {
    /// Retrieves plugins from the unified plugin source and sorts plugins by priority in execution order.
    ///
    /// - Tip: You can use this function to check the execution order in your application.
    func prepareForExecution() -> [Plugin] {
        return unified().sorted { $0.priority < $1.priority }
    }
}

// MARK: - AdditiveArithmetic

public extension PluginPriority {
    static func +(lhs: Self, rhs: Self) -> PluginPriority {
        #if swift(>=6.0) && !supportsVisionOS
        if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            assert(Int128(lhs.rawValue) + Int128(rhs.rawValue) <= Int128(RawValue.max), "Cannot add two values that overflow.")
        }
        #endif
        return .init(rawValue: lhs.rawValue &+ rhs.rawValue)
    }

    static func -(lhs: Self, rhs: Self) -> PluginPriority {
        #if swift(>=6.0) && !supportsVisionOS
        if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            assert(Int128(lhs.rawValue) - Int128(rhs.rawValue) >= Int128(RawValue.min), "Cannot subtract two values that overflow.")
        }
        #endif
        return .init(rawValue: lhs.rawValue &- rhs.rawValue)
    }
}

// MARK: - PluginPriority + ExpressibleByIntegerLiteral

extension PluginPriority: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: RawValue) {
        self.init(rawValue: value)
    }
}
