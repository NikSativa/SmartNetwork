import Foundation

struct VoidContent: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Void, Error> {
        if let error = data.error {
            if let error = data.error as? StatusCode, error == .noContent {
                return .success(())
            } else if let error = data.error as? RequestDecodingError {
                switch error {
                case .nilResponse:
                    return .success(())
                case .brokenImage,
                     .brokenResponse,
                     .other:
                    return .failure(error)
                }
            } else {
                return .failure(error)
            }
        } else {
            return .success(())
        }
    }
}
