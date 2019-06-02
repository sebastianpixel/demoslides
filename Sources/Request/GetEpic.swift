import Environment
import Foundation
import Model

public struct GetEpic: Request {
    let epicLink: String

    public init(epicLink: String) {
        self.epicLink = epicLink
    }

    public typealias Response = Epic

    public let method = HTTPMethod.get
    public let host = Env.current.configStore.config?.jiraHost
    public var path: String {
        return "/rest/api/2/issue/\(epicLink)"
    }

    public let httpBody = Data?.none
    public let queryItems = [URLQueryItem(name: "fields", value: "summary,customfield_10523")]
}
