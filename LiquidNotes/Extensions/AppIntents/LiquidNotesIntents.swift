import Foundation
import AppIntents
import SwiftData

struct CreateNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Note"
    static let description = IntentDescription("Create a new note in LiquidNotes.")
    static let openAppWhenRun = true

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Body")
    var body: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(AppModelContainer.shared)
        let note = Note(title: title, bodyText: body)
        context.insert(note)
        try context.save()
        NotificationRouter.shared.routeToNote(with: note.id)
        return .result(dialog: "Created \(note.effectiveTitle)")
    }
}

struct AppendToNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Append Text to Note"
    static let description = IntentDescription("Append text to an existing note.")
    static let openAppWhenRun = true

    @Parameter(title: "Note")
    var note: NoteIntentEntity

    @Parameter(title: "Text")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(AppModelContainer.shared)
        let targetID = note.id
        let descriptor = FetchDescriptor<Note>(predicate: #Predicate<Note> { $0.id == targetID })
        guard let model = try context.fetch(descriptor).first else {
            return .result(dialog: "Note not found.")
        }

        model.bodyText += model.bodyText.isEmpty ? text : "\n\n\(text)"
        model.updatedAt = .now
        try context.save()
        NotificationRouter.shared.routeToNote(with: model.id)
        return .result(dialog: "Updated \(model.effectiveTitle)")
    }
}

struct OpenNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Note"
    static let description = IntentDescription("Open a specific note in LiquidNotes.")
    static let openAppWhenRun = true

    @Parameter(title: "Note")
    var note: NoteIntentEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationRouter.shared.routeToNote(with: note.id)
        return .result()
    }
}
