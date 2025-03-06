import Foundation

#if swift(>=6.0)
/// Conforms to the Sendable protocol if Swift version is 6.0 or later.
/// or just empty conformance
public protocol SmartSendable: Sendable {}
#else
/// Conforms to the Sendable protocol if Swift version is 6.0 or later.
/// or just empty conformance
public protocol SmartSendable {}
#endif
