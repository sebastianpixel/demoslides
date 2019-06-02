public struct IssueCategory: Codable {
    public var epics: [String]
    public let color: Color

    public static let featureKey = "Feature"
    public static let featureValue = IssueCategory(epics: [featureKey], color: .init(red: 43, green: 54, blue: 113, alpha: 255))

    public init(epics: [String], color: Color) {
        self.epics = epics
        self.color = color
    }
}
