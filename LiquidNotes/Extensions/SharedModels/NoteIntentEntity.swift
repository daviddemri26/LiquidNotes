import Foundation
import AppIntents
import SwiftData

struct NoteIntentEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Note")
    static var defaultQuery = NoteIntentEntityQuery()

    let id: UUID
    let title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct NoteIntentEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [NoteIntentEntity.ID]) async throws -> [NoteIntentEntity] {
        let context = ModelContext(AppModelContainer.shared)
        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)
        return notes
            .filter { identifiers.contains($0.id) && !$0.isTrashed }
            .map { NoteIntentEntity(id: $0.id, title: $0.effectiveTitle) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [NoteIntentEntity] {
        let context = ModelContext(AppModelContainer.shared)
        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        return notes
            .filter {
                !$0.isTrashed
                    && ($0.effectiveTitle.localizedCaseInsensitiveContains(string)
                        || $0.effectivePreview.localizedCaseInsensitiveContains(string))
            }
            .prefix(25)
            .map { NoteIntentEntity(id: $0.id, title: $0.effectiveTitle) }
    }

    @MainActor
    func suggestedEntities() async throws -> [NoteIntentEntity] {
        let context = ModelContext(AppModelContainer.shared)
        let descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\Note.updatedAt, order: .reverse)])
        let notes = try context.fetch(descriptor)
        return notes
            .filter { !$0.isTrashed }
            .prefix(10)
            .map { NoteIntentEntity(id: $0.id, title: $0.effectiveTitle) }
    }
}
