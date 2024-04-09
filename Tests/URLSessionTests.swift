import Foundation
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

final class URLSessionTests: XCTestCase {
    func test_init() {
        let session: Session = URLSession.shared
        let task = session.task(with: .spry.testMake()) { _, _, _ in
            fatalError()
        }
        XCTAssertFalse(task.isRunning)
    }
}
