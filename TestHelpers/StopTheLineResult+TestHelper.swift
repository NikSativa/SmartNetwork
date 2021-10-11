import Foundation
import NSpry

@testable import NRequest

extension StopTheLineResult: Equatable, SpryEquatable {
    public static func == (lhs: StopTheLineResult, rhs: StopTheLineResult) -> Bool {
        switch (lhs, rhs) {
        case (.passOver(let responseData1), .passOver(let responseData2)):
            return responseData1 == responseData2
        case (.useOriginal, .useOriginal):
            return true
        case (.retry, .retry):
            return true
        case (.retry, _),
            (.useOriginal, _),
            (.passOver, _):
            return false
        }
    }
}
