import Foundation
import Model
import Yams

public protocol ConfigurationStore {
    static var fileName: String { get }

    static var config: Configuration? { get set }
}

struct ConfigurationStoreImpl: ConfigurationStore {
    static let fileName = "\(Env.current.toolName).yml"

    static var config: Configuration? {
        get { return getCurrent() }
        set { newValue.map(setCurrent) }
    }

    private static var saved: Configuration?

    private static func getCurrent() -> Configuration? {
        if let saved = saved {
            return saved
        }
        do {
            let yamlDecoder = YAMLDecoder()
            let directory = try Env.current.directory.init(path: .current, create: false)
            let configRaw = try directory.file(fileName).read()
            let config = try yamlDecoder.decode(Configuration.self, from: configRaw)
            saved = config
            return config
        } catch {
            if Env.current.debug {
                Env.current.shell.write("\(error)")
            }
            return nil
        }
    }

    private static func setCurrent(_ config: Configuration) {
        do {
            saved = config
            let yamlEncoder = YAMLEncoder()
            yamlEncoder.options = .init(indent: 4, sortKeys: true)
            let directory = try Env.current.directory.init(path: .current, create: false)
            let configEncoded = try yamlEncoder.encode(config)
            try directory.file(fileName) { configEncoded }
        } catch {
            Env.current.shell.write("\(error)")
            exit(EXIT_FAILURE)
        }
    }
}
