import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var id: UUID
    var text: String
    var isCompleted: Bool
    var orderIndex: Int
    var createdAt: Date

    var note: Note?

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        orderIndex: Int = 0,
        createdAt: Date = .now,
        note: Note? = nil
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.note = note
    }
}
