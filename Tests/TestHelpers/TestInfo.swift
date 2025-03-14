import Foundation
import SmartNetwork

struct TestInfo: Codable, Equatable {
    let id: Int

    var data: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}

struct TestInfo2: Codable, Equatable {
    let id2: Int

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

    func info2() -> TestInfo2? {
        let encoder = JSONDecoder()
        return try? encoder.decode(TestInfo2.self, from: self)
    }
}

struct BrokenTestInfo: Codable, Equatable {
    let id: Int

    func encode(to encoder: Encoder) throws {
        throw RequestEncodingError.invalidJSON
    }
}

#if swift(>=6.0)
extension TestInfo: Sendable {}
extension BrokenTestInfo: Sendable {}
#endif
