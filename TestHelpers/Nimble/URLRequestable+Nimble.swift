import Foundation
import Nimble
import NRequestTestHelpers
import NSpry

@testable import NRequest

extension URLRequestWrapper where Self: SpryEquatable {}
extension URLRequestWrapper where Self: TestOutputStringConvertible {}

public func equal(_ expectedValue: URLRequest?) -> Predicate<URLRequestWrapper> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (_, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            let matches = expected == actual.original
            return PredicateResult(bool: matches, message: msg)
        }
    }
}

public func equal(_ expectedValue: URLRequestWrapper?) -> Predicate<URLRequest> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (_, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            let matches = expected.original == actual
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

public func ==(lhs: SyncExpectation<URLRequestWrapper>, rhs: URLRequest?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: SyncExpectation<URLRequestWrapper>, rhs: URLRequest?) {
    lhs.toNot(equal(rhs))
}

public func ==(lhs: SyncExpectation<URLRequest>, rhs: URLRequestWrapper?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: SyncExpectation<URLRequest>, rhs: URLRequestWrapper?) {
    lhs.toNot(equal(rhs))
}
