import Foundation

public struct IgnorableResult: Equatable {
    public init() { }
    public init<T, E: Error>(_ result: Result<T, E>) { }
    public init<T>(_ result: T) { }
}
