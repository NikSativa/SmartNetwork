import Foundation
import NSpry

@testable import NRequest

extension URLRequestRepresentation where Self: FriendlyStringConvertible {
    public var friendlyDescription: String {
        return sdk.friendlyDescription
    }
}

public func ==(lhs: URLRequest, rhs: URLRequestRepresentation) -> Bool {
    return lhs == rhs.sdk
}

public func ==(lhs: URLRequestRepresentation, rhs: URLRequest) -> Bool {
    return lhs.sdk == rhs
}
