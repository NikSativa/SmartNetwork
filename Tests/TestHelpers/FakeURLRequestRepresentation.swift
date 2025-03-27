#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SmartNetwork
import SpryKit

@Spryable
final class FakeURLRequestRepresentation: URLRequestRepresentation {
    init() {}

    @SpryableVar(.get, .set)
    var sdk: URLRequest

    @SpryableVar(.get, .set)
    var allHTTPHeaderFields: [String: String]?

    @SpryableVar(.get, .set)
    var url: URL?

    @SpryableVar(.get, .set)
    var httpBody: Data?

    @SpryableFunc
    func addValue(_ value: String, forHTTPHeaderField field: String)

    @SpryableFunc
    func setValue(_ value: String?, forHTTPHeaderField field: String)

    @SpryableFunc
    func value(forHTTPHeaderField field: String) -> String?
}
#endif
