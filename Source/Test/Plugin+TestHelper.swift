import Foundation
import Spry

import NRequest

extension PluginInfo: Equatable, SpryEquatable {
    public static func ==(lhs: PluginInfo, rhs: PluginInfo) -> Bool {
        return lhs.parameters == rhs.parameters
            && lhs.request == rhs.request
    }

    static func testMake(request: URLRequest = .testMake(),
                         parameters: Parameters = .testMake()) -> PluginInfo {
        return PluginInfo(request: request,
                          parameters: parameters)
    }
}
