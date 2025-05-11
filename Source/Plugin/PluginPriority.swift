import Foundation

/// Represents the execution priority of a plugin in the SmartNetwork pipeline.
///
/// Plugins with lower priority values are executed earlier. This allows you to control the order
/// of plugin execution, especially when plugins have dependencies or side effects.
/// Predefined priorities are provided for built-in plugins, and custom values can be created as needed.
public struct PluginPriority: Comparable, Hashable, RawRepresentable, SmartSendable {
    public typealias RawValue = Int

    /// The underlying integer value representing plugin execution order.
    ///
    /// Lower values execute earlier. Used to sort plugins in the SmartNetwork pipeline.
    public let rawValue: RawValue

    /// Creates a custom plugin priority from a raw integer value.
    ///
    /// - Parameter rawValue: An integer that determines the execution order of the plugin.
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    /// Default priority for the `Plugins.AuthBasic` plugin.
    ///
    /// Set to 100 to ensure it executes early in the pipeline.
    public static let authBasic: Self = .init(rawValue: 100)

    /// Default priority for the `Plugins.AuthBearer` plugin.
    ///
    /// Executes after `authBasic`.
    public static let authBearer: Self = .init(rawValue: 200)

    /// Default priority for the `Plugins.StatusCode` plugin.
    ///
    /// Typically used for handling response validation.
    public static let statusCode: Self = .init(rawValue: 300)

    /// Default priority for the `Plugins.Log` plugin.
    ///
    /// Executes late in the pipeline to capture final request state.
    public static let curl: Self = .init(rawValue: .max - 200)

    /// Default priority for the `Plugins.LogOS` plugin (Apple OS logging).
    ///
    /// Executes just before `curl`, platform-dependent.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public static let curlOS: Self = curl - 1

    /// Default priority for the `Plugins.JSONHeaders` plugin.
    ///
    /// Uses a very high value to ensure headers are added after other plugins have executed.
    public static let jsonHeaders: Self = .init(rawValue: .max - 100)

    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public extension [Plugin] {
    /// Sorts and returns all plugins in ascending order of execution priority.
    ///
    /// Use this to ensure plugins are applied in the intended sequence.
    func prepareForExecution() -> [Plugin] {
        return unified().sorted { $0.priority < $1.priority }
    }
}

// MARK: - AdditiveArithmetic

public extension PluginPriority {
    /// Returns a new `PluginPriority` by adding two priorities.
    ///
    /// Performs overflow-safe addition on supported platforms.
    static func +(lhs: Self, rhs: Self) -> PluginPriority {
        #if swift(>=6.0) && !supportsVisionOS
        if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            assert(Int128(lhs.rawValue) + Int128(rhs.rawValue) <= Int128(RawValue.max), "Cannot add two values that overflow.")
        }
        #endif
        return .init(rawValue: lhs.rawValue &+ rhs.rawValue)
    }

    /// Returns a new `PluginPriority` by subtracting one priority from another.
    ///
    /// Performs overflow-safe subtraction on supported platforms.
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
    /// Allows initialization of `PluginPriority` using integer literals.
    ///
    /// Example:
    /// ```swift
    /// let priority: PluginPriority = 150
    /// ```
    public init(integerLiteral value: RawValue) {
        self.init(rawValue: value)
    }
}
