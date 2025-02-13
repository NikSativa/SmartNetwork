import Foundation

struct VoidContent: Deserializable {
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Void, Error> {
        if let error = data.error {
            if let error = data.error as? StatusCode, error == .noContent {
                return .success(())
            } else {
                return .failure(error)
            }
        } else {
            return .success(())
        }
    }
}
