import Foundation

struct OptionalDataContent: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Data?, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            return .success(data)
        } else {
            return .success(nil)
        }
    }
}

struct DataContent: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Data, Error> {
        return OptionalDataContent.decode(with: data, decoder: decoder()).recoverResponse()
    }
}
