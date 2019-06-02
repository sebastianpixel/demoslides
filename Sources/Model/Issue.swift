import Foundation

public final class Issue {
    public let id: Int
    public let key: String
    public let fields: Fields

    public init(key: String, fields: Fields, id: Int) {
        self.key = key
        self.fields = fields
        self.id = id
    }

    public func cleansedDescription(ranges: [DescriptionRange], maxLines: Int) -> String? {
        // strip nasty carriage returns and other weird newline combinations
        guard let descriptionLines = fields.description?.components(separatedBy: .newlines).filter({ !$0.isEmpty }).map({ $0.trimmingCharacters(in: .whitespaces) }) else { return nil }
        let description = descriptionLines.joined(separator: "\n")
        let charsToTrim = CharacterSet(charactersIn: "*:").union(.whitespacesAndNewlines)

        var cleansedDescriptionLines = [String]()

        for range in ranges {
            if let startPattern = description.range(of: range.beginAfterPattern, options: .regularExpression),
                let endPattern = description.range(of: range.endBeforePattern, options: .regularExpression, range: startPattern.upperBound ..< description.endIndex) {
                cleansedDescriptionLines = description[startPattern.upperBound ..< endPattern.lowerBound].components(separatedBy: .newlines)
                break
            }
        }

        // fallback
        if cleansedDescriptionLines.isEmpty {
            cleansedDescriptionLines = descriptionLines
                .filter {
                    let line = $0.trimmingCharacters(in: .whitespaces)
                    return line.range(of: "^(h\\d|Android \\d|iOS \\d|AppService \\d)", options: .regularExpression) == nil
                }
        }

        return cleansedDescriptionLines
            .prefix(maxLines)
            .map { $0.trimmingCharacters(in: charsToTrim) }
            .joined(separator: "\n")
    }
}

extension Issue: Equatable {
    public static func == (lhs: Issue, rhs: Issue) -> Bool {
        return lhs.id == rhs.id
            && lhs.key == rhs.key
            && lhs.fields == rhs.fields
    }
}

public extension Issue {
    struct Response: Codable {
        public let issues: [Issue]
    }

    struct Fields: Codable, Equatable {
        public let summary: String
        public let parent: Issue?
        public let issuetype: IssueType
        public let updated: Date?
        public let description: String?
        public let fixVersions: [FixVersion]
        public let epicLink: String?

        enum CodingKeys: String, CodingKey {
            case summary, parent, issuetype, updated, description, fixVersions, customfield_10522
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            summary = try container.decode(String.self, forKey: .summary)
            issuetype = try container.decode(IssueType.self, forKey: .issuetype)
            fixVersions = try container.decodeIfPresent([FixVersion].self, forKey: .fixVersions) ?? []
            parent = try container.decodeIfPresent(Issue.self, forKey: .parent)
            updated = try container.decodeIfPresent(Date.self, forKey: .updated)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            epicLink = try container.decodeIfPresent(String.self, forKey: .customfield_10522)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(summary, forKey: .summary)
            try container.encode(parent, forKey: .parent)
            try container.encode(issuetype, forKey: .issuetype)
            try container.encode(updated, forKey: .updated)
            try container.encode(description, forKey: .description)
            try container.encode(fixVersions, forKey: .fixVersions)
            try container.encode(epicLink, forKey: .customfield_10522)
        }
    }

    struct FixVersion: Codable, Equatable {
        public let name: String

        public static let emojiMapping = [
            "iOS": "🍏",
            "Android": "🤖"
        ]
    }

    struct IssueType: Codable, Equatable {
        public let name: String

        public var jqlSearchTerm: String {
            return #""\#(name.replacingOccurrences(of: " ", with: "+"))""#
        }

        public static let
            story = IssueType(name: "Story"),
            subTask = IssueType(name: "Sub-task"),
            bug = IssueType(name: "Bug"),
            subBug = IssueType(name: "Bug (sub)"),
            epic = IssueType(name: "Epic")
    }
}

extension Issue: Codable {
    enum CodingKeys: String, CodingKey {
        case key, fields, id
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(String.self, forKey: .key)
        let fields = try container.decode(Fields.self, forKey: .fields)
        let id = try container.decode(String.self, forKey: .id)

        guard let idAsInt = Int(id) else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: [CodingKeys.id], debugDescription: "Could not convert \(id) to Int"))
        }

        self.init(key: key, fields: fields, id: idAsInt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(fields, forKey: .fields)
        try container.encode("\(id)", forKey: .id)
    }
}