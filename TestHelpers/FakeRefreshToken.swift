import Foundation
import Spry
import NCallback

@testable import NRequest

final
public class FakeRefreshToken<Error: AnyError>: RefreshToken, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case makeRequest = "makeRequest(_:)"
        case shouldRefresh = "shouldRefresh(_:)"
    }

    public func makeRequest<R: RequestFactory>(_ originalFactory: R) -> Callback<Ignorable>
    where Error == R.Error {
        return spryify(arguments: originalFactory)
    }

    public func shouldRefresh(_ error: Error) -> Bool {
        return spryify(arguments: error)
    }
}
