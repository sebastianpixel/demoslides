import Environment
import Model
import UI
import Yams

public struct CreateAdditionalIssue: Procedure {

    static let fileName = "additionally_created_issues.yml"

    public init() {}

    public func run() -> Bool {

        guard let categories = Env.current.configStore.config?
            .categories
            .keys else {
                assertionFailure("Could not get categories from config.")
                return false
        }

        Env.current.shell.write("""

        Create an issue to add to the PDF in addition to the ones downloaded from JIRA.
        Remove the file with the -r option.

        """)

        guard let summary = Env.current.shell.prompt("Summary") else { return true }
        let description = Env.current.shell.prompt("Description (optional)")

        let categoryOutput = "\(Prompt().prefix)Category:"
        Env.current.shell.write(categoryOutput)

        let items = Array(categories).filter { $0 != Env.current.configStore.config?.textResources["sprint_goal"] }
        let dataSource = GenericLineSelectorDataSource(items: items) { ($0, false) }
        let lineSelector = LineSelector(dataSource: dataSource)
        let selectedCategory = lineSelector?.singleSelection()?.output ?? ""

        LineDrawer(linesToDrawCount: 0).reset(lines: 1)
        Env.current.shell.write("\(categoryOutput) \(selectedCategory)")

        let issue = Issue(
            key: "ADDITIONAL",
            fields: .init(
                summary: summary,
                parent: nil,
                issuetype: .story,
                updated: nil,
                description: description,
                fixVersions: [],
                epicLink: nil
            ),
            id: 0,
            customCategory: selectedCategory
        )

        do {
            let directory = try Env.current.directory.init(path: .current, create: false)
            let file = directory.file(CreateAdditionalIssue.fileName)
            var savedIssues = [Issue]()
            if file.exists {
                let savedIssuesEncoded = try file.read()
                savedIssues = try YAMLDecoder().decode([Issue].self, from: savedIssuesEncoded)
            }
            savedIssues.append(issue)
            let issuesToSave = try YAMLEncoder().encode(savedIssues)
            try file.write(issuesToSave)
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }

        if Env.current.shell.promptDecision("Create another issue?") {
            return run()
        } else if Env.current.shell.promptDecision("Create PDF?") {
            return CreatePDFFromIssues().run()
        } else {
            return true
        }
    }
}
