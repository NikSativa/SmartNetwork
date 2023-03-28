import Foundation

public enum Logger {
    public typealias LoggingClosure = (_ text: String, _ file: String, _ method: String, _ line: Int) -> Void
    public static var logger: LoggingClosure?

    public static func log(_ text: @autoclosure () -> String,
                           file: String = #file,
                           method: String = #function,
                           line: Int = #line) {
        logger?(text(), file, method, line)
    }
}
