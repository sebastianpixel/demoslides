import AppKit
import Foundation
import Utils

public struct FontStyle: Codable {
    public let fontName: String
    public let fontSize, lineSpacing, maximumLineHeight: CGFloat
    public let isUnderlined: Bool
    public let insets: Insets

    public func attributes(color: Color, scale: CGFloat) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing * scale
        paragraphStyle.maximumLineHeight = maximumLineHeight * scale
        paragraphStyle.lineBreakMode = .byWordWrapping
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color.nsColor,
            .paragraphStyle: paragraphStyle,
            .font: NSFont.getFromGoogleIfNeeded(name: fontName, size: fontSize * scale) ?? .systemFont(ofSize: fontSize * scale)
        ]
        if isUnderlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            attributes[.underlineColor] = color.nsColor
        }
        return attributes
    }

    public static let summary = FontStyle(
        fontName: "Oswald-Regular",
        fontSize: 44,
        lineSpacing: 8,
        maximumLineHeight: 64,
        isUnderlined: false,
        insets: .init(top: 4, right: 0, bottom: 0, left: 0)
    )

    public static let aim = FontStyle(
        fontName: "Lato-Bold",
        fontSize: 24,
        lineSpacing: 0,
        maximumLineHeight: 0,
        isUnderlined: true,
        insets: .init(top: 16, right: 0, bottom: 0, left: 0)
    )

    public static let description = FontStyle(
        fontName: "Lato-Regular",
        fontSize: 24,
        lineSpacing: 0,
        maximumLineHeight: 0,
        isUnderlined: false,
        insets: .init(top: 16, right: 24, bottom: 0, left: 24)
    )

    public static let category = FontStyle(
        fontName: "Oswald-Regular",
        fontSize: 32,
        lineSpacing: 2,
        maximumLineHeight: 0,
        isUnderlined: false,
        insets: .zero
    )

    public static let fixVersions = category

    public init(fontName: String, fontSize: Int, lineSpacing: Int, maximumLineHeight: Int, isUnderlined: Bool, insets: Insets) {
        self.fontName = fontName
        self.fontSize = CGFloat(fontSize)
        self.lineSpacing = CGFloat(lineSpacing)
        self.maximumLineHeight = CGFloat(maximumLineHeight)
        self.isUnderlined = isUnderlined
        self.insets = insets
    }

    enum CodingKeys: String, CodingKey {
        case fontName, fontSize, lineSpacing, maximumLineHeight, isUnderlined, insets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontName = try container.decode(String.self, forKey: .fontName)
        fontSize = CGFloat(try container.decode(Int.self, forKey: .fontSize))
        lineSpacing = CGFloat(try container.decode(Int.self, forKey: .lineSpacing))
        maximumLineHeight = CGFloat(try container.decode(Int.self, forKey: .maximumLineHeight))
        isUnderlined = try container.decode(Bool.self, forKey: .isUnderlined)
        insets = try container.decode(Insets.self, forKey: .insets)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fontName, forKey: .fontName)
        try container.encode(Int(fontSize), forKey: .fontSize)
        try container.encode(Int(lineSpacing), forKey: .lineSpacing)
        try container.encode(Int(maximumLineHeight), forKey: .maximumLineHeight)
        try container.encode(isUnderlined, forKey: .isUnderlined)
        try container.encode(insets, forKey: .insets)
    }
}
