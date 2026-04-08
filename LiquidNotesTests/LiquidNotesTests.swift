import Foundation
import SwiftData
import Testing
@testable import LiquidNotes

struct LiquidNotesTests {
    @MainActor
    @Test
    func noteRepositoryCreateEditDeleteRestore() throws {
        let context = ModelContext(makeInMemoryContainer())

        let note = NoteRepository.create(in: context)
        #expect(note.isDeleted == false)

        NoteRepository.update(note, title: "Title", body: "Body", in: context)
        #expect(note.title == "Title")
        #expect(note.bodyText == "Body")

        NoteRepository.moveToTrash(note, in: context)
        #expect(note.isDeleted == true)

        NoteRepository.restoreFromTrash(note, in: context)
        #expect(note.isDeleted == false)
    }

    @Test
    func queryEngineSortingFilteringSearch() {
        let now = Date.now
        let notes = [
            NoteProjection(id: UUID(), title: "Bravo", body: "Hello", createdAt: now, updatedAt: now, isPinned: false, isFavorite: false, isArchived: false, isDeleted: false, reminderDate: nil, tags: ["work"]),
            NoteProjection(id: UUID(), title: "Alpha", body: "World", createdAt: now.addingTimeInterval(-10), updatedAt: now.addingTimeInterval(-10), isPinned: true, isFavorite: true, isArchived: false, isDeleted: false, reminderDate: nil, tags: ["home"])
        ]

        let scoped = NoteQueryEngine.scoped(notes, scope: .notes)
        let filtered = NoteQueryEngine.filtered(scoped, searchText: "world", requiredTag: nil)
        #expect(filtered.count == 1)

        let sorted = NoteQueryEngine.sorted(scoped, by: .alphabetical)
        #expect(sorted.first?.title == "Alpha")
    }

    @MainActor
    @Test
    func reminderIdentifierStableFormat() {
        let service = ReminderNotificationService()
        let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        #expect(service.identifier(for: id) == "note-reminder-AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")
    }

    @MainActor
    private func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([Note.self, Tag.self, ChecklistItem.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
