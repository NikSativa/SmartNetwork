import Foundation
import NSpry

@testable import NRequest

public extension URLRequestable where Self: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.original == rhs.original
    }
}

public extension URLRequestable {
    var testDescription: String {
        return original.testDescription
    }
}

public func ==(lhs: URLRequest, rhs: URLRequestable) -> Bool {
    return lhs == rhs.original
}

public func ==(lhs: URLRequestable, rhs: URLRequest) -> Bool {
    return lhs.original == rhs
}
