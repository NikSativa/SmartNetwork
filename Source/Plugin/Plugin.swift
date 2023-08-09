import Foundation

/// namespace
public enum Plugins {}

public protocol Plugin {
    func prepare(_ parameters: Parameters,
                 request: inout URLRequestRepresentation)

    func verify(data: RequestResult,
                userInfo: UserInfo) throws

    func willSend(_ parameters: Parameters,
                  request: URLRequestRepresentation,
                  userInfo: UserInfo)

    func didReceive(_ parameters: Parameters,
                    request: URLRequestRepresentation,
                    data: RequestResult,
                    userInfo: UserInfo)
}
