import Environment

public struct RemoveAdditionalIssues: Procedure {

    public init() {}

    public func run() -> Bool {
        do {
            try directory.file(CreateAdditionalIssue.fileName).remove()
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
        return true
    }
}
