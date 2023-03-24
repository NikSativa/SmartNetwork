import Foundation
import NSpry

@testable import NRequest

public final class FakeStopTheLine: StopTheLine, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case action = "action(with:originalParameters:response:userInfo:)"
        case verify = "verify(response:for:userInfo:)"
    }
}
