import Foundation
import Spry
import Nimble

@testable import NRequest

extension RequestInfo: Equatable, SpryEquatable {
    public static func testMake(request: URLRequestable = .testMake(),
                                parameters: Parameters = .testMake()) -> Self {
        return .init(request: request,
                     parameters: parameters)
    }

    public static func testMake(request: URLRequest = .testMake(),
                                parameters: Parameters = .testMake()) -> Self {
        return .init(request: request,
                     parameters: parameters)
    }

    public static func ==(lhs: RequestInfo, rhs: RequestInfo) -> Bool {
        return lhs.parameters == rhs.parameters
            && lhs.request == rhs.request
    }
}

extension URLRequestable: Equatable, SpryEquatable, TestOutputStringConvertible {
    public static func testMake(request: URLRequest = .testMake(),
                                parameters: Parameters = .testMake()) -> Self {
        return .init(request)
    }

    public static func ==(lhs: URLRequestable, rhs: URLRequestable) -> Bool {
        return lhs.original == rhs.original
    }

    public var testDescription: String {
        return original.testDescription
    }
}

public func ==(lhs: URLRequest, rhs: URLRequestable) -> Bool {
    return lhs == rhs.original
}

public func ==(lhs: URLRequestable, rhs: URLRequest) -> Bool {
    return lhs.original == rhs
}

public func equal(_ expectedValue: URLRequest?) -> Predicate<URLRequestable> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _?):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (nil, nil), (_, nil):
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
        case (nil, nil), (_, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            let matches = expected == actual
            return PredicateResult(bool: matches, message: msg)
        }
    }
}
