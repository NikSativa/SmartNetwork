import Foundation
import NSpry
import NCallback

@testable import NRequest

final
public class FakeRefreshToken<Error: AnyError>: StopTheLine, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case makeRequest = "makeRequest(_:)"
        case action = "action(for:with:)"
    }

    public func makeRequest<R: RequestFactory>(_ originalFactory: R) -> Callback<Ignorable>
    where Error == R.Error {
        return spryify(arguments: originalFactory)
    }

    public func action(for error: Error, with info: RequestInfo) -> StopTheLineAction {
        return spryify(arguments: error, info)
    }
}
