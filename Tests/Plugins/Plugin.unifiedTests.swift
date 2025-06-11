import Combine
import Foundation
import XCTest
@testable import SmartNetwork

private final class TestPlugin: Plugin {
    private let input: PluginPriority.RawValue
    lazy var id: ID = TestPlugin.makeHash(withAdditionalHash: input)
    let priority: PluginPriority

    init(input: PluginPriority.RawValue) {
        self.input = input
        self.priority = .init(rawValue: input)
    }

    func prepare(parameters: SmartNetwork.Parameters, userInfo: SmartNetwork.UserInfo, request: inout SmartNetwork.URLRequestRepresentation, session: SmartNetwork.SmartURLSession) async {
        fatalError("not used in that test")
    }

    func willSend(parameters: SmartNetwork.Parameters, userInfo: SmartNetwork.UserInfo, request: SmartNetwork.URLRequestRepresentation, session: SmartNetwork.SmartURLSession) {
        fatalError("not used in that test")
    }

    func didReceive(parameters: SmartNetwork.Parameters, userInfo: SmartNetwork.UserInfo, request: SmartNetwork.URLRequestRepresentation, data: SmartNetwork.SmartResponse) {
        fatalError("not used in that test")
    }

    func verify(parameters: SmartNetwork.Parameters, userInfo: SmartNetwork.UserInfo, data: SmartNetwork.SmartResponse) throws {
        fatalError("not used in that test")
    }

    func didFinish(parameters: SmartNetwork.Parameters, userInfo: SmartNetwork.UserInfo, data: SmartNetwork.SmartResponse) {
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
