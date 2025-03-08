import Foundation

public extension Plugins {
    /// The plugin that adds the `bearer` authentication token to the header.
    static func AuthBearer(overrideExisting: Bool = true, with tokenProvider: @escaping TokenProvider) -> Plugin {
        return TokenPlugin(id: "AuthBearer",
                           priority: .authBearer,
                           type: .header(overrideExisting ? .set("Authorization") : .trySet("Authorization")),
                           tokenProvider: {
                               return await tokenProvider().map { token in
                                   return "Bearer " + token
                               }
                           })
    }
}
