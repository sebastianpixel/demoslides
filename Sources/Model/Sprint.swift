import Foundation

public struct Sprint: Codable {
    public let closed: Bool
    public let viewBoardsUrl: String
    public let name: String
    public let id: Int

    public struct Response: Codable {
        public let sprints: [Sprint]
    }

    public var trainCasedName: String {
        let nonAlphaNumerics = CharacterSet.alphanumerics.inverted
        return name
            .folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: nil)
            .lowercased()
            .components(separatedBy: nonAlphaNumerics)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
