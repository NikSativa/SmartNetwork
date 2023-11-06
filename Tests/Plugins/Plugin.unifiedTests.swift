import Combine
import Foundation
import XCTest

@testable import NRequest

private final class TestPlugin: Plugin {
    private let input: Int
    lazy var id: AnyHashable = TestPlugin.makeHash(withAdditionalHash: input)

    init(input: Int) {
        self.input = input
    }

    func prepare(_ parameters: NRequest.Parameters, request: inout NRequest.URLRequestRepresentation) {
        fatalError("not used in that test")
    }

    func verify(data: NRequest.RequestResult, userInfo: NRequest.UserInfo) throws {
        fatalError("not used in that test")
    }

    func willSend(_ parameters: NRequest.Parameters, request: NRequest.URLRequestRepresentation, userInfo: NRequest.UserInfo) {
        fatalError("not used in that test")
    }

    func didReceive(_ parameters: NRequest.Parameters, request: NRequest.URLRequestRepresentation, data: NRequest.RequestResult, userInfo: NRequest.UserInfo) {
        fatalError("not used in that test")
    }
}

final class PluginUnifiedTests: XCTestCase {
    func test_duplication() {
        let processors: [Plugin] = [
            TestPlugin(input: 0),
            TestPlugin(input: 1),
            TestPlugin(input: 0),
            TestPlugin(input: 2),
            TestPlugin(input: 0),
            TestPlugin(input: 1)
        ]

        XCTAssertEqual(processors.count, 6)

        let noDuplicatesProcessors = processors.unified()
        XCTAssertEqual(noDuplicatesProcessors.count, 3)
    }

    func test_NO_duplication() {
        let processors: [Plugin] = [
            TestPlugin(input: 0),
            TestPlugin(input: 1),
            TestPlugin(input: 2)
        ]

        XCTAssertEqual(processors.count, 3)

        let noDuplicatesProcessors = processors.unified()
        XCTAssertEqual(noDuplicatesProcessors.count, 3)
    }
}
