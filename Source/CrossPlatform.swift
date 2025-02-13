import Foundation
import Threading

#if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
import UIKit

/// A typealias representing an image.
public typealias SmartImage = UIImage
#elseif os(macOS)
import Cocoa

/// A typealias representing an image.
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
    // visionOS doesn't have a screen scale, so we'll just use 2x for Tests.
    // override it on your own risk.
    #if swift(>=6.0)
    @MainActor
    public static var scale: CGFloat?
    #else
    public static var scale: CGFloat?
    #endif
}
#endif

internal struct PlatformImage {
    let sdk: SmartImage

    init(_ image: SmartImage) {
        self.sdk = image
    }

    #if os(macOS)
    init?(data: Data) {
        if let image = NSImage(data: data) {
            self.init(image)
        } else {
            return nil
        }
    }

    func pngData() -> Data? {
        return sdk.pngData()
    }

    #elseif supportsVisionOS
    init?(data: Data) {
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

    func pngData() -> Data? {
        return sdk.pngData()
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        return sdk.jpegData(compressionQuality: CGFloat(compressionQuality))
    }

    #elseif os(iOS) || os(tvOS) || os(watchOS)
    init?(data: Data) {
        let scale = Queue.isolatedMain.sync { Screen.scale }

        if let image = UIImage(data: data, scale: scale) {
            self.init(image)
        } else {
            return nil
        }
    }

    func pngData() -> Data? {
        return sdk.pngData()
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        return sdk.jpegData(compressionQuality: CGFloat(compressionQuality))
    }
    #else
    #error("unsupported os")
    #endif
}

#if os(macOS)
private extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}

private extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}

private extension NSImage {
    func pngData() -> Data? {
        return tiffRepresentation?.bitmap?.png
    }
}
#endif
