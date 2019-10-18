import Foundation

public struct Sprint: Codable {
    public let id: Int
    public let `self`: String
    public let state: String
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let originBoardId: Int
    public let goal: String
}
