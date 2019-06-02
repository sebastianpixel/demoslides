import Environment
import Foundation
import Model
import Request
import UI

public struct Initialize: Procedure {
    public init() {}

    public func run() -> Bool {
        guard Env.current.configStore.config == nil else {
            Env.current.shell.write("\(Env.current.configStore.fileName) already created. Remove it to create a new one.")
            return false
        }

        guard let jiraHost = Env.current.shell.prompt("JIRA host? (Format: <jira.mycompany.com>)") else { return false }
        Env.current.configStore.config = .default(for: "", with: [:], jiraHost: jiraHost)

        guard let projects = GetProjects().awaitResponseWithDebugPrinting() else { return false }

        let dataSource = GenericLineSelectorDataSource(items: projects, line: \.description)

        guard let project = LineSelector(dataSource: dataSource)?.singleSelection()?.output?.key,
            let issues = GetIssues(
                jiraProject: project,
                exclude: [.subTask, .subBug],
                limit: 100
            ).awaitResponseWithDebugPrinting()?.issues else { return false }

        let epics = getEpics(for: issues).map { $0.value.fields.name }

        let categories = epics.reduce(into: [String: IssueCategory]()) { categories, epic in
            categories[epic] = IssueCategory(epics: [epic], color: .black)
        }

        Env.current.configStore.config = .default(for: project, with: categories, jiraHost: jiraHost)

        Env.current.shell.write("\(Env.current.configStore.fileName) created!")

        return true
    }
}
