import Foundation

public enum HTTPStubBody {
    case empty
    case file(path: String)
    case data(Data)
    case any(Any)
}
