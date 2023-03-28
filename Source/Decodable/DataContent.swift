import Foundation

struct DataContent: CustomDecodable {
    var result: Result<Data?, Error>

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) {
        if let error = data.error {
            self.result = .failure(error)
        } else if let data = data.body {
            self.result = .success(data)
        } else {
            self.result = .success(nil)
        }
    }
}
