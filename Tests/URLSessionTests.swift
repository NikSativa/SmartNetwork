import Foundation
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class URLSessionTests: XCTestCase {
    func test_init() {
        let session: Session = URLSession.shared
        let task = session.task(with: .testMake()) { _, _, _ in
            fatalError()
        }
        XCTAssertFalse(task.isRunning)
    }
}
