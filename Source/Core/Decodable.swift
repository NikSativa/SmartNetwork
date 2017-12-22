import Foundation
import UIKit

protocol InternalDecodable {
    associatedtype Response
    var content: Response { get }

    init(with data: Data?) throws
}

struct IgnorableContent: InternalDecodable {
    let content = IgnorableResult()
    init(with data: Data?) throws { }
}

struct DecodableContent<Response: Decodable>: InternalDecodable {
    let content: Response?

    init(with data: Data?) throws {
        if let data = data {
            do {
                let decoder = (Response.self as? CustomizedDecodable.Type)?.decoder ?? JSONDecoder()
                content = try decoder.decode(Response.self, from: data)
            } catch let error {
                throw DecodingError.cantDecode(error)
            }
        } else {
            content = nil
        }
    }
}

struct ImageContent: InternalDecodable {
    let content: UIImage?

    init(with data: Data?) throws {
        if let data = data, let image = UIImage(data: data) {
            content = image
        } else {
            content = nil
        }
    }
}

struct DataContent: InternalDecodable {
    let content: Data?

    public init(with data: Data?) throws {
        content = data
    }
}

struct JSONContent: InternalDecodable {
    let content: Any?

    public init(with data: Data?) throws {
        if let data = data {
            do {
                content = try JSONSerialization.jsonObject(with: data)
            } catch let error {
                throw DecodingError.cantSerialize(error)
            }
        } else {
            content = nil
        }
    }
}
