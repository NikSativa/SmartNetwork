import Foundation
import SmartNetwork
import XCTest

final class URLSessionTests: XCTestCase {
    func test_init() {
        let session: SmartURLSession = URLSession.shared
        let task = session.task(with: .spry.testMake()) { _, _, _ in
            fatalError()
        }
        XCTAssertFalse(task.isRunning)
    }
}
