import Foundation

public struct QueryItem: Equatable {
    public let key: String
    public let value: String?

    public init(key: String, value: String?) {
        self.key = key
        self.value = value
    }
}

public typealias QueryItems = [QueryItem]

public extension QueryItems {
    /// add new one
    @discardableResult
    mutating func add(_ item: Element) -> Self {
        append(item)
        return self
    }

    /// - NOTE: replacing all previously added items and add new one
    @discardableResult
    mutating func set(_ item: Element) -> Self {
        self = filter {
            return $0.key == item.key
        }
        append(item)
        return self
    }
}

extension QueryItems: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self = elements.map(Element.init(key:value:))
    }
}
