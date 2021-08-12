import Foundation

public struct Logger {
    public typealias Logging = (_ text: String, _ file: String, _ method: String, _ line: Int) -> Void
    public static var logger: Logging?

    public static func log(_ text: @autoclosure () -> String,
                           file: String = #file,
                           method: String = #function,
                           line: Int = #line) {
        logger?(text(), file, method, line)
    }
}
