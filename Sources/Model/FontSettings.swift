public struct FontSettings: Codable {
    public let summary, aim, description, category, fixVersions: FontStyle

    public init(summary: FontStyle, aim: FontStyle, description: FontStyle, category: FontStyle, fixVersions: FontStyle) {
        self.summary = summary
        self.aim = aim
        self.description = description
        self.category = category
        self.fixVersions = fixVersions
    }
}
