import Foundation
import SwiftData

struct WidgetNoteSnapshot: Identifiable, Sendable {
    let id: UUID
    let title: String
    let updatedAt: Date
    let isPinned: Bool
}

@MainActor
struct WidgetSnapshotService {
    func recentNotes(limit: Int = 5, context: ModelContext) -> [WidgetNoteSnapshot] {
        let descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let notes = (try? context.fetch(descriptor)) ?? []

        return notes
            .filter { !$0.isDeleted }
            .prefix(limit)
            .map {
                WidgetNoteSnapshot(
                    id: $0.id,
                    title: $0.effectiveTitle,
                    updatedAt: $0.updatedAt,
                    isPinned: $0.isPinned
                )
            }
    }
}
