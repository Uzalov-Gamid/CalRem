import Foundation
import SwiftData

@Model
final class TaskList {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorName: String
    var symbolName: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.list)
    var tasks: [TaskItem]

    init(
        id: UUID = UUID(),
        name: String,
        colorName: String = ListColor.blue.rawValue,
        symbolName: String = "list.bullet",
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false,
        tasks: [TaskItem] = []
    ) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.symbolName = symbolName
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.tasks = tasks
    }

    func touch() {
        updatedAt = .now
    }
}
