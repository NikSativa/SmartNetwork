import Foundation

struct DataContent: Deserializable {
    func decode(with data: RequestResult, parameters: Parameters) -> Result<Data, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            return .success(data)
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
