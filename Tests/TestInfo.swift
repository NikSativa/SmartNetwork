import Foundation
import NRequest

struct TestInfo: Codable, Equatable {
    let id: Int

    var data: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}

extension Data {
    func info() -> TestInfo? {
        let encoder = JSONDecoder()
        return try? encoder.decode(TestInfo.self, from: self)
    }
}

struct BrokenTestInfo: Codable, Equatable {
    let id: Int

    func encode(to encoder: Encoder) throws {
        throw RequestEncodingError.invalidJSON
    }
}
