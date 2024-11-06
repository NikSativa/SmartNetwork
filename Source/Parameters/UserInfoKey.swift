import Foundation

/// A type that represents a namespace of keys for a value in a `UserInfo` dictionary.
public struct UserInfoKey: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - Decodable

extension UserInfoKey: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
}

// MARK: - Encodable

extension UserInfoKey: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

#if swift(>=6.0)
extension UserInfoKey: Sendable {}
#endif
