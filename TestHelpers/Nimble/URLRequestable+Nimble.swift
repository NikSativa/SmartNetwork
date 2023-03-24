import Foundation
import Nimble
import NRequestTestHelpers
import NSpry

@testable import NRequest

extension URLRequestRepresentation where Self: SpryEquatable {}
extension URLRequestRepresentation where Self: TestOutputStringConvertible {}

public func equal(_ expectedValue: URLRequest?) -> Predicate<URLRequestRepresentation> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (_, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            let matches = expected == actual.sdk
            return PredicateResult(bool: matches, message: msg)
        }
    }
}

public func equal(_ expectedValue: URLRequestRepresentation?) -> Predicate<URLRequest> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (_, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            let matches = expected.sdk == actual
            return PredicateResult(bool: matches, message: msg)
        }
    }
}

public func ==(lhs: SyncExpectation<URLRequest>, rhs: URLRequest?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: SyncExpectation<URLRequest>, rhs: URLRequest?) {
    lhs.toNot(equal(rhs))
}

public func ==(lhs: SyncExpectation<URLRequestRepresentation>, rhs: URLRequest?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: SyncExpectation<URLRequestRepresentation>, rhs: URLRequest?) {
    lhs.toNot(equal(rhs))
}

public func ==(lhs: SyncExpectation<URLRequest>, rhs: URLRequestRepresentation?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: SyncExpectation<URLRequest>, rhs: URLRequestRepresentation?) {
    lhs.toNot(equal(rhs))
}
