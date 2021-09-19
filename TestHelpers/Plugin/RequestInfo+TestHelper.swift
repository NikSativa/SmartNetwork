import Foundation
import Nimble
import NSpry

@testable import NRequest

extension Impl.URLRequestable: Equatable, SpryEquatable, TestOutputStringConvertible {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.original == rhs.original
    }

    public var testDescription: String {
        return original.testDescription
    }
}

public func equal(_ expectedValue: URLRequest?) -> Predicate<URLRequestable> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _?):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (_, nil),
             (nil, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            let matches = expected == actual
            return PredicateResult(bool: matches, message: msg)
        }
    }
}

public func equal(_ expectedValue: URLRequestable?) -> Predicate<URLRequest> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _?):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (_, nil),
             (nil, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            let matches = expected == actual
            return PredicateResult(bool: matches, message: msg)
        }
    }
}

public func ==(lhs: URLRequest, rhs: URLRequestable) -> Bool {
    return lhs == rhs.original
}

public func ==(lhs: URLRequestable, rhs: URLRequest) -> Bool {
    return lhs.original == rhs
}

public func ==(lhs: Expectation<URLRequest>, rhs: URLRequest?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: Expectation<URLRequest>, rhs: URLRequest?) {
    lhs.toNot(equal(rhs))
}

public func ==(lhs: Expectation<URLRequestable>, rhs: URLRequest?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: Expectation<URLRequestable>, rhs: URLRequest?) {
    lhs.toNot(equal(rhs))
}

public func ==(lhs: Expectation<URLRequest>, rhs: URLRequestable?) {
    lhs.to(equal(rhs))
}

public func !=(lhs: Expectation<URLRequest>, rhs: URLRequestable?) {
    lhs.toNot(equal(rhs))
}
