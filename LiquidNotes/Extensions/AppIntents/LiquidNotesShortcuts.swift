import AppIntents

struct LiquidNotesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "Create a note in \(.applicationName)",
                "New note in \(.applicationName)"
            ],
            shortTitle: "Create Note",
            systemImageName: "square.and.pencil"
        )

        AppShortcut(
            intent: OpenNoteIntent(),
            phrases: [
                "Open a note in \(.applicationName)"
            ],
            shortTitle: "Open Note",
            systemImageName: "note.text"
        )
    }
}
