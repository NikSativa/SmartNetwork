import Foundation
import NSpry

@testable import NRequest

extension Image {
    #if os(macOS)
    static let circle = Image(systemSymbolName: "circle", accessibilityDescription: nil)
    #elseif os(iOS) || os(tvOS) || os(watchOS)
    static let circle = Image(systemName: "circle")!
    #else
    #error("unsupported os")
    #endif
}
