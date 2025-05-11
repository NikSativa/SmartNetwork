import Foundation

#if swift(>=6.0)
/// A compatibility protocol that conditionally conforms to `Sendable` based on the Swift version.
///
/// In Swift 6.0 and later, `SmartSendable` conforms to `Sendable`, enabling concurrency safety checks.
/// In earlier versions, it acts as a placeholder with no requirements, ensuring backward compatibility.
public protocol SmartSendable: Sendable {}
#else
/// Conforms to the Sendable protocol if Swift version is 6.0 or later.
/// or just empty conformance
public protocol SmartSendable {}
#endif
