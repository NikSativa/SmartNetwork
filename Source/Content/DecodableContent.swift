import Foundation

struct OptionalDecodableContent<Response: Decodable>: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Response?, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            do {
                let decoder = decoder()
                return .success(try decoder.decode(Response.self, from: data))
            } catch {
                return .failure(error)
            }
        } else {
            return .success(nil)
        }
    }
}

struct DecodableContent<Response: Decodable>: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Response, Error> {
        return OptionalDecodableContent<Response>.decode(with: data, decoder: decoder()).recoverResponse()
    }
}
