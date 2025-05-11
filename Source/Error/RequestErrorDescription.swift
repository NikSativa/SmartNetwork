import Foundation

/// A protocol that enables errors to provide a concise, structured identifier used in descriptions.
///
/// Conforming types must supply a `subname` string, which is used to generate the `description`
/// and `debugDescription` for the error. This is useful for error logging and categorization.
public protocol RequestErrorDescription: Error, CustomDebugStringConvertible, CustomStringConvertible {
    var subname: String { get }
}

public extension RequestErrorDescription {
    /// Constructs a full description using the conforming type's name and its `subname`.
    ///
    /// Example output: `MyErrorType.someCase`
    private func makeDescription() -> String {
        let className: String = .init(reflecting: Self.self).components(separatedBy: ".").last.unsafelyUnwrapped
        return className + "." + subname
    }

    /// A human-readable string representation of the error, combining the type name and subname.
    var description: String {
        return makeDescription()
    }

    /// A debug-friendly string representation of the error, combining the type name and subname.
    var debugDescription: String {
        return makeDescription()
    }
}
