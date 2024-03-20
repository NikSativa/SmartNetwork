import Foundation
import NSpry

@testable import NRequest

public extension URLRequestRepresentation where Self: SpryFriendlyStringConvertible {
    var friendlyDescription: String {
        return sdk.friendlyDescription
    }
}

public func ==(lhs: URLRequest, rhs: URLRequestRepresentation) -> Bool {
    return lhs == rhs.sdk
}

public func ==(lhs: URLRequestRepresentation, rhs: URLRequest) -> Bool {
    return lhs.sdk == rhs
}
