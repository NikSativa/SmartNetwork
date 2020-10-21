import Foundation
import UIKit
import NCallback

final
public class BaseRequestFactory<Error: AnyError> {
    private let refreshToken: RefreshToken?

    public init(refreshToken: RefreshToken? = nil) {
        self.refreshToken = refreshToken
    }

    public func request<R: Request>(_ response: R.Response.Type, with parameters: Parameters) -> R where Error == R.Error {
        return Impl.Request<R.Response, Error>(parameters)
    }
}

//extension BaseRequestFactory: RequestFactory {
//    public func request<T, R>(_: T.Type, with parameters: Parameters) -> R where T : CustomDecodable, R : Request, Error == R.Error, T.Object == R.Response {
//        fatalError()
//    }
//}
