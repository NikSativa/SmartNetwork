import Foundation

struct JSONContent: Deserializable {
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Any, Error> {
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
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
