import Foundation

public struct QueryItem: Hashable {
    public let key: String
    public let value: String?

    public init(key: String, value: String?) {
        self.key = key
        self.value = value
    }

    private var myDescription: String {
        return [key, value].compactMap {
            return $0
        }.joined(separator: ": ")
    }
}

// MARK: - CustomStringConvertible

extension QueryItem: CustomStringConvertible {
    public var description: String {
        return myDescription
    }
}

// MARK: - CustomDebugStringConvertible

extension QueryItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        return myDescription
    }
}

#if swift(>=6.0)
extension QueryItem: Sendable {}
#endif
