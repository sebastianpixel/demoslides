import Environment
import Model
import Request
import UI
import Utils

public protocol Procedure {
    func run() -> Bool
}

extension Procedure {
    func getEpics(for issues: [Issue]) -> [String: Epic] {
        return issues.reduce(into: [String: Epic]()) { epics, issue in
            if let epicLink = issue.fields.epicLink {
                if epics[epicLink] == nil {
                    epics[epicLink] = GetEpic(epicLink: epicLink).awaitResponseWithDebugPrinting()
                }
            } else if epics[IssueCategory.featureKey] == nil {
                epics[IssueCategory.featureKey] = Epic(fields: .init(name: IssueCategory.featureKey, summary: ""))
            }
        }
    }
}
