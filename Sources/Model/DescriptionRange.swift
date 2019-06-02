public struct DescriptionRange: Codable {
    public let beginAfterPattern, endBeforePattern: String

    public init(beginAfterPattern: String, endBeforePattern: String) {
        self.beginAfterPattern = beginAfterPattern
        self.endBeforePattern = endBeforePattern
    }
}
