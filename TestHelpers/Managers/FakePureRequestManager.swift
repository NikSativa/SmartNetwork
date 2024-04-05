import Foundation
import NQueue
import NRequest
import NSpry

public final class FakePureRequestManager: PureRequestManager, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case request = "request(address:with:inQueue:completion:)"
        case requestAsync = "request(address:with:)"
    }

    public init() {}

    public func map<T>(data: NRequest.RequestResult, to type: T.Type, with parameters: NRequest.Parameters) -> Result<T.Object, any Error> where T: NRequest.CustomDecodable {
        return spryify()
    }

    public func request(address: Address,
                        with parameters: Parameters,
                        inQueue completionQueue: DelayedQueue,
                        completion: @escaping ResponseClosure) -> RequestingTask {
        return spryify()
    }

    public func request(address: Address,
                        with parameters: Parameters) async -> RequestResult {
        return spryify()
    }
}
