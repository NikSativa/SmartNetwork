import Foundation
import NRequest
import NSpry

extension Plugin {
    func prepare(_ parameters: Parameters,
                 request: FakeURLRequestable,
                 userInfo: inout Parameters.UserInfo) {
        var request: URLRequestable = request
        prepare(parameters,
                request: &request,
                userInfo: &userInfo)
    }
}
