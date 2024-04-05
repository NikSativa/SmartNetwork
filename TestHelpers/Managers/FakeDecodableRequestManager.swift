import Foundation
import NQueue
import NRequest
import NSpry

public final class FakeDecodableRequestManager: DecodableRequestManager, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case request = "request(address:with:inQueue:completion:)"
        case requestOpt = "request(opt:address:with:inQueue:completion:)"
        case requestAsync = "request(_:address:with:)"
        case requestAsyncOpt = "request(opt:address:with:)"
        case requestWithThrowing = "requestWithThrowing(_:address:with:)"
        case requestWithThrowingOpt = "requestWithThrowing(opt:address:with:)"
    }

    public init() {}

    public func request<T: Decodable>(_ type: T.Type,
                                      address: Address,
                                      with parameters: Parameters,
                                      inQueue completionQueue: DelayedQueue,
                                      completion: @escaping (Result<T, Error>) -> Void) -> RequestingTask {
        return spryify()
    }

    public func request<T: Decodable>(opt type: T.Type,
                                      address: Address,
                                      with parameters: Parameters,
                                      inQueue completionQueue: DelayedQueue,
                                      completion: @escaping (Result<T?, Error>) -> Void) -> RequestingTask {
        return spryify()
    }

    public func request<T: Decodable>(_ type: T.Type,
                                      address: Address,
                                      with parameters: Parameters) async -> Result<T, Error> {
        return spryify()
    }

    public func request<T: Decodable>(opt type: T.Type,
                                      address: Address,
                                      with parameters: Parameters) async -> Result<T, Error> {
        return spryify()
    }

    public func requestWithThrowing<T: Decodable>(_ type: T.Type,
                                                  address: Address,
                                                  with parameters: Parameters) async throws -> T {
        return spryify()
    }

    public func requestWithThrowing<T: Decodable>(opt type: T.Type,
                                                  address: Address,
                                                  with parameters: Parameters) async throws -> T? {
        return spryify()
    }
}
