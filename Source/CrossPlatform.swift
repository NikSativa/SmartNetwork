import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

public typealias Image = UIImage
#elseif os(macOS)
import Cocoa

public typealias Image = NSImage
#else
#error("unsupported os")
#endif

private struct Screen {
#if os(iOS) || os(tvOS)
    static var scale: CGFloat {
        return UIScreen.main.scale
    }
#elseif os(watchOS)
    static var scale: CGFloat {
        return WKInterfaceDevice.current().screenScale
    }
#elseif os(macOS)
    static var scale: CGFloat {
        return 1
    }
#endif
}

//#if os(macOS)
//typealias Color = NSColor
//#else
//typealias Color = UIColor
//#endif

internal struct PlatformImage {
    let sdk: Image

    init(_ image: Image) {
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
        return sdk.png
    }
#elseif os(iOS) || os(tvOS) || os(watchOS)
    init?(data: Data) {
        if let image = UIImage(data: data, scale: Screen.scale) {
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
extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
extension NSImage {
    var png: Data? { tiffRepresentation?.bitmap?.png }
}
#endif
