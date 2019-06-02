import Foundation

public struct Insets: Codable {
    public let top, right, bottom, left: CGFloat

    public static let zero = Insets(top: 0, right: 0, bottom: 0, left: 0)

    public init(top: Int, right: Int, bottom: Int, left: Int) {
        self.top = CGFloat(top)
        self.right = CGFloat(right)
        self.bottom = CGFloat(bottom)
        self.left = CGFloat(left)
    }

    enum CodingKeys: String, CodingKey {
        case top, right, bottom, left
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        top = CGFloat(try container.decode(Int.self, forKey: .top))
        right = CGFloat(try container.decode(Int.self, forKey: .right))
        bottom = CGFloat(try container.decode(Int.self, forKey: .bottom))
        left = CGFloat(try container.decode(Int.self, forKey: .left))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(top), forKey: .top)
        try container.encode(Int(right), forKey: .right)
        try container.encode(Int(bottom), forKey: .bottom)
        try container.encode(Int(left), forKey: .left)
    }
}
