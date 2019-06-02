import AppKit

public extension NSFont {
    static func getFromGoogleIfNeeded(name: String, size: CGFloat) -> NSFont? {
        var font: NSFont? {
            return NSFont(name: name, size: size)
        }

        if let font = font {
            return font
        }

        let error: UnsafeMutablePointer<Unmanaged<CFError>?>? = nil

        guard
            let family = name.split(separator: "-").first?.lowercased(),
            let fontURL = URL(string: "https://github.com/google/fonts/blob/master/ofl/\(family)/\(name).ttf?raw=true") else { return nil }

        print(#"Downloading "\#(name)" from "\#(fontURL.absoluteString)"."#)

        guard
            let fontFile = try? Data(contentsOf: fontURL),
            let fontProvider = CGDataProvider(data: fontFile as CFData),
            let cgFont = CGFont(fontProvider) else { return nil }

        do {
            if let fontFileURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("Fonts")
                .appendingPathComponent("\(name).ttf", isDirectory: false) {
                try fontFile.write(to: fontFileURL)
                print(#"Saved "\#(name)" under "\#(fontFileURL.path)"."#)
            }
        } catch {
            print(error)
        }

        if !CTFontManagerRegisterGraphicsFont(cgFont, error) {
            (error?.pointee?.takeRetainedValue())
                .flatMap(CFErrorCopyDescription)
                .map { print($0) }
        }

        return font
    }
}
