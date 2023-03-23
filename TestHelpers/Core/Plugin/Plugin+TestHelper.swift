import Foundation
import NRequest
import NSpry

extension Plugin {
    func prepare(_ parameters: Parameters,
                 request: FakeURLRequestWrapper,
                 userInfo: inout Parameters.UserInfo) {
        var request: URLRequestWrapper = request
        prepare(parameters,
                request: &request,
                userInfo: &userInfo)
    }
}
