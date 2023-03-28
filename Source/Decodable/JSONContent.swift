import Foundation

struct JSONContent: CustomDecodable {
    var result: Result<Any?, Error>

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) {
        if let error = data.error {
            self.result = .failure(error)
        } else if let data = data.body {
            do {
                self.result = .success(try JSONSerialization.jsonObject(with: data))
            } catch {
                self.result = .failure(error)
            }
        } else {
            self.result = .success(nil)
        }
    }
}
