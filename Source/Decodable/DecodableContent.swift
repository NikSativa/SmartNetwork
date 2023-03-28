import Foundation

struct DecodableContent<Response: Decodable>: CustomDecodable {
    var result: Result<Response?, Error>

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) {
        if let error = data.error {
            self.result = .failure(error)
        } else if let data = data.body {
            do {
                let decoder = decoder()
                self.result = .success(try decoder.decode(Response.self, from: data))
            } catch {
                self.result = .failure(error)
            }
        } else {
            self.result = .success(nil)
        }
    }
}
