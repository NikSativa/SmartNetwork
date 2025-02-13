import Foundation
import Threading

/// A struct that manages requests and responses for a specific type.
public struct TypedRequestManager<Output> {
    private let base: RequestManager
    private let decoder: TypedRequest<Output>.DecodingClosure

    internal init<D: Deserializable>(_ type: D, base: RequestManager)
        where Output == D.Object {
        self.base = base
        self.decoder = { data, parameters in
            return type.decode(with: data, parameters: parameters)
        }
    }

    internal init<D: Deserializable>(_ type: D, base: RequestManager)
        where Output == D.Object? {
        self.base = base
        self.decoder = { data, parameters in
            let decoded = type.decode(with: data, parameters: parameters)
            return decoded.recoverResult()
        }
    }

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
