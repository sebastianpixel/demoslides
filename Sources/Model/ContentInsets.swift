import Foundation

public struct ContentInsets: Codable {
    public let contentBackgroundInsets: Insets
    public let contentInsets: Insets

    public static let contentBackgroundInsets = Insets(top: 12, right: 12, bottom: 96, left: 12)
    public static let contentInsets = Insets(top: 36, right: 36, bottom: 36, left: 36)

    enum CodingKeys: String, CodingKey {
        case textBoxSpacing, contentBackgroundInsets, contentInsets
    }

    public init(contentBackgroundInsets: Insets, contentInsets: Insets) {
        self.contentBackgroundInsets = contentBackgroundInsets
        self.contentInsets = contentInsets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contentBackgroundInsets = try container.decode(Insets.self, forKey: .contentBackgroundInsets)
        contentInsets = try container.decode(Insets.self, forKey: .contentInsets)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentBackgroundInsets, forKey: .contentBackgroundInsets)
        try container.encode(contentInsets, forKey: .contentInsets)
    }
}
