import CommandLineKit
import Environment
import Foundation
import Procedure

let flags = Flags()

let debug = flags.option("d", "debug", description: "Print network requests, responses, received JSON, shell commands with output and errors.")
let help = flags.option("h", "help", description: "Print the usage description")
let initialize = flags.option("i", "init", description: "Select the JIRA project and create a config file in the current working directory without creating a PDF.")
let reset = flags.option("r", "reset-login", description: "Reset the login information in User Defaults (username) and Keychain (password).")

if let failure = flags.parsingFailure() {
    Env.current.shell.write(failure)
    exit(EXIT_FAILURE)
}

private let run = { Core(debug: debug.wasSet, toolName: flags.toolName).run($0) }

if help.wasSet {
    Env.current.shell.write(flags.usageDescription())
} else if initialize.wasSet {
    run(Initialize())
} else if reset.wasSet {
    run(ResetLogin())
} else {
    run(CreatePDFFromIssues())
}
