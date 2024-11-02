import Foundation

#if swift(>=6.0)
public typealias JSONDecoding = @Sendable () -> JSONDecoder
#else
public typealias JSONDecoding = () -> JSONDecoder
#endif
