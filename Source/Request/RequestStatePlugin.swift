import Foundation

public protocol RequestStatePlugin {
    func willSend(_ parameters: Parameters,
                  request: URLRequestRepresentation,
                  userInfo: UserInfo)
    func didReceive(_ parameters: Parameters,
                    request: URLRequestRepresentation,
                    data: RequestResult,
                    userInfo: UserInfo)
}
