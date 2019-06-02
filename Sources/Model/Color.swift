import AppKit

public struct Color: Codable, Equatable {
    public let red, green, blue, alpha: CGFloat

    public var cgColor: CGColor {
        return CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public var nsColor: NSColor {
        return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }

    public static let black = Color(red: 0, green: 0, blue: 0, alpha: 255)
    public static let white = Color(red: 255, green: 255, blue: 255, alpha: 255)

    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    public init(red: Int, green: Int, blue: Int, alpha: Int) {
        self.red = Color.component(red)
        self.green = Color.component(green)
        self.blue = Color.component(blue)
        self.alpha = Color.component(alpha)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        red = Color.component(try container.decode(Int.self, forKey: .red))
        green = Color.component(try container.decode(Int.self, forKey: .green))
        blue = Color.component(try container.decode(Int.self, forKey: .blue))
        alpha = Color.component(try container.decode(Int.self, forKey: .alpha))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Color.component(red), forKey: .red)
        try container.encode(Color.component(green), forKey: .green)
        try container.encode(Color.component(blue), forKey: .blue)
        try container.encode(Color.component(alpha), forKey: .alpha)
    }

    private static func component(_ value: Int) -> CGFloat {
        return CGFloat(min(max(0, value), 255)) / 255
    }

    private static func component(_ value: CGFloat) -> Int {
        return Int(value * 255)
    }
}
