import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class ParametersTests: XCTestCase {
    func test_observe() {
        let originalPlugin: FakeRequestStatePlugin = .init()
        let plugin1: FakeRequestStatePlugin = .init()
        let subject = Parameters(address: .url(.testMake()),
                                 plugins: [originalPlugin])
        var actual: Parameters = subject + plugin1
        XCTAssertNotEqual(subject, actual)
        XCTAssertTrue(compare(subject.plugins, [originalPlugin]))
        XCTAssertTrue(compare(actual.plugins, [originalPlugin, plugin1]))

        let plugins: [FakeRequestStatePlugin] = .init(repeating: .init(), count: 4)
        actual = subject + plugins
        XCTAssertNotEqual(subject, actual)
        XCTAssertTrue(compare(subject.plugins, [originalPlugin]))
        XCTAssertTrue(compare(actual.plugins, [originalPlugin] + plugins))
    }
}

private func compare(_ lhs: [RequestStatePlugin], _ rhs: [FakeRequestStatePlugin]) -> Bool {
    let zipped = zip(lhs.map { $0 as? FakeRequestStatePlugin }, rhs).map { $0 === $1 }
    return lhs.count == rhs.count && zipped.reduce(true) { $0 && $1 }
}
