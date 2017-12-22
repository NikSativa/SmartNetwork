import Foundation

public class Configuration {
    public static var session = URLSession.shared

    public typealias Logging = (_ text: String, _ file: String, _ method: String) -> Void
    public static var log: Logging?

    static func log(_ text: @autoclosure () -> String, file: String = #file, method: String = #function) {
        log.map {
            $0(text(), file, method)
        }
    }
}
