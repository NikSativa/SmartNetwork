import Foundation

public enum Scheme: Equatable {
    case http
    case https
    case other(String)
}
