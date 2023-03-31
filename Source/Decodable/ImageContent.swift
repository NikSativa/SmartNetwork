import Foundation

struct ImageContent: CustomDecodable {
    var result: Result<Image?, Error>

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) {
        if let error = data.error {
            self.result = .failure(error)
        } else if let data = data.body {
            if let image = PlatformImage(data: data)?.sdk {
                self.result = .success(image)
            } else {
                self.result = .failure(RequestDecodingError.brokenImage)
            }
        } else {
            self.result = .success(nil)
        }
    }
}
