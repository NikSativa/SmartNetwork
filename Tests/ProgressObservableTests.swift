import Foundation
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

final class ProgressObservableTests: XCTestCase {
    func test_observe() {
        let subject: Progress = .init(totalUnitCount: 100)
        var events: [Int] = []
        let observer: Any? = subject.observe { progress in
            let percent = Int(progress.fractionCompleted * 100)
            events.append(percent)
        }

        subject.completedUnitCount = 1
        subject.completedUnitCount = 5
        subject.completedUnitCount = 20
        subject.completedUnitCount = 99
        subject.completedUnitCount = 77
        subject.completedUnitCount = 100
        XCTAssertEqual(events, [1, 5, 20, 99, 77, 100])
        XCTAssertNotNil(observer) // retain while testing and remove warning `Immutable value 'observer' was never used`
    }
}
