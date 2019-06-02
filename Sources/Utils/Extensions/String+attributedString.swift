import AppKit

public extension String {
    func attributedStringWithSize(fitting size: CGSize, fontName: String, maxFontSize: CGFloat, scale: CGFloat, attributes: [NSAttributedString.Key: Any]) -> (attributedString: NSAttributedString, size: CGSize) {
        let mutableAttributedString = NSMutableAttributedString(string: self, attributes: attributes)
        var fontSize = maxFontSize * scale
        var height = size.height
        let range = NSRange(location: 0, length: utf16.count)
        var font: NSFont {
            return NSFont.getFromGoogleIfNeeded(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
        }

        repeat {
            mutableAttributedString.removeAttribute(.font, range: range)
            mutableAttributedString.addAttribute(.font, value: font, range: range)

            height = mutableAttributedString.boundingRect(
                with: .init(width: size.width, height: .greatestFiniteMagnitude),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                context: .none
            ).height
            fontSize -= 0.5
        } while height > size.height

        return (mutableAttributedString, .init(width: size.width, height: height))
    }
}
