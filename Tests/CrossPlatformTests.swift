import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

final class CrossPlatformTests: XCTestCase {
    func test_scale() {
        let image = Image.spry.testImage

        #if os(macOS)
        XCTAssertEqual(PlatformImage(data: image.testData().unsafelyUnwrapped)?.pngData(), image.testData())
        XCTAssertNil(PlatformImage(data: Data()))
        #elseif os(visionOS)
        XCTAssertEqual(PlatformImage(image).jpegData(compressionQuality: 1), image.jpegData(compressionQuality: 1))
        XCTAssertEqual(PlatformImage(image).jpegData(compressionQuality: 0.5), image.jpegData(compressionQuality: 0.5))
        XCTAssertNil(PlatformImage(data: Data()))
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        XCTAssertEqual(PlatformImage(image).pngData(), image.pngData())
        XCTAssertEqual(PlatformImage(data: image.pngData().unsafelyUnwrapped)?.sdk.pngData(), image.pngData())
        XCTAssertEqual(PlatformImage(image).jpegData(compressionQuality: 1), image.jpegData(compressionQuality: 1))
        XCTAssertEqual(PlatformImage(image).jpegData(compressionQuality: 0.5), image.jpegData(compressionQuality: 0.5))
        XCTAssertNil(PlatformImage(data: Data()))
        #else
        #error("unsupported os")
        #endif

        XCTAssertEqual(PlatformImage(image).sdk, image)
    }
}
