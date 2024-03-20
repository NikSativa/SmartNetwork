import Foundation

struct OptionalJSONContent: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Any?, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            do {
                return try .success(JSONSerialization.jsonObject(with: data))
            } catch {
                return .failure(error)
            }
        } else {
            return .success(nil)
        }
    }
}

struct JSONContent: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Any, Error> {
        return OptionalJSONContent.decode(with: data, decoder: decoder()).recoverResponse()
    }
}
