import Foundation
import NQueue
import NSpry

@testable import NRequest

public final class FakeRequestManagering: RequestManagering, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case map = "map(data:to:with:)"
        case request = "request(address:with:inQueue:completion:)"
    }

    public init() {}

    public static func map<T: CustomDecodable>(data: RequestResult,
                                               to type: T.Type,
                                               with parameters: Parameters) -> Result<T.Object, Error> {
        return spryify(arguments: data, type, parameters)
    }

    public var lastCompletion: ResponseClosure?
    public var completion: [Address: ResponseClosure] = [:]
    public func request(address: Address,
                        with parameters: Parameters,
                        inQueue completionQueue: DelayedQueue,
                        completion: @escaping ResponseClosure) -> RequestingTask {
        self.completion[address] = completion
        lastCompletion = completion
        return spryify(arguments: address, parameters, completionQueue, completion)
    }
}
