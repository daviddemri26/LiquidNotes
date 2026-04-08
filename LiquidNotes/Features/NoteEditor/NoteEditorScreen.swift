import SwiftUI
import SwiftData
import UIKit

struct NoteEditorScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppDependencies.self) private var dependencies

    @Bindable var note: Note

    @FocusState private var focusedField: Field?
    @State private var isReminderSheetPresented = false
    @State private var tagDraft = ""

    private enum Field {
        case title
        case body
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LNTheme.Spacing.medium) {
                TextField("Title", text: $note.title)
                    .font(.title3.weight(.semibold))
                    .focused($focusedField, equals: .title)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .body }

                TextField("Start writing...", text: $note.bodyText, axis: .vertical)
                    .font(.body)
                    .lineSpacing(4)
                    .focused($focusedField, equals: .body)
                    .textInputAutocapitalization(.sentences)
                    .frame(minHeight: 220, alignment: .topLeading)

                if let reminderDate = note.reminderDate {
                    Label {
                        Text("\(reminderDate, style: .date) at \(reminderDate, style: .time)")
                    } icon: {
                        Image(systemName: "bell.badge")
                    }
                    .font(.footnote)
                    .padding(.horizontal, LNTheme.Spacing.small)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule(style: .continuous))
                }

                if !(note.tags ?? []).isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                        ForEach(note.tagNames, id: \.self) { tag in
                            HStack(spacing: 6) {
                                Text("#\(tag)")
                                    .font(.footnote)
                                Button {
                                    NoteRepository.removeTag(named: tag, from: note, in: modelContext)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove tag \(tag)")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: Capsule(style: .continuous))
                        }
                    }
                }
            }
            .padding(LNTheme.Spacing.large)
            .glassEffect(.clear, in: .rect(cornerRadius: LNTheme.Radius.card))
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(note.effectiveTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: shareText)
                Button(note.isFavorite ? "Unfavorite" : "Favorite", systemImage: note.isFavorite ? "star.fill" : "star") {
                    NoteRepository.toggleFavorite(note, in: modelContext)
                }
            }

            ToolbarSpacer(.fixed)

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin") {
                    NoteRepository.togglePinned(note, in: modelContext)
                }
                Button("Move to Trash", systemImage: "trash", role: .destructive) {
                    NoteRepository.moveToTrash(note, in: modelContext)
                    dismiss()
                }
            }

            ToolbarSpacer(.fixed)

            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button("Undo", systemImage: "arrow.uturn.backward") {
                        undoManager?.undo()
                    }
                    Button("Redo", systemImage: "arrow.uturn.forward") {
                        undoManager?.redo()
                    }
                    Spacer()
                    Button("Reminder", systemImage: "bell.badge") {
                        isReminderSheetPresented = true
                    }
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }

            ToolbarItem(placement: .bottomBar) {
                HStack {
                    TextField("Add tag", text: $tagDraft)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 180)
                    Button("Add") {
                        NoteRepository.upsertTag(named: tagDraft, for: note, in: modelContext)
                        tagDraft = ""
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .sheet(isPresented: $isReminderSheetPresented) {
            ReminderEditorSheet(note: note)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            focusedField = note.title.isEmpty ? .title : .body
        }
        .onChange(of: note.title) { _, _ in
            autosave()
        }
        .onChange(of: note.bodyText) { _, _ in
            autosave()
        }
    }

    private var shareText: String {
        if note.title.isEmpty {
            note.bodyText
        } else {
            "\(note.title)\n\n\(note.bodyText)"
        }
    }

    private func autosave() {
        NoteRepository.touch(note, in: modelContext)
    }
}

private struct ReminderEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies

    @Bindable var note: Note
    @State private var selectedDate: Date

    init(note: Note) {
        self.note = note
        _selectedDate = State(initialValue: note.reminderDate ?? Date.now.addingTimeInterval(3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Reminder", selection: $selectedDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])

                Button("Save Reminder") {
                    note.reminderDate = selectedDate
                    NoteRepository.touch(note, in: modelContext)
                    Task {
                        await dependencies.notificationService.scheduleReminder(for: note)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                if note.reminderDate != nil {
                    Button("Clear Reminder", role: .destructive) {
                        note.reminderDate = nil
                        NoteRepository.touch(note, in: modelContext)
                        dependencies.notificationService.cancelReminder(for: note.id)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
