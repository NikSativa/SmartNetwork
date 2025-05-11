import Foundation
import Threading

/// A wrapper around `AnyRequest` that produces strongly typed results through deserialization.
///
/// `TypedRequest` supports both synchronous and asynchronous decoding using a provided `Deserializable` implementation
/// or a custom decoding closure. It is the core type-safe interface for handling structured network responses.
public struct TypedRequest<T> {
    private let anyRequest: AnyRequest

    /// A closure that transforms a `SmartResponse` into a `Result<T, Error>` using the request parameters.
    typealias DecodingClosure = (_ data: SmartResponse, _ parameters: Parameters) -> Result<T, Error>
    private let decoder: DecodingClosure

    /// Initializes a typed request using a generic deserializer for a concrete result type.
    ///
    /// - Parameters:
    ///   - anyRequest: The underlying untyped request.
    ///   - decoder: A `Deserializable` instance for decoding to type `T`.
    internal init<D: Deserializable>(anyRequest: AnyRequest, decoder: D)
        where D.Object == T {
        self.anyRequest = anyRequest
        self.decoder = { data, parameters in
            return decoder.decode(with: data, parameters: parameters)
        }
    }

    /// Initializes a typed request using a deserializer for an optional result type.
    ///
    /// If decoding fails, this initializer recovers by returning `nil` instead of an error.
    ///
    /// - Parameters:
    ///   - anyRequest: The underlying untyped request.
    ///   - decoder: A `Deserializable` instance for decoding to type `T?`.
    internal init<D: Deserializable>(anyRequest: AnyRequest, decoder: D)
        where D.Object == T, T: ExpressibleByNilLiteral {
        self.anyRequest = anyRequest
        self.decoder = { data, parameters in
            return decoder.decode(with: data, parameters: parameters).recoverResult(nil)
        }
    }

    /// Initializes a typed request with a custom decoding closure.
    ///
    /// - Parameters:
    ///   - anyRequest: The underlying untyped request.
    ///   - decoder: A closure that performs custom decoding.
    internal init(anyRequest: AnyRequest, decoder: @escaping DecodingClosure) {
        self.anyRequest = anyRequest
        self.decoder = decoder
    }
}

// MARK: - RequestCompletion

extension TypedRequest: RequestCompletion {
    public typealias Object = Result<T, Error>

    /// Executes the request asynchronously and returns a decoded result.
    ///
    /// - Returns: A `Result` containing the typed object or an error.
    @discardableResult
    public func async() async -> Object {
        let result = await anyRequest.async()
        let parameters = anyRequest.parameters
        let object = decoder(result, parameters)
        return object
    }

    /// Executes the request using a completion handler and returns a running task.
    ///
    /// - Parameters:
    ///   - completionQueue: The queue to invoke the completion handler on.
    ///   - completion: A closure called with the decoded result.
    /// - Returns: A cancellable task conforming to `SmartTasking`.
    public func complete(in completionQueue: Threading.DelayedQueue, completion: @escaping CompletionClosure) -> SmartTasking {
        let parameters = anyRequest.parameters
        return anyRequest.complete(in: completionQueue) { [parameters] result in
            let object = decoder(result, parameters)
            completion(object)
        }
    }
}
