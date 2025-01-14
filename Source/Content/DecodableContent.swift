import Foundation

struct DecodableContent<Response: Decodable>: Deserializable {
    let decoder: JSONDecoding?
    let keyPath: DecodableKeyPath<Response>

    func decode(with data: RequestResult, parameters: Parameters) -> Result<Response, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            do {
                let decoder = decoder?() ?? .init()
                let result: Response
                if keyPath.path.isEmpty {
                    result = try decoder.decode(Response.self, from: data)
                } else {
                    result = try data.decode(Response.self, keyPath: keyPath.path, decoder: decoder)
                }
                return .success(result)
            } catch {
                switch keyPath.fallback {
                case .error(let error):
                    return .failure(error)
                case .value(let value):
                    return .success(value)
                case .none:
                    return .failure(error)
                }
            }
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
