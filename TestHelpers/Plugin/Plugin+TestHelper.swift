import Foundation
import NSpry

import NRequest

extension Plugin {
    func prepare(_ parameters: Parameters,
                 request: FakeURLRequestable) {
        var request: URLRequestable = request
        prepare(parameters,
                request: &request)
    }
}
