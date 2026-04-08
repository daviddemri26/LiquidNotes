import SwiftUI

struct SettingsScreen: View {
    @AppStorage("settings.sortOrder") private var sortOrder = NoteSortOrder.updatedDescending.rawValue
    @AppStorage("settings.createStartsInBody") private var createStartsInBody = false
    @AppStorage("settings.notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("settings.useSystemTint") private var useSystemTint = true
    @AppStorage("settings.futureAI") private var futureAIEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Notes") {
                    Picker("Default Sort", selection: $sortOrder) {
                        ForEach(NoteSortOrder.allCases) { order in
                            Text(order.title).tag(order.rawValue)
                        }
                    }

                    Toggle("Start New Note in Body", isOn: $createStartsInBody)
                }

                Section {
                    Toggle("Reminder Notifications", isOn: $notificationsEnabled)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Notification permissions are requested only when you set a reminder.")
                }

                Section("Appearance") {
                    Toggle("Use System Tint", isOn: $useSystemTint)
                }

                Section("Storage & Sync") {
                    LabeledContent("Sync", value: "iCloud Ready")
                    LabeledContent("Privacy", value: "On-device + iCloud only")
                }

                Section("Advanced") {
                    Toggle("Enable Future Intelligence Features", isOn: $futureAIEnabled)
                    NavigationLink("Trash") {
                        NotesListScreen(scope: .trash, showsPrimaryChrome: false)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
