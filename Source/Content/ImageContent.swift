import Foundation

struct OptionalImageContent: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Image?, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if let image = PlatformImage(data: data)?.sdk {
                return .success(image)
            } else {
                return .failure(RequestDecodingError.brokenImage)
            }
        } else {
            return .success(nil)
        }
    }
}

struct ImageContent: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Image, Error> {
        return OptionalImageContent.decode(with: data, decoder: decoder()).recoverResponse()
    }
}
