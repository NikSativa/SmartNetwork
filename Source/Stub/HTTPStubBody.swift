import Foundation

public enum HTTPStubBody {
    case empty
    case file(name: String, bundle: Bundle)
    case filePath(path: String)
    case data(Data)
    case encodable(any Encodable)
    case encodableWithEncoder(any Encodable, JSONEncoder)

    internal static var iOSVerificationEnabled: Bool = true
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
            if Self.iOSVerificationEnabled, #available(iOS 16.0, *) {
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
