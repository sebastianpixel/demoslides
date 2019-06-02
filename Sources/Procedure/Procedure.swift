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
            if let epicLink = issue.fields.epicLink, epics[epicLink] == nil {
                epics[epicLink] = GetEpic(epicLink: epicLink).awaitResponseWithDebugPrinting()
            }
        }
    }
}
