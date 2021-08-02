import Foundation
import UIKit
import NCallback

public protocol CustomDecodable {
    associatedtype Object
    associatedtype Error: AnyError

    var content: Object { get }

    init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws
}

struct IgnorableContent<Error: AnyError>: CustomDecodable {
    let content = Ignorable()
    init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws { }
}

struct DecodableContent<Response: Decodable, Error: AnyError>: CustomDecodable {
    let content: Response

    init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws {
        if let data = data {
            do {
                let decoder = (Response.self as? CustomizedDecodable.Type)?.decoder ?? JSONDecoder()
                content = try decoder.decode(Response.self, from: data)
            } catch let error {
                throw Error.wrap(error)
            }
        } else {
            throw Error.wrap(DecodingError.nilResponse)
        }
    }
}

struct ImageContent<Error: AnyError>: CustomDecodable {
    let content: UIImage

    init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws {
        if let data = data {
            if let image = UIImage(data: data) {
                content = image
            } else {
                throw Error.wrap(DecodingError.brokenResponse)
            }
        } else {
            throw Error.wrap(DecodingError.nilResponse)
        }
    }
}

struct OptionalImageContent<Error: AnyError>: CustomDecodable {
    let content: UIImage?

    init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws {
        content = data.map { UIImage(data: $0) } ?? nil
    }
}

struct DataContent<Error: AnyError>: CustomDecodable {
    let content: Data

    public init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws {
        if let data = data {
            content = data
        } else {
            throw Error.wrap(DecodingError.nilResponse)
        }
    }
}

struct OptionalDataContent<Error: AnyError>: CustomDecodable {
    let content: Data?

    public init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws {
        content = data
    }
}

struct JSONContent<Error: AnyError>: CustomDecodable {
    let content: Any

    public init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws {
        if let data = data {
            do {
                content = try JSONSerialization.jsonObject(with: data)
            } catch let error {
                throw Error.wrap(error)
            }
        } else {
            throw Error.wrap(DecodingError.nilResponse)
        }
    }
}

struct OptionalJSONContent<Error: AnyError>: CustomDecodable {
    let content: Any?

    public init(with data: Data?, statusCode: Int?, headers: [AnyHashable: Any]) throws {
        content = data.map { try? JSONSerialization.jsonObject(with: $0) } ?? nil
    }
}
