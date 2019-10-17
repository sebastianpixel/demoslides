import Foundation

public struct Configuration: Codable {
    public let jiraHost: String
    public let jiraProject: String
    public let textResources: [String: String]
    public let fixVersionEmojis: [String: String]
    public let descriptionPatterns: [DescriptionRange]
    public let descriptionLinesMax: Int
    public let insets: ContentInsets
    public let fontSettings: FontSettings
    public let issuesPerPage: Int
    public let limitToPrintableArea: Bool
    public var categories: [String: IssueCategory]

    public static func `default`(for project: String, with categories: [String: IssueCategory], jiraHost: String) -> Configuration {
        var categories = categories
        categories[IssueCategory.featureKey] = IssueCategory.featureValue

        return Configuration(
            jiraHost: jiraHost,
            jiraProject: project,
            textResources: [
                "aim": "Ziel:",
                "sprint_goal": "Sprintziel"
            ],
            fixVersionEmojis: Issue.FixVersion.emojiMapping,
            descriptionPatterns: [
                .init(beginAfterPattern: #"User Story\W+"#, endBeforePattern: #"\n"#)
            ],
            descriptionLinesMax: 3,
            insets: .init(
                contentBackgroundInsets: ContentInsets.contentBackgroundInsets,
                contentInsets: ContentInsets.contentInsets
            ),
            fontSettings: .init(
                summary: .summary,
                aim: .aim,
                description: .description,
                category: .category,
                fixVersions: .fixVersions
            ),
            issuesPerPage: 2,
            limitToPrintableArea: true,
            categories: categories
        )
    }

    public init(jiraHost: String,
                jiraProject: String,
                textResources: [String: String],
                fixVersionEmojis: [String: String],
                descriptionPatterns: [DescriptionRange],
                descriptionLinesMax: Int,
                insets: ContentInsets,
                fontSettings: FontSettings,
                issuesPerPage: Int,
                limitToPrintableArea: Bool,
                categories: [String: IssueCategory]) {
        self.jiraHost = jiraHost
        self.jiraProject = jiraProject
        self.textResources = textResources
        self.fixVersionEmojis = fixVersionEmojis
        self.descriptionPatterns = descriptionPatterns
        self.descriptionLinesMax = descriptionLinesMax
        self.insets = insets
        self.fontSettings = fontSettings
        self.issuesPerPage = issuesPerPage
        self.limitToPrintableArea = limitToPrintableArea
        self.categories = categories
    }
}
