import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class PluginProviderTests: XCTestCase {
    func test_providers() {
        let p1 = FakePlugin()
        let p2 = FakePlugin()
        let p3 = FakePlugin()
        let p4 = FakePlugin()

        var subject = PluginProvider.create()
        XCTAssertTrue(subject.plugins().isEmpty)

        subject = PluginProvider.create(plugins: [p1])
        XCTAssertTrue(subject.plugins() == [p1])

        subject = PluginProvider.create(plugins: [p1, p2])
        XCTAssertTrue(subject.plugins() == [p1, p2])

        subject = PluginProvider.create(plugins: [p1, p2],
                                        providers: [
                                            PluginProvider.create(plugins: [p3]),
                                            PluginProvider.create(plugins: [p3, p4])
                                        ])
        XCTAssertTrue(subject.plugins() == [p1, p2, p3, p3, p4])
    }
}

private func ==(lhs: [Plugin], rhs: [Plugin]) -> Bool {
    return lhs.count == rhs.count && !zip(lhs, rhs).contains(where: {
        return ($0 as! FakePlugin) !== ($1 as! FakePlugin)
    })
}
