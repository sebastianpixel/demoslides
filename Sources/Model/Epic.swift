import Foundation

public struct Epic: Codable, Equatable {
    public let fields: Fields

    public init(fields: Fields) {
        self.fields = fields
    }

    public struct Fields: Codable, Equatable {
        public let name: String
        public let summary: String

        enum CodingKeys: String, CodingKey {
            case customfield_10523, summary
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .customfield_10523)
            summary = try container.decode(String.self, forKey: .summary)
        }

        public init(name: String, summary: String) {
            self.name = name
            self.summary = summary
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .customfield_10523)
            try container.encode(summary, forKey: .summary)
        }
    }
}
