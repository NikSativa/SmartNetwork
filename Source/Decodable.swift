import Foundation
import UIKit

// sourcery: fakable
public protocol CustomDecodable {
    associatedtype Object

    var result: Result<Object, Error> { get }

    init(with data: ResponseData)
}

struct VoidContent: CustomDecodable {
    var result: Result<Void, Error>

    init(with data: ResponseData) {
        if let error = data.error {
            if let error = data.error as? StatusCode {
                switch error {
                case .noContent:
                    result = .success(())
                case .badRequest,
                     .forbidden,
                     .notFound,
                     .other,
                     .serverError,
                     .timeout,
                     .unauthorized,
                     .upgradeRequired:
                    break
                }
            } else if let error = data.error as? DecodingError {
                switch error {
                case .nilResponse:
                    result = .success(())
                case .brokenResponse:
                    break
                }
            }

            result = .failure(error)
        } else {
            result = .success(())
        }
    }
}

struct DecodableContent<Response: Decodable>: CustomDecodable {
    var result: Result<Response?, Error>

    init(with data: ResponseData) {
        if let error = data.error {
            result = .failure(error)
        } else if let data = data.body {
            do {
                let decoder = (Response.self as? CustomizedDecodable.Type)?.decoder ?? JSONDecoder()
                result = .success(try decoder.decode(Response.self, from: data))
            } catch {
                result = .failure(error)
            }
        } else {
            result = .success(nil)
        }
    }
}

struct ImageContent: CustomDecodable {
    var result: Result<UIImage?, Error>

    init(with data: ResponseData) {
        if let error = data.error {
            result = .failure(error)
        } else if let data = data.body {
            if let image = UIImage(data: data) {
                result = .success(image)
            } else {
                result = .failure(DecodingError.brokenResponse)
            }
        } else {
            result = .success(nil)
        }
    }
}

struct DataContent: CustomDecodable {
    var result: Result<Data?, Error>

    init(with data: ResponseData) {
        if let error = data.error {
            result = .failure(error)
        } else if let data = data.body {
            result = .success(data)
        } else {
            result = .success(nil)
        }
    }
}

struct JSONContent: CustomDecodable {
    var result: Result<Any?, Error>

    init(with data: ResponseData) {
        if let error = data.error {
            result = .failure(error)
        } else if let data = data.body {
            do {
                result = .success(try JSONSerialization.jsonObject(with: data))
            } catch {
                result = .failure(error)
            }
        } else {
            result = .success(nil)
        }
    }
}
