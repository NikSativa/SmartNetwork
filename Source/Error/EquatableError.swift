import Foundation

/// The main idea is to make **Swift.Error** conforms to **Equatable** protocol.
/// As result we can make associated errors automaticaly **Equatable**
///
/// see **RequestError**
public struct EquatableError: Equatable {
    public let error: Error

    public init(_ error: Error) {
        self.error = error
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (lhs.error as NSError) == (rhs.error as NSError)
    }
}
