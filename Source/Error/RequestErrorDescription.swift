import Foundation

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
