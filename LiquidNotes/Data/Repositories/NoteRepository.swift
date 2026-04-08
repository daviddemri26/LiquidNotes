import Foundation
import SwiftData

@MainActor
struct NoteRepository {
    static let trashRetentionDays = 7

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
           !note.isTrashed {
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
        saveIfNeeded(context)
    }

    static func toggleFavorite(_ note: Note, in context: ModelContext) {
        note.isFavorite.toggle()
        saveIfNeeded(context)
    }

    static func moveToTrash(_ note: Note, in context: ModelContext) {
        note.isTrashed = true
        note.isArchived = false
        note.deletedAt = .now
        touch(note, in: context)
    }

    static func restoreFromTrash(_ note: Note, in context: ModelContext) {
        note.isTrashed = false
        note.deletedAt = nil
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

    static func purgeExpiredTrash(in context: ModelContext, referenceDate: Date = .now) {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { $0.isTrashed || $0.isArchived }
        )
        let notes = (try? context.fetch(descriptor)) ?? []
        var hasUpdates = false

        for note in notes {
            if note.isArchived && !note.isTrashed {
                note.isArchived = false
                note.isTrashed = true
                note.deletedAt = note.updatedAt
                hasUpdates = true
            }

            if note.isTrashed && note.deletedAt == nil {
                note.deletedAt = note.updatedAt
                hasUpdates = true
            }
        }

        let expiryInterval = TimeInterval(trashRetentionDays * 24 * 60 * 60)
        for note in notes where note.isTrashed {
            guard let deletedAt = note.deletedAt else { continue }
            if deletedAt.addingTimeInterval(expiryInterval) <= referenceDate {
                context.delete(note)
                hasUpdates = true
            }
        }

        if hasUpdates {
            saveIfNeeded(context)
        }
    }

    static func trashDaysRemaining(for note: Note, referenceDate: Date = .now) -> Int? {
        guard note.isTrashed else { return nil }
        guard let deletedAt = note.deletedAt else { return trashRetentionDays }

        let expiryDate = deletedAt.addingTimeInterval(TimeInterval(trashRetentionDays * 24 * 60 * 60))
        if expiryDate <= referenceDate { return 0 }

        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: referenceDate)
        let end = calendar.startOfDay(for: expiryDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, days)
    }

    private static func saveIfNeeded(_ context: ModelContext?) {
        guard let context else { return }
        if context.hasChanges {
            try? context.save()
        }
    }
}
