import Foundation

/// Represents the body content used in a stubbed HTTP response.
///
/// `HTTPStubBody` defines various ways to construct response bodies for test purposes, including raw data,
/// file-based content, encoded models, or images. This is used in conjunction with `HTTPStubServer` to simulate
/// different network response scenarios.
public enum HTTPStubBody {
    /// Represents a response with no body.
    case empty
    /// Loads the body content from a file included in a specific bundle.
    case file(name: String, bundle: Bundle)
    /// Loads the body content from a file at a specified filesystem path.
    case filePath(path: String)
    /// Uses the provided `Data` as the body content.
    case data(Data)
    /// Encodes an `Encodable` object using the given `JSONEncoder`.
    case encodable(any Encodable, with: JSONEncoder)
    /// Encodes an image using the specified image format (e.g., PNG, JPEG).
    case image(Body.ImageFormat)

    /// Convenience method to encode an `Encodable` object using a default `JSONEncoder`.
    /// Encodable body.
    public static func encodable(_ obj: any Encodable) -> Self {
        return .encodable(obj, with: .init())
    }

    /// Convenience method to encode an `Encodable` object using a default `JSONEncoder`.
    /// Encodable body.
    public static func encode(_ obj: any Encodable) -> Self {
        return .encodable(obj, with: .init())
    }

    /// Convenience method to encode an `Encodable` object using the specified `JSONEncoder`.
    /// Encodable body.
    public static func encode(_ obj: any Encodable, with encoder: JSONEncoder) -> Self {
        return .encodable(obj, with: encoder)
    }

    #if swift(>=6.0)
    internal nonisolated(unsafe) static var iOSVerificationEnabled: Bool = true
    #else
    internal static var iOSVerificationEnabled: Bool = true
    #endif
}

extension HTTPStubBody {
    var data: Data? {
        switch self {
        case .empty:
            return nil
        case .file(let name, let bundle):
            guard let path = bundle.url(forResource: name, withExtension: nil) else {
                return nil
            }

            let data = try? Data(contentsOf: path)
            return data
        case .filePath(let path):
            if Self.iOSVerificationEnabled, #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
                let path = URL(filePath: path)
                let data = try? Data(contentsOf: path)
                return data
            } else {
                let path = URL(fileURLWithPath: path)
                let data = try? Data(contentsOf: path)
                return data
            }
        case .data(let data):
            return data
        case .encodable(let encodable, let encoder):
            encoder.outputFormatting = encoder.outputFormatting.union([.sortedKeys, .prettyPrinted])
            let data = try? encoder.encode(encodable)
            return data
        case .image(let image):
            let data: Data?
            switch image {
            #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            case .png(let image):
                data = try? PlatformImage(image).pngData().unwrap(orThrow: RequestEncodingError.cantEncodeImage)
            #endif

            #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
            case .jpeg(let image, let quality):
                data = try? PlatformImage(image).jpegData(compressionQuality: quality).unwrap(orThrow: RequestEncodingError.cantEncodeImage)
            #endif
            }
            return data
        }
    }
}

#if swift(>=6.0)
extension HTTPStubBody: @unchecked Sendable {}
#endif
