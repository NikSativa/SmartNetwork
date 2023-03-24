import Foundation
import NRequest
import NSpry

extension Plugin {
    func prepare(_ parameters: Parameters,
                 request: FakeURLRequestRepresentation,
                 userInfo: inout Parameters.UserInfo) {
        var request: URLRequestRepresentation = request
        prepare(parameters,
                request: &request,
                userInfo: &userInfo)
    }
}
