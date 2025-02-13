import Foundation
import SmartNetwork
import SpryKit

extension Plugin {
    func prepare(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) async {
        var request: URLRequestRepresentation = request
        await prepare(parameters: parameters, userInfo: userInfo, request: &request, session: session)
    }
}
