import Foundation

struct ImageContent: Deserializable {
    func decode(with data: RequestResult, parameters: Parameters) -> Result<Image, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            if let image = PlatformImage(data: data)?.sdk {
                return .success(image)
            } else {
                return .failure(RequestDecodingError.brokenImage)
            }
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
