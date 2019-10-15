import Foundation

public protocol ErrorMapping: Error {
    static func verify(_ code: Int?, error: Error?) throws
}

public enum Plugins {
    public final class Bearer<T: TokenKey>: TokenPlugin {
        private let authToken: Token<T>

        public init(authToken: Token<T>) {
            self.authToken = authToken

            super.init(type: .header("Authorization"), tokenProvider: { [weak authToken] () -> String? in
                if let token = authToken?.value {
                    return "Bearer " + token
                }
                return nil
            })
        }
    }

    public final class AutoError<E: ErrorMapping>: Plugin {
        public init() { }

        public func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
            try E.verify(code, error: error)
        }
    }
}
