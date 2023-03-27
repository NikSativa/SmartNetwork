import Foundation

/// namespace
public enum Plugins {}

public protocol Plugin {
    func prepare(_ parameters: Parameters,
                 request: inout URLRequestRepresentation,
                 userInfo: inout Parameters.UserInfo)

    func verify(data: RequestResult,
                userInfo: Parameters.UserInfo) throws
}
