import Foundation
import Threading

public struct TypedRequest<T> {
    private let anyRequest: AnyRequest

    typealias DecodingClosure = (_ data: RequestResult, _ parameters: Parameters) -> Result<T, Error>
    private let decoder: DecodingClosure

    internal init<D: Deserializable>(anyRequest: AnyRequest, decoder: D)
        where D.Object == T {
        self.anyRequest = anyRequest
        self.decoder = { data, parameters in
            return decoder.decode(with: data, parameters: parameters)
        }
    }

    internal init<D: Deserializable>(anyRequest: AnyRequest, decoder: D)
        where D.Object == T, T: ExpressibleByNilLiteral {
        self.anyRequest = anyRequest
        self.decoder = { data, parameters in
            return decoder.decode(with: data, parameters: parameters).recoverResult(nil)
        }
    }

    internal init(anyRequest: AnyRequest, decoder: @escaping DecodingClosure) {
        self.anyRequest = anyRequest
        self.decoder = decoder
    }
}

// MARK: - RequestCompletion

extension TypedRequest: RequestCompletion {
    public typealias Object = Result<T, Error>

    public func complete(in completionQueue: Threading.DelayedQueue, completion: @escaping CompletionClosure) -> SmartTasking {
        let parameters = anyRequest.parameters
        return anyRequest.complete(in: completionQueue) { [parameters] result in
            let object = decoder(result, parameters)
            completion(object)
        }
    }
}
