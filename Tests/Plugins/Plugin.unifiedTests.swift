import Combine
import Foundation
import XCTest

@testable import SmartNetwork

private final class TestPlugin: Plugin {
    private let input: Int
    lazy var id: AnyHashable = TestPlugin.makeHash(withAdditionalHash: input)
    let priority: PluginPriority

    init(input: Int) {
        self.input = input
        self.priority = .init(rawValue: input)
    }

    func prepare(_ parameters: SmartNetwork.Parameters, request: inout SmartNetwork.URLRequestRepresentation) {
        fatalError("not used in that test")
    }

    func verify(data: SmartNetwork.RequestResult, userInfo: SmartNetwork.UserInfo) throws {
        fatalError("not used in that test")
    }

    func didFinish(withData data: RequestResult, userInfo: UserInfo) {
        fatalError("not used in that test")
    }

    func willSend(_ parameters: SmartNetwork.Parameters, request: SmartNetwork.URLRequestRepresentation, userInfo: SmartNetwork.UserInfo) {
        fatalError("not used in that test")
    }

    func didReceive(_ parameters: SmartNetwork.Parameters, request: SmartNetwork.URLRequestRepresentation, data: SmartNetwork.RequestResult, userInfo: SmartNetwork.UserInfo) {
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

#if swift(>=6.0)
extension TestPlugin: @unchecked Sendable {}
#endif
