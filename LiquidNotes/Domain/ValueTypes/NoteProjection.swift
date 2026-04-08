import Foundation

struct NoteProjection: Identifiable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let createdAt: Date
    let updatedAt: Date
    let isPinned: Bool
    let isFavorite: Bool
    let isArchived: Bool
    let isDeleted: Bool
    let reminderDate: Date?
    let tags: [String]
}
