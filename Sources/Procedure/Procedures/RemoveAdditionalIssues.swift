import Environment

public struct RemoveAdditionalIssues: Procedure {

    public init() {}

    public func run() -> Bool {
        let file = directory.file(CreateAdditionalIssue.fileName)
        guard file.exists else {
            Env.current.shell.write("There are no additionally created issues. Create with -c option.")
            return false
        }
        do {
            try file.remove()
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
        return true
    }
}
