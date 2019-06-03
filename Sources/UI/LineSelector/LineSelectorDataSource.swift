public protocol LineSelectorDataSource {
    associatedtype Model: Equatable
    typealias Item = (line: String, isSelected: Bool, model: Model)

    var items: [Item] { get }
}
