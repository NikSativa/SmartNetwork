import Foundation

public typealias ProgressHandler = (Progress) -> Void

public struct Progress {
    public let fractionCompleted: Double
}
