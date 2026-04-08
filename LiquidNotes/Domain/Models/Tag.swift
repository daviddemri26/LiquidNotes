import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var createdAt: Date

    var notes: [Note]?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        notes: [Note]? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.notes = notes
    }
}
