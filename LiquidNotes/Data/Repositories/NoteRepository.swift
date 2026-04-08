import Foundation
import SwiftData

@MainActor
struct NoteRepository {
    static func create(in context: ModelContext) -> Note {
        let note = Note()
        context.insert(note)
        touch(note)
        return note
    }

    static func touch(_ note: Note, in context: ModelContext? = nil) {
        note.updatedAt = .now
        if note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           note.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !note.isDeleted {
            note.title = ""
        }
        saveIfNeeded(context)
    }

    static func update(
        _ note: Note,
        title: String,
        body: String,
        in context: ModelContext
    ) {
        note.title = title
        note.bodyText = body
        touch(note, in: context)
    }

    static func togglePinned(_ note: Note, in context: ModelContext) {
        note.isPinned.toggle()
        touch(note, in: context)
    }

    static func toggleFavorite(_ note: Note, in context: ModelContext) {
        note.isFavorite.toggle()
        touch(note, in: context)
    }

    static func archive(_ note: Note, in context: ModelContext) {
        note.isArchived = true
        touch(note, in: context)
    }

    static func unarchive(_ note: Note, in context: ModelContext) {
        note.isArchived = false
        touch(note, in: context)
    }

    static func moveToTrash(_ note: Note, in context: ModelContext) {
        note.isDeleted = true
        note.isArchived = false
        touch(note, in: context)
    }

    static func restoreFromTrash(_ note: Note, in context: ModelContext) {
        note.isDeleted = false
        touch(note, in: context)
    }

    static func deletePermanently(_ note: Note, in context: ModelContext) {
        context.delete(note)
        saveIfNeeded(context)
    }

    static func upsertTag(named rawName: String, for note: Note, in context: ModelContext) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == name })
        let existing = (try? context.fetch(descriptor))?.first
        let tag = existing ?? Tag(name: name)
        if existing == nil { context.insert(tag) }

        var tags = note.tags ?? []
        if !tags.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            tags.append(tag)
            note.tags = tags
        }

        touch(note, in: context)
    }

    static func removeTag(named rawName: String, from note: Note, in context: ModelContext) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        note.tags = (note.tags ?? []).filter { $0.name.caseInsensitiveCompare(name) != .orderedSame }
        touch(note, in: context)
    }

    static func allTags(in context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name, order: .forward)])
        let tags = (try? context.fetch(descriptor)) ?? []
        return tags.map(\.name)
    }

    private static func saveIfNeeded(_ context: ModelContext?) {
        guard let context else { return }
        if context.hasChanges {
            try? context.save()
        }
    }
}
