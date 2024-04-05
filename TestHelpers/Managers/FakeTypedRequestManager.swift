import Foundation
import NQueue
import NRequest
import NSpry

public final class FakeTypedRequestManager<Response>: TypedRequestManager<Response>, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case request = "request(address:with:inQueue:completion:)"
        case requestAsync = "request(address:with:)"
        case requestWithThrowing = "requestWithThrowing(address:with:)"
    }

    private enum FakeResponse: CustomDecodable {
        typealias Object = Response
        static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Response, any Error> {
            fatalError("Not implemented")
        }
    }

    public convenience init() {
        self.init(FakeResponse.self, parent: FakePureRequestManager())
    }

    override public func request(address: Address,
                                 with parameters: Parameters,
                                 inQueue completionQueue: DelayedQueue,
                                 completion: @escaping (Result<Response, any Error>) -> Void) -> RequestingTask {
        return spryify()
    }

    override public func request(address: Address,
                                 with parameters: Parameters) async -> Result<Response, any Error> {
        return spryify()
    }

    override public func requestWithThrowing(address: Address,
                                             with parameters: Parameters) async throws -> Response {
        return spryify()
    }
}
