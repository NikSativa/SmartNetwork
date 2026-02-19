import Foundation

/// Represents supported image formats for use in HTTP body payloads.
public struct ImageFormat {
    public let contentType: String
    public let data: () throws -> Data

    public init(contentType: String, data: @escaping () throws -> Data) {
        self.contentType = contentType
        self.data = data
    }

    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    /// PNG image payload.
    static func png(_ image: SmartImage) -> Self {
        return .init(contentType: "image/png") {
            try PlatformImage(image).pngData().unwrap(orThrow: RequestEncodingError.cantEncodeImage)
        }
    }
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
    /// JPEG image payload with custom compression quality.
    static func jpeg(_ image: SmartImage, compressionQuality quality: CGFloat) -> Self {
        return .init(contentType: "image/jpeg") {
            try PlatformImage(image).jpegData(compressionQuality: quality).unwrap(orThrow: RequestEncodingError.cantEncodeImage)
        }
    }
    #endif

    func encode() throws -> EncodedBody {
        let data: Data = try data()
        return .init(httpBody: data, [
            "Content-Type": contentType,
            "Content-Length": "\(data.count)"
        ])
    }
}

#if swift(>=6.0)
extension ImageFormat: @unchecked Sendable {}
#endif
