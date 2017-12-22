import Foundation

public struct IgnorableResult {
    public init() { }
    public init<T, E: Error>(_ result: Result<T, E>) { }
    public init<T>(_ result: T) { }
}
