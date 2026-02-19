import Foundation
import Threading

#if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
import UIKit

/// Provides cross-platform typealiases and image utilities compatible with iOS, macOS, watchOS, tvOS, and visionOS.
///
/// This module abstracts platform-specific image APIs into a unified `PlatformImage` structure, allowing consistent
/// creation and manipulation of images regardless of the underlying Apple platform.
///
/// Represents a platform-agnostic image type (`UIImage` on iOS, `NSImage` on macOS).
public typealias SmartImage = UIImage
#elseif os(macOS)
import Cocoa

/// Provides cross-platform typealiases and image utilities compatible with iOS, macOS, watchOS, tvOS, and visionOS.
///
/// This module abstracts platform-specific image APIs into a unified `PlatformImage` structure, allowing consistent
/// creation and manipulation of images regardless of the underlying Apple platform.
///
/// Represents a platform-agnostic image type (`UIImage` on iOS, `NSImage` on macOS).
public typealias SmartImage = NSImage
#else
#error("unsupported os")
#endif

#if os(iOS) || os(tvOS)
private enum Screen {
    #if swift(>=6.0)
    @MainActor
    static var scale: CGFloat {
        return UIScreen.main.scale
    }
    #else
    static var scale: CGFloat {
        return UIScreen.main.scale
    }
    #endif
}

#elseif os(watchOS)
import WatchKit

private enum Screen {
    #if swift(>=6.0)
    @MainActor
    static var scale: CGFloat {
        return WKInterfaceDevice.current().screenScale
    }
    #else
    static var scale: CGFloat {
        return WKInterfaceDevice.current().screenScale
    }
    #endif
}

#elseif supportsVisionOS
public enum Screen {
    // Returns the display scale factor for rendering images.
    //
    // visionOS doesn't expose a screen scale, so a fallback (e.g., 2.0) can be used in tests or set manually.
    #if swift(>=6.0)
    @MainActor
    public static var scale: CGFloat?
    #else
    public static var scale: CGFloat?
    #endif
}
#endif

/// A platform-independent image wrapper that unifies image handling across Apple platforms.
///
/// Supports initialization from system symbols or raw image data and provides data conversion utilities like PNG or JPEG encoding.
public struct PlatformImage {
    /// Underlying platform-specific image object (`UIImage` or `NSImage`).
    public let sdk: SmartImage

    /// Wraps a platform image into ``PlatformImage``.
    ///
    /// - Parameter image: Platform-specific image instance.
    public init(_ image: SmartImage) {
        self.sdk = image
    }

    #if os(macOS)
    /// Creates image from SF Symbol name.
    ///
    /// - Parameter systemSymbolName: Symbol name used by system symbol catalog.
    public init?(systemSymbolName: String) {
        if let image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil) {
            self.init(image)
        } else {
            return nil
        }
    }

    /// Creates image from raw bytes.
    ///
    /// - Parameter data: Encoded image data.
    public init?(data: Data) {
        if let image = NSImage(data: data) {
            self.init(image)
        } else {
            return nil
        }
    }

    /// Encodes wrapped image to PNG data.
    public func pngData() -> Data? {
        return sdk.pngData()
    }

    #elseif supportsVisionOS
    /// Creates image from SF Symbol name.
    ///
    /// - Parameter systemSymbolName: Symbol name used by system symbol catalog.
    public init?(systemSymbolName: String) {
        if let image = UIImage(systemName: systemSymbolName) {
            self.init(image)
        } else {
            return nil
        }
    }

    /// Creates image from raw bytes.
    ///
    /// - Parameter data: Encoded image data.
    public init?(data: Data) {
        let scale = Queue.isolatedMain.sync { Screen.scale }

        if let scale,
           let image = UIImage(data: data, scale: scale) {
            self.init(image)
        } else if let image = UIImage(data: data) {
            self.init(image)
        } else {
            return nil
        }
    }

    /// Encodes wrapped image to PNG data.
    public func pngData() -> Data? {
        return sdk.pngData()
    }

    public func jpegData(compressionQuality: CGFloat) -> Data? {
        return sdk.jpegData(compressionQuality: CGFloat(compressionQuality))
    }

    #elseif os(iOS) || os(tvOS) || os(watchOS)
    /// Creates image from SF Symbol name.
    ///
    /// - Parameter systemSymbolName: Symbol name used by system symbol catalog.
    public init?(systemSymbolName: String) {
        if let image = UIImage(systemName: systemSymbolName) {
            self.init(image)
        } else {
            return nil
        }
    }

    /// Creates image from raw bytes.
    ///
    /// - Parameter data: Encoded image data.
    public init?(data: Data) {
        let scale = Queue.isolatedMain.sync { Screen.scale }

        if let image = UIImage(data: data, scale: scale) {
            self.init(image)
        } else {
            return nil
        }
    }

    /// Encodes wrapped image to PNG data.
    public func pngData() -> Data? {
        return sdk.pngData()
    }

    public func jpegData(compressionQuality: CGFloat) -> Data? {
        return sdk.jpegData(compressionQuality: CGFloat(compressionQuality))
    }
    #else
    #error("unsupported os")
    #endif
}

#if os(macOS)
private extension NSBitmapImageRep {
    var png: Data? {
        representation(using: .png, properties: [:])
    }
}

private extension Data {
    var bitmap: NSBitmapImageRep? {
        NSBitmapImageRep(data: self)
    }
}

private extension NSImage {
    /// Returns PNG-encoded image data for the `NSImage` if possible.
    func pngData() -> Data? {
        return tiffRepresentation?.bitmap?.png
    }
}
#endif
