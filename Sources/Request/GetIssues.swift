import Environment
import Foundation
import Model

public struct GetIssues: Request {
    let jiraProject: String
    let exclude: [Issue.IssueType]
    let limit: Int

    public init(jiraProject: String, exclude: [Issue.IssueType], limit: Int) {
        self.jiraProject = jiraProject
        self.exclude = exclude
        self.limit = limit
    }

    public typealias Response = Issue.Response

    public let method = HTTPMethod.get
    public let host = Env.current.configStore.config?.jiraHost
    public let path = "/rest/api/2/search"
    public let httpBody = Data?.none
    public var queryItems: [URLQueryItem] {
        let excludedTypes = exclude.map { $0.jqlSearchTerm }.joined(separator: ",")
        let excludedQuery = excludedTypes.isEmpty ? "" : #"+AND+issuetype+not+in+(\#(excludedTypes))"#
        return [
            .init(name: "jql", value: #"project=\#(jiraProject)\#(excludedQuery)+order+by+updatedDate"#),
            .init(name: "fields", value: "key,summary,issuetype,parent,updated,customfield_10522"),
            .init(name: "maxResults", value: "\(limit)")
        ]
    }
}
