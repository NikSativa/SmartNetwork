import Foundation

/// Body for stubbing a request with a HTTPStupServer.
public enum HTTPStubBody {
    /// Empty body.
    case empty
    /// File body in specified bundle.
    case file(name: String, bundle: Bundle)
    /// File body in specified path.
    case filePath(path: String)
    /// Data body.
    case data(Data)
    /// Encodable body with specified JSONEncoder.
    case encodable(any Encodable, with: JSONEncoder)
    /// Image body
    case image(Body.ImageFormat)

    /// Encodable body.
    public static func encodable(_ obj: any Encodable) -> Self {
        return .encodable(obj, with: .init())
    }

    /// Encodable body.
    public static func encode(_ obj: any Encodable) -> Self {
        return .encodable(obj, with: .init())
    }

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
