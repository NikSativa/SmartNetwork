import Foundation
import SmartNetwork
import SpryKit

extension Plugin {
    func prepare(_ parameters: Parameters,
                 request: FakeURLRequestRepresentation) {
        var request: URLRequestRepresentation = request
        prepare(parameters,
                request: &request)
    }
}
