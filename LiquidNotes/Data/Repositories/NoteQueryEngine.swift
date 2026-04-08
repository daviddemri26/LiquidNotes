import Foundation

enum NoteQueryEngine {
    static func scoped(_ notes: [NoteProjection], scope: NoteListScope) -> [NoteProjection] {
        notes.filter { note in
            switch scope {
            case .notes:
                return !note.isTrashed
            case .favorites:
                return !note.isTrashed && note.isFavorite
            case .trash:
                return note.isTrashed
            }
        }
    }

    static func filtered(
        _ notes: [NoteProjection],
        searchText: String,
        requiredTag: String?
    ) -> [NoteProjection] {
        notes.filter { note in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || note.title.localizedCaseInsensitiveContains(searchText)
                || note.body.localizedCaseInsensitiveContains(searchText)

            let matchesTag = requiredTag == nil || note.tags.contains { $0.caseInsensitiveCompare(requiredTag!) == .orderedSame }
            return matchesSearch && matchesTag
        }
    }

    static func sorted(_ notes: [NoteProjection], scope: NoteListScope) -> [NoteProjection] {
        notes.sorted { lhs, rhs in
            if scope == .notes, lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }
}
