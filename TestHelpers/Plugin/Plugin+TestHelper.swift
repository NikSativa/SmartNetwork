import Foundation
import NRequest
import NSpry

extension Plugin {
    func prepare(_ parameters: Parameters,
                 request: FakeURLRequestRepresentation) {
        var request: URLRequestRepresentation = request
        prepare(parameters,
                request: &request)
    }
}
