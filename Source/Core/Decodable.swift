import Foundation
import UIKit
import NCallback

public protocol CustomDecodable {
    associatedtype Object
    var content: Object { get }

    init(with data: Data?) throws
}

struct IgnorableContent: CustomDecodable {
    let content = Ignorable()
    init(with data: Data?) throws { }
}

struct DecodableContent<Response: Decodable>: CustomDecodable {
    let content: Response?

    init(with data: Data?) throws {
        if let data = data {
            do {
                let decoder = (Response.self as? CustomizedDecodable.Type)?.decoder ?? JSONDecoder()
                content = try decoder.decode(Response.self, from: data)
            } catch let error {
                throw DecodingError(error)
            }
        } else {
            content = nil
        }
    }
}

struct ImageContent: CustomDecodable {
    let content: UIImage?

    init(with data: Data?) throws {
        if let data = data, let image = UIImage(data: data) {
            content = image
        } else {
            content = nil
        }
    }
}

struct DataContent: CustomDecodable {
    let content: Data?

    public init(with data: Data?) throws {
        content = data
    }
}

struct JSONContent: CustomDecodable {
    let content: Any?

    public init(with data: Data?) throws {
        if let data = data {
            do {
                content = try JSONSerialization.jsonObject(with: data)
            } catch let error {
                throw DecodingError(error)
            }
        } else {
            content = nil
        }
    }
}
