import Foundation

#if swift(>=6.0)
/// A typealias representing a closure that returns a `JSONDecoder` instance.
///
/// This allows the decoder creation logic to be injected or customized at runtime, supporting use cases like
/// testability, custom date decoding strategies, or different configurations per request.
///
/// In Swift 6.0 and later, the closure conforms to `Sendable` for concurrency safety.
public typealias JSONDecoding = @Sendable () -> JSONDecoder
#else
/// A typealias representing a closure that returns a `JSONDecoder` instance.
///
/// This allows the decoder creation logic to be injected or customized at runtime, supporting use cases like
/// testability, custom date decoding strategies, or different configurations per request.
///
/// In Swift 6.0 and later, the closure conforms to `Sendable` for concurrency safety.
public typealias JSONDecoding = () -> JSONDecoder
#endif
