#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import Threading

actor FakeStopTheLine: StopTheLine {
    #if swift(>=6.0)
    typealias VerifyHandler = @Sendable (SmartResponse, SmartURL, Parameters, UserInfo) -> StopTheLineAction
    typealias ActionHandler = @Sendable (SmartRequestManager, SmartResponse, SmartURL, Parameters, UserInfo) async throws -> StopTheLineResult
    #else
    typealias VerifyHandler = (SmartResponse, SmartURL, Parameters, UserInfo) -> StopTheLineAction
    typealias ActionHandler = (SmartRequestManager, SmartResponse, SmartURL, Parameters, UserInfo) async throws -> StopTheLineResult
    #endif

    @AtomicValue
    private var verifyCountValue: Int = 0
    @AtomicValue
    private var actionCountValue: Int = 0

    private var verifyHandler: VerifyHandler = { _, _, _, _ in .passOver }
    private var actionHandler: ActionHandler = { _, _, _, _, _ in .useOriginal }

    var verifyCount: Int {
        return $verifyCountValue.syncUnchecked { $0 }
    }

    var actionCount: Int {
        return $actionCountValue.syncUnchecked { $0 }
    }

    func reset() {
        $verifyCountValue.syncUnchecked { $0 = 0 }
        $actionCountValue.syncUnchecked { $0 = 0 }
        verifyHandler = { _, _, _, _ in .passOver }
        actionHandler = { _, _, _, _, _ in .useOriginal }
    }

    func setVerifyResult(_ result: StopTheLineAction) {
        verifyHandler = { _, _, _, _ in result }
    }

    func setVerifyHandler(_ handler: @escaping VerifyHandler) {
        verifyHandler = handler
    }

    func setActionResult(_ result: StopTheLineResult) {
        actionHandler = { _, _, _, _, _ in result }
    }

    func setActionHandler(_ handler: @escaping ActionHandler) {
        actionHandler = handler
    }

    func verify(response: SmartResponse,
                url: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction {
        $verifyCountValue.syncUnchecked { $0 += 1 }
        return verifyHandler(response, url, parameters, userInfo)
    }

    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                url: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult {
        $actionCountValue.syncUnchecked { $0 += 1 }
        return try await actionHandler(manager, response, url, parameters, userInfo)
    }
}
#endif
