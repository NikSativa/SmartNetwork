#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import Threading

actor FakePlugin: Plugin {
    nonisolated let id: ID
    nonisolated let priority: PluginPriority

    @AtomicValue
    private var prepareCountValue: Int = 0
    @AtomicValue
    private var verifyCountValue: Int = 0
    @AtomicValue
    private var willSendCountValue: Int = 0
    @AtomicValue
    private var didReceiveCountValue: Int = 0
    @AtomicValue
    private var didFinishCountValue: Int = 0
    @AtomicValue
    private var lastPreparedPluginIDsValue: [String] = []

    init(id: Int, priority: PluginPriority) {
        self.id = "\(id)"
        self.priority = priority
    }

    init(id: ID, priority: PluginPriority) {
        self.id = id
        self.priority = priority
    }

    var prepareCount: Int {
        return $prepareCountValue.syncUnchecked { $0 }
    }

    var verifyCount: Int {
        return $verifyCountValue.syncUnchecked { $0 }
    }

    var willSendCount: Int {
        return $willSendCountValue.syncUnchecked { $0 }
    }

    var didReceiveCount: Int {
        return $didReceiveCountValue.syncUnchecked { $0 }
    }

    var didFinishCount: Int {
        return $didFinishCountValue.syncUnchecked { $0 }
    }

    var lastPreparedPluginIDs: [String] {
        return $lastPreparedPluginIDsValue.syncUnchecked { $0 }
    }

    func resetCalls() {
        $prepareCountValue.syncUnchecked { $0 = 0 }
        $verifyCountValue.syncUnchecked { $0 = 0 }
        $willSendCountValue.syncUnchecked { $0 = 0 }
        $didReceiveCountValue.syncUnchecked { $0 = 0 }
        $didFinishCountValue.syncUnchecked { $0 = 0 }
        $lastPreparedPluginIDsValue.syncUnchecked { $0 = [] }
    }

    func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async throws {
        $prepareCountValue.syncUnchecked { $0 += 1 }
        $lastPreparedPluginIDsValue.syncUnchecked { $0 = parameters.plugins.map(\.id) }
    }

    func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {
        $willSendCountValue.syncUnchecked { $0 += 1 }
    }

    func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, response: SmartResponse) {
        $didReceiveCountValue.syncUnchecked { $0 += 1 }
    }

    func verify(parameters: Parameters, userInfo: UserInfo, response: SmartResponse) async throws {
        $verifyCountValue.syncUnchecked { $0 += 1 }
    }

    func didFinish(parameters: Parameters, userInfo: UserInfo, response: SmartResponse) {
        $didFinishCountValue.syncUnchecked { $0 += 1 }
    }
}

extension FakePlugin: @unchecked Sendable {}
#endif
