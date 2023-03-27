import Foundation

public protocol CustomDecodable {
    associatedtype Object

    var result: Result<Object, Error> { get }

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder)
}

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
                case .brokenResponse,
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

struct ImageContent: CustomDecodable {
    var result: Result<Image?, Error>

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) {
        if let error = data.error {
            self.result = .failure(error)
        } else if let data = data.body {
            if let image = PlatformImage(data: data)?.sdk {
                self.result = .success(image)
            } else {
                self.result = .failure(RequestDecodingError.brokenResponse)
            }
        } else {
            self.result = .success(nil)
        }
    }
}

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
