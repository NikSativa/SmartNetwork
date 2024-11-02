import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class PluginPriorityTests: XCTestCase {
    func test_common_plugins() {
        let actual: [Plugin] = [
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.Curl(logger: { _, _ in }),
            Plugins.StatusCode(),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.StatusCode(),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.StatusCode(),
            Plugins.JSONHeaders()
        ].unified().sorted { a, b in
            return a.priority > b.priority
        }

        let expected: [Plugin] = [
            Plugins.JSONHeaders(),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.Curl(logger: { _, _ in }),
            Plugins.StatusCode()
        ]

        XCTAssertEqual(actual.map(\.id), expected.map(\.id))
    }

    #if canImport(os)
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    func test_common_plugins_with_curlOS() {
        let actual: [Plugin] = [
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.Curl(logger: { _, _ in }),
            Plugins.StatusCode(),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.StatusCode(),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.StatusCode(),
            Plugins.CurlOS(),
            Plugins.JSONHeaders()
        ].unified().sorted { a, b in
            return a.priority > b.priority
        }

        let expected: [Plugin] = [
            Plugins.JSONHeaders(),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.Curl(logger: { _, _ in }),
            Plugins.CurlOS(),
            Plugins.StatusCode()
        ]

        XCTAssertEqual(actual.map(\.id), expected.map(\.id))
    }
    #endif

    func test_custom_plugins() {
        let actual: [Plugin] = [
            FakePlugin(id: "fake_1000", priority: 1000),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.Curl(logger: { _, _ in }),
            Plugins.StatusCode(),
            FakePlugin(id: "fake_110", priority: 110),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.StatusCode(),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            FakePlugin(id: "fake_310", priority: 310),
            Plugins.StatusCode(),
            FakePlugin(id: "fake_0", priority: 0)
        ].unified().sorted { a, b in
            return a.priority > b.priority
        }

        let expected: [Plugin] = [
            FakePlugin(id: "fake_1000", priority: 1000),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            FakePlugin(id: "fake_310", priority: 310),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.Curl(logger: { _, _ in }),
            FakePlugin(id: "fake_110", priority: 110),
            Plugins.StatusCode(),
            FakePlugin(id: "fake_0", priority: 0)
        ]

        XCTAssertEqual(actual.map(\.id), expected.map(\.id), actual.map(\.id).map { "\($0)" }.joined(separator: ", "))
    }

    func test_additiveArithmetic() {
        XCTAssertEqual(PluginPriority.authBasic + PluginPriority.authBearer, .init(rawValue: 700))
        XCTAssertEqual(PluginPriority.authBasic + PluginPriority.statusCode, .init(rawValue: 500))
        XCTAssertEqual(PluginPriority.authBasic + 3, .init(rawValue: 403))
        XCTAssertEqual(PluginPriority.authBasic + 30, .init(rawValue: 430))
        XCTAssertEqual(PluginPriority.authBasic + (3 as Int), .init(rawValue: 403))
        XCTAssertEqual(PluginPriority.authBasic + (30 as Int), .init(rawValue: 430))

        XCTAssertEqual(PluginPriority.authBasic - PluginPriority.authBearer, .init(rawValue: 100))
        XCTAssertEqual(PluginPriority.authBasic - PluginPriority.statusCode, .init(rawValue: 300))
        XCTAssertEqual(PluginPriority.authBasic - 3, .init(rawValue: 397))
        XCTAssertEqual(PluginPriority.authBasic - 30, .init(rawValue: 370))

        XCTAssertEqual(PluginPriority.authBasic - (3 as Int), .init(rawValue: 397))
        XCTAssertEqual(PluginPriority.authBasic - (30 as Int), .init(rawValue: 370))
    }
}
