import Foundation
import Threading

/// A type-safe wrapper around `RequestManager` that produces `TypedRequest` instances with strongly typed output.
///
/// `TypedRequestManager` enables decoding of network responses into specific Swift types using a
/// provided `Deserializable` implementation. It simplifies handling of structured response data
/// by encapsulating decoding logic.
public struct TypedRequestManager<Output> {
    private let base: RequestManager
    private let decoder: TypedRequest<Output>.DecodingClosure

    /// Creates a manager for decoding responses into a non-optional type.
    ///
    /// - Parameters:
    ///   - type: A `Deserializable` type that provides decoding logic for the expected output.
    ///   - base: The underlying request manager that handles request execution.
    internal init<D: Deserializable>(_ type: D, base: RequestManager)
        where Output == D.Object {
        self.base = base
        self.decoder = { data, parameters in
            return type.decode(with: data, parameters: parameters)
        }
    }

    /// Creates a manager for decoding responses into an optional type, recovering from decoding failures.
    ///
    /// - Parameters:
    ///   - type: A `Deserializable` type used to decode the expected optional output.
    ///   - base: The underlying request manager that executes requests.
    internal init<D: Deserializable>(_ type: D, base: RequestManager)
        where Output == D.Object? {
        self.base = base
        self.decoder = { data, parameters in
            let decoded = type.decode(with: data, parameters: parameters)
            return decoded.recoverResult()
        }
    }

    /// Builds a `TypedRequest` that sends a request and decodes the response into the expected output type.
    ///
    /// - Parameters:
    ///   - address: The endpoint to which the request should be sent.
    ///   - parameters: Configuration parameters for the request. Defaults to an empty instance.
    ///   - userInfo: Additional metadata to pass along with the request. Defaults to empty.
    /// - Returns: A `TypedRequest` configured to decode its result into `Output`.
    public func request(address: Address, with parameters: Parameters = .init(), userInfo: UserInfo = .init()) -> TypedRequest<Output> {
        return TypedRequest(anyRequest: .init(pure: base,
                                              address: address,
                                              parameters: parameters,
                                              userInfo: userInfo),
                            decoder: decoder)
    }
}

#if swift(>=6.0)
extension TypedRequestManager: @unchecked Sendable {}
#endif
