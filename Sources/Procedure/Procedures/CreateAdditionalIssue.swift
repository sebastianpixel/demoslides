import Environment
import Model
import UI
import Yams

public struct CreateAdditionalIssue: Procedure {

    private enum Error: Swift.Error {
        case interactiveCommandFailed, noSummaryProvided
    }

    static let fileName = "additionally_created_issues.yml"
    static let issueKey = "ADDITIONAL"

    public init() {}

    public func run() -> Bool {

        guard let categories = Env.current.configStore.config?
            .categories
            .keys else {
                assertionFailure("Could not get categories from config.")
                return false
        }

        let summary, description: String
        switch promptToCreateSummaryAndDescription() {
        case let .failure(error):
            Env.current.shell.write(error.localizedDescription)
            return false
        case let .success(success):
            summary = success.summary
            description = success.description
        }

        let categoryOutput = "\(Prompt().prefix)Category:"
        Env.current.shell.write(categoryOutput)

        let items = Array(categories).filter { $0 != Env.current.configStore.config?.textResources["sprint_goal"] }
        let dataSource = GenericLineSelectorDataSource(items: items) { ($0, false) }
        let lineSelector = LineSelector(dataSource: dataSource)
        let selectedCategory = lineSelector?.singleSelection()?.output ?? ""

        LineDrawer(linesToDrawCount: 0).reset(lines: 1)
        Env.current.shell.write("\(categoryOutput) \(selectedCategory)")

        let issue = Issue(
            key: CreateAdditionalIssue.issueKey,
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

    private func promptToCreateSummaryAndDescription() -> Result<(summary: String, description: String), Swift.Error> {
        let tempFile: File
        do {
            tempFile = try Env.current.file.init { template }
        } catch {
            return .failure(error)
        }
        defer { try? tempFile.remove() }

        guard Env.current.shell.runForegroundTask("\(Env.current.shell.editor) \(tempFile.path)") else {
            return .failure(Error.interactiveCommandFailed)
        }

        let arrays = tempFile.parse(markSwitchToSecondBlockLinePrefix: "# Description", markEndLinePrefix: nil)
        let summary = arrays.firstBlock.filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let description = arrays.secondBlock.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        if summary.isEmpty {
            return .failure(Error.noSummaryProvided)
        } else {
            return .success((summary, description))
        }
    }

    private var template: String {
        """
        # Summary

        # Description (optional)

        # Usage
        # Enter a summary and an optional description to create an issue that
        # will be added to the PDF in addition to the ones downloaded from JIRA.
        # All lines starting with # will be ignored.
        # Remove the file with the -r option.
        """
    }
}
