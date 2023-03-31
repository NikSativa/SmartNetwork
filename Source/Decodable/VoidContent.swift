import Foundation

struct VoidContent: CustomDecodable {
    var result: Result<Void, Error>

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) {
        if let error = data.error {
            if let error = data.error as? StatusCode, error.isSuccess {
                self.result = .success(())
            } else if let error = data.error as? RequestDecodingError {
                switch error {
                case .nilResponse:
                    self.result = .success(())
                case .brokenImage,
                     .brokenResponse,
                     .other:
                    self.result = .failure(error)
                }
            } else {
                self.result = .failure(error)
            }
        } else {
            self.result = .success(())
        }
    }
}
