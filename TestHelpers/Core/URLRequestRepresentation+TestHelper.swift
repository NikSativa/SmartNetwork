import Foundation
import NSpry

@testable import NRequest

public extension URLRequestRepresentation where Self: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.sdk == rhs.sdk
    }
}

public extension URLRequestRepresentation {
    var testDescription: String {
        return sdk.testDescription
    }
}

public func ==(lhs: URLRequest, rhs: URLRequestRepresentation) -> Bool {
    return lhs == rhs.sdk
}

public func ==(lhs: URLRequestRepresentation, rhs: URLRequest) -> Bool {
    return lhs.sdk == rhs
}
