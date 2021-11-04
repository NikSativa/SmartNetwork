import Foundation
import UIKit

import Nimble
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

@available(iOS 11, *)
final class FoundationProgress_ProgressObservableSpec: QuickSpec {
    override func spec() {
        describe("Progress") {
            var subject: Foundation.Progress!
            var events: [Int]!
            var observer: AnyObject!

            beforeEach {
                events = []
                subject = Foundation.Progress(totalUnitCount: 100)
                observer = subject.observe { progress in
                    let percent = Int(progress.fractionCompleted * 100)
                    events.append(percent)
                }
            }

            it("should retain observer") {
                expect(events) == []
                expect(observer).toNot(beNil())
            }

            it("should fire observing on every change") {
                subject.completedUnitCount = 1
                subject.completedUnitCount = 5
                subject.completedUnitCount = 20
                subject.completedUnitCount = 99
                subject.completedUnitCount = 100
                expect(events) == [1, 5, 20, 99, 100]
            }
        }
    }
}
