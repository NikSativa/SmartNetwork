import Foundation
import Threading

/// A struct that manages requests and responses for a specific type.
public struct TypedRequestManager<Output> {
    private let parent: RequestManager
    private let decoder: TypedRequest<Output>.DecodingClosure

    internal init<D: Deserializable>(_ type: D, parent: RequestManager)
        where Output == D.Object {
        self.parent = parent
        self.decoder = { data, parameters in
            return type.decode(with: data, parameters: parameters)
        }
    }

    internal init<D: Deserializable>(_ type: D, parent: RequestManager)
        where Output == D.Object? {
        self.parent = parent
        self.decoder = { data, parameters in
            let decoded = type.decode(with: data, parameters: parameters)
            return decoded.recoverResult()
        }
    }

    public func request(address: Address, with parameters: Parameters = .init()) -> TypedRequest<Output> {
        return TypedRequest(anyRequest: .init(pure: parent,
                                              address: address,
                                              parameters: parameters),
                            decoder: decoder)
    }
}

#if swift(>=6.0)
extension TypedRequestManager: @unchecked Sendable {}
#endif
