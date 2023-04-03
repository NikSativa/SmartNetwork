import Foundation

public enum Scheme: Hashable {
    case http
    case https
    case other(String)
}
