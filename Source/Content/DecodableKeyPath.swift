import Foundation

/// Represents a key path for accessing nested values during decoding.
///
/// `DecodableKeyPath` enables structured access to deeply nested values within a JSON object or other
/// keyed containers. Supports fallback behavior for missing or invalid paths.
///
/// Example Usage:
/// ```swift
/// let keyPath: DecodableKeyPath<DTO> = ["user", "profile", "name"]
/// let keyPath: DecodableKeyPath<DTO> = "user/profile/name"
/// let singleKeyPath: DecodableKeyPath<DTO> = "user"
/// ```
public struct DecodableKeyPath<T> {
    /// Defines fallback behavior when decoding a value at the specified key path fails.
    public enum Fallback {
        /// Throws or logs the provided error when the key path is invalid or inaccessible.
        case error(Error)
        /// Returns a predefined default value when decoding fails.
        case value(T)
    }

    /// The sequence of keys used to navigate nested containers.
    public let path: [String]
    /// Optional fallback behavior applied when decoding at the path fails.
    public let fallback: Fallback?

    /// Initializes a `DecodableKeyPath` from an array of key components.
    ///
    /// - Parameters:
    ///   - path: An array of strings representing the key path.
    ///   - fallback: An optional fallback behavior to apply on decoding failure.
    ///
    /// - Note: If no fallback is provided, decoding failure will result in a `RequestDecodingError.brokenKeyPath(...)`.
    public init(path: [String] = [], fallback: Fallback? = nil) {
        self.path = path
        self.fallback = fallback
    }

    /// Initializes a `DecodableKeyPath` from a slash-delimited string.
    ///
    /// - Parameters:
    ///   - path: A forward-slash-separated string representing the key path (e.g., "user/profile/name").
    ///   - fallback: An optional fallback behavior to apply on decoding failure.
    ///
    /// - Note: If no fallback is provided, decoding failure will result in a `RequestDecodingError.brokenKeyPath(...)`.
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
