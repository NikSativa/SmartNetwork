import Foundation

public typealias QueryItems = [QueryItem]

public extension QueryItems {
    /// add new one
    mutating func append(key: String, value: String?) {
        append(.init(key: key, value: value))
    }

    /// - NOTE: replacing all previously added items and add new one
    mutating func set(_ item: Element) {
        self = filter {
            return $0.key != item.key
        }
        append(item)
    }

    /// - NOTE: replacing all previously added items and add new one
    mutating func set(key: String, value: String?) {
        set(.init(key: key, value: value))
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension QueryItems: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String?)...) {
        self = elements.map(Element.init(key:value:))
    }
}
