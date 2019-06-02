import Environment

public struct PrintUsageDescription: Procedure {
    private let usageDescription: String

    public init(usageDescription: String) {
        self.usageDescription = usageDescription
    }

    public func run() -> Bool {
        return Env.current.shell.runForegroundTask("echo \"\(usageDescription)\" | ${PAGER:-less}")
    }
}
