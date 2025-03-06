import Foundation

/// A structure representing a key path used to access nested values in data structures.
/// Supports fallback values and error handling.
///
/// Example Usage:
/// ```swift
/// let keyPath: DecodableKeyPath<DTO> = ["user", "profile", "name"]
/// let keyPath: DecodableKeyPath<DTO> = "user/profile/name"
/// let singleKeyPath: DecodableKeyPath<DTO> = "user"
/// ```
public struct DecodableKeyPath<T> {
    /// Enumeration defining fallback behavior for inaccessible or missing key paths.
    public enum Fallback {
        /// Specifies an error to be thrown or logged when the key path is invalid.
        case error(Error)
        /// Provides a default value of type `T`.
        case value(T)
    }

    /// An array of strings representing the sequence of keys in the key path.
    public let path: [String]
    /// An optional fallback value to handle errors or provide default values.
    public let fallback: Fallback?

    /// Initializes a `DecodableKeyPath` instance.
    ///
    /// Example Usage:
    /// ```swift
    /// let keyPath: DecodableKeyPath<DTO> = ["user", "profile", "name"]
    /// ```
    ///
    /// - Parameters:
    ///   - path: An array of strings representing the key path.
    ///   - fallback: An optional `Fallback` value for error handling or default values.
    ///
    /// - Note: Throws `RequestDecodingError`.brokenKeyPath(...) error if fallback is not specified.
    public init(path: [String] = [], fallback: Fallback? = nil) {
        self.path = path
        self.fallback = fallback
    }

    /// Initializes a `DecodableKeyPath` instance.
    /// Path components should be separated by forward slashes (/) or be a single key of path.
    ///
    /// Example Usage:
    /// ```swift
    /// let keyPath: DecodableKeyPath<DTO> = "user/profile/name"
    /// let singleKeyPath: DecodableKeyPath<DTO> = "user"
    /// ```
    ///
    /// - Parameters:
    ///   - path: An array of strings representing the key path.
    ///   - fallback: An optional `Fallback` value for error handling or default values.
    ///
    /// - Note: Throws `RequestDecodingError`.brokenKeyPath(...) error if fallback is not specified.
    public init(path: String, fallback: Fallback? = nil) {
        let path = path.components(separatedBy: "/").filter {
            return !$0.isEmpty
        }
        self.path = path
        self.fallback = fallback
    }
}

// MARK: - ExpressibleByArrayLiteral

extension DecodableKeyPath: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        self.init(path: elements)
    }
}

// MARK: - ExpressibleByStringLiteral

extension DecodableKeyPath: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(path: value)
    }
}

#if swift(>=6.0)
extension DecodableKeyPath: Sendable where T: Sendable {}
extension DecodableKeyPath.Fallback: Sendable where T: Sendable {}
#endif
