import Environment
import Foundation
import Model

public struct GetSprint: Request {
    let id: Int

    public init(id: Int) {
        self.id = id
    }

    public typealias Response = Sprint

    public let method = HTTPMethod.get
    public let host = Env.current.configStore.config?.jiraHost
    public var path: String {
        return "/rest/agile/1.0/sprint/\(id)"
    }
    public let httpBody = Data?.none
    public let queryItems = [URLQueryItem]()
}
