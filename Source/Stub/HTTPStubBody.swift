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
    /// Encodable body.
    case encodable(any Encodable)
    /// Encodable body with specified JSONEncoder.
    case encodableWithEncoder(any Encodable, JSONEncoder)

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
        case .encodable(let encodable):
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let data = try? encoder.encode(encodable)
            return data
        case .encodableWithEncoder(let encodable, let jSONEncoder):
            let data = try? jSONEncoder.encode(encodable)
            return data
        }
    }
}

#if swift(>=6.0)
extension HTTPStubBody: @unchecked Sendable {}
#endif
