import Foundation

public enum RequestError: Error {
    case generic
    case other(Error)
    case connection(URLError)
    case encoding(RequestEncodingError)
    case decoding(RequestDecodingError)
    case statusCode(StatusCode)

    public init(_ error: Swift.Error) {
        switch error {
        case let error as Self:
            self = error
        case let error as URLError:
            self = .connection(error)
        case let error as RequestEncodingError:
            self = .encoding(error)
        case let error as EncodingError:
            self = .encoding(.other(error))
        case let error as RequestDecodingError:
            self = .decoding(error)
        case let error as DecodingError:
            self = .decoding(.other(error))
        case let error as StatusCode:
            self = .statusCode(error)
        default:
            self = .other(error)
        }
    }
}

public extension Error {
    var requestError: RequestError {
        return .init(self)
    }
}

public protocol RequestErrorDescription: Error, CustomDebugStringConvertible, CustomStringConvertible {
    var subname: String { get }
}

public extension RequestErrorDescription {
    private func makeDescription() -> String {
        let className: String = .init(reflecting: Self.self).components(separatedBy: ".").last.unsafelyUnwrapped
        return className + "." + subname
    }

    var description: String {
        return makeDescription()
    }

    var debugDescription: String {
        return makeDescription()
    }
}
