import Foundation

struct NoteProjection: Identifiable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let createdAt: Date
    let updatedAt: Date
    let isPinned: Bool
    let isFavorite: Bool
    let isTrashed: Bool
    let deletedAt: Date?
    let reminderDate: Date?
    let tags: [String]
}
