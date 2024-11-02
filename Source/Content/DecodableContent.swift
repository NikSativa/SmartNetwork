import Foundation

struct DecodableContent<Response: Decodable>: Deserializable {
    let decoder: JSONDecoding?
    let keyPath: [String]

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
                if keyPath.isEmpty {
                    result = try decoder.decode(Response.self, from: data)
                } else {
                    result = try data.decode(Response.self, keyPath: keyPath, decoder: decoder)
                }
                return .success(result)
            } catch {
                return .failure(error)
            }
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
