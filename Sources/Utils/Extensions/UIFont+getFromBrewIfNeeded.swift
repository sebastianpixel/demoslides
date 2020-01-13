import AppKit

public extension NSFont {
    static func getFromBrewIfNeeded(name: String, size: CGFloat) -> NSFont? {
        var font: NSFont? {
            return NSFont(name: name, size: size)
        }

        if let font = font {
            return font
        }

        guard let family = name.split(separator: "-").first else { return nil }

        if !command("which -s brew").success {
            print("Brew was not found. Installing it…")
            if let output = command(#"ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)""#).output {
                print(output)
            }
        }

        if command("brew tap").output?.contains("homebrew/cask-fonts") == false {
            print(#"Tapping "homebrew/cask/fonts""#)
            if let output = command("brew tap homebrew/cask-fonts").output {
                print(output)
            }
        }

        let cask = "font-\(family.lowercased())"

        guard command("brew cask list").output?.contains(cask) == false else {
            return font
        }

        print("Font \(family) was not found. Installing it…")

        if let output = command("brew cask install \(cask)").output {
            print(output)
        }

        return font
    }

    @discardableResult
    private static func command(_ command: String) -> (output: String?, success: Bool) {
        let launchPath = "/bin/bash"
        let arguments = ["-c", command]

        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        task.waitUntilExit()
        return (output, task.terminationStatus == EXIT_SUCCESS)
    }
}
