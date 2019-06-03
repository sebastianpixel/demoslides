public struct GenericLineSelectorDataSource<Model: Equatable>: LineSelectorDataSource {
    public var items: [(line: String, isSelected: Bool, model: Model)]

    public init(items: [Model], line: (Model) -> (String, Bool)) {
        self.items = items.map {
            let line = line($0)
            return (line.0, line.1, $0)
        }
    }
}
