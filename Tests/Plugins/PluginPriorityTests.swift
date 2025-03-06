#if canImport(SpryMacroAvailable) && swift(>=6.0)
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
            Plugins.Log(logger: { _ in }),
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
        ].prepareForExecution()

        let expected: [Plugin] = [
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.StatusCode(),
            Plugins.Log(logger: { _ in }),
            Plugins.JSONHeaders()
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
            Plugins.Log(logger: { _ in }),
            Plugins.StatusCode(),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.StatusCode(),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.StatusCode(),
            Plugins.LogOS(),
            Plugins.JSONHeaders()
        ].prepareForExecution()

        let expected: [Plugin] = [
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.StatusCode(),
            Plugins.LogOS(),
            Plugins.Log(logger: { _ in }),
            Plugins.JSONHeaders()
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
            Plugins.Log(logger: { _ in }),
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
        ].prepareForExecution()

        let expected: [Plugin] = [
            FakePlugin(id: "fake_0", priority: 0),
            Plugins.AuthBasic(with: {
                return .init(username: "AuthBasic", password: "AuthBasic")
            }),
            FakePlugin(id: "fake_110", priority: 110),
            Plugins.AuthBearer(with: {
                return "AuthBearer"
            }),
            Plugins.StatusCode(),
            FakePlugin(id: "fake_310", priority: 310),
            FakePlugin(id: "fake_1000", priority: 1000),
            Plugins.Log(logger: { _ in })
        ]

        XCTAssertEqual(actual.map(\.id), expected.map(\.id), actual.map(\.id).map { "\($0)" }.joined(separator: ", "))
    }

    func test_additiveArithmetic() {
        XCTAssertEqual(PluginPriority.authBasic + PluginPriority.authBearer, .init(rawValue: 300))
        XCTAssertEqual(PluginPriority.authBasic + PluginPriority.statusCode, .init(rawValue: 400))
        XCTAssertEqual(PluginPriority.authBasic + 3, .init(rawValue: 103))
        XCTAssertEqual(PluginPriority.authBasic + 30, .init(rawValue: 130))

        XCTAssertEqual(PluginPriority.authBearer - PluginPriority.authBasic, .init(rawValue: 100))
        XCTAssertEqual(PluginPriority.statusCode - PluginPriority.authBasic, .init(rawValue: 200))
        XCTAssertEqual(PluginPriority.authBasic - 3, .init(rawValue: 97))
        XCTAssertEqual(PluginPriority.authBasic - 30, .init(rawValue: 70))
    }

    #if swift(>=6.0) && !supportsVisionOS
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func test_overflows() {
        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .max) + 1
        }

        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .min) - 1
        }

        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .max) + 1
        }

        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .min) - 1
        }

        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .max) + PluginPriority(rawValue: 1)
        }

        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .min) - PluginPriority(rawValue: 1)
        }

        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .max) + PluginPriority(rawValue: 1)
        }

        XCTAssertThrowsAssertion {
            PluginPriority(rawValue: .min) - PluginPriority(rawValue: 1)
        }
    }
    #endif
}
#endif
