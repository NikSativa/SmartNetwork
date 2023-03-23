import Foundation
import NSpry

@testable import NRequest

public extension URLRequestWrapper where Self: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.original == rhs.original
    }
}

public extension URLRequestWrapper {
    var testDescription: String {
        return original.testDescription
    }
}

public func ==(lhs: URLRequest, rhs: URLRequestWrapper) -> Bool {
    return lhs == rhs.original
}

public func ==(lhs: URLRequestWrapper, rhs: URLRequest) -> Bool {
    return lhs.original == rhs
}
