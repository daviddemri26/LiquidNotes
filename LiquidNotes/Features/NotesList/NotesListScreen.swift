import SwiftUI
import SwiftData

fileprivate enum NotesSecondaryDestination: String, Identifiable {
    case settings
    case trash

    var id: String { rawValue }
}

struct NotesListScreen: View {
    let scope: NoteListScope
    var showsPrimaryChrome: Bool = true

    @Binding private var searchText: String

    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: [SortDescriptor(\Note.updatedAt, order: .reverse)])
    private var allNotes: [Note]

    @Namespace private var transitionNamespace

    @AppStorage("settings.sortOrder") private var persistedSortOrder = NoteSortOrder.updatedDescending.rawValue
    @State private var selectedTag: String?
    @State private var path: [UUID] = []
    @State private var secondaryDestination: NotesSecondaryDestination?

    init(
        scope: NoteListScope,
        showsPrimaryChrome: Bool = true,
        searchText: Binding<String> = .constant("")
    ) {
        self.scope = scope
        self.showsPrimaryChrome = showsPrimaryChrome
        self._searchText = searchText
    }

    private var sortOrder: NoteSortOrder {
        NoteSortOrder(rawValue: persistedSortOrder) ?? .updatedDescending
    }

    private var availableTags: [String] {
        let all = allNotes
            .filter { !$0.isDeleted }
            .flatMap(\.tagNames)
        return Array(Set(all)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var visibleNotes: [Note] {
        let projections = allNotes.map(\.asProjection)
        let scoped = NoteQueryEngine.scoped(projections, scope: scope)
        let filtered = NoteQueryEngine.filtered(scoped, searchText: searchText, requiredTag: selectedTag)
        let sorted = NoteQueryEngine.sorted(filtered, by: sortOrder)
        return sorted.compactMap { projection in
            allNotes.first(where: { $0.id == projection.id })
        }
    }

    private var canShowEmptyStateAction: Bool {
        showsPrimaryChrome && (scope == .notes || scope == .favorites)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if visibleNotes.isEmpty {
                    EmptyStateView(
                        title: scope == .trash ? "Trash is Empty" : "No Notes",
                        subtitle: scope == .trash ? "Items stay in Trash for 7 days before permanent deletion." : "Tap New Note to capture your first thought.",
                        systemImage: scope == .trash ? "trash" : "square.and.pencil",
                        actionTitle: canShowEmptyStateAction ? "Create Note" : nil,
                        action: canShowEmptyStateAction ? { createAndOpenNote() } : nil
                    )
                } else {
                    notesList
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(scope.title)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        ForEach(NoteSortOrder.allCases) { order in
                            Button(order.title) {
                                persistedSortOrder = order.rawValue
                            }
                        }
                    }

                    if showsPrimaryChrome {
                        Menu("More", systemImage: "ellipsis.circle") {
                            Button("Trash", systemImage: "trash") {
                                secondaryDestination = .trash
                            }
                            Button("Settings", systemImage: "gearshape") {
                                secondaryDestination = .settings
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: UUID.self) { noteID in
                if let note = allNotes.first(where: { $0.id == noteID }) {
                    NoteEditorScreen(note: note)
                        .navigationTransition(.zoom(sourceID: note.id, in: transitionNamespace))
                }
            }
            .sheet(item: $secondaryDestination) { destination in
                SecondaryDestinationSheet(destination: destination)
            }
            .onChange(of: dependencies.router.pendingOpenNoteID) { _, newValue in
                guard let id = newValue else { return }
                if allNotes.contains(where: { $0.id == id }) {
                    path = [id]
                    _ = dependencies.router.consumePendingNoteID()
                }
            }
            .task(id: allNotes.count) {
                NoteRepository.purgeExpiredTrash(in: modelContext)
            }
        }
    }

    private var notesList: some View {
        List {
            if scope == .notes, !availableTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LNTheme.Spacing.small) {
                        FilterChip(title: "All", isSelected: selectedTag == nil) {
                            selectedTag = nil
                        }
                        ForEach(availableTags, id: \.self) { tag in
                            FilterChip(title: "#\(tag)", isSelected: selectedTag == tag) {
                                selectedTag = (selectedTag == tag) ? nil : tag
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if scope == .notes {
                let pinned = visibleNotes.filter(\.isPinned)
                let recent = visibleNotes.filter { !$0.isPinned }

                if !pinned.isEmpty {
                    Section("Pinned") {
                        noteRows(pinned)
                    }
                }

                Section("Recent") {
                    noteRows(recent)
                }
            } else {
                Section {
                    noteRows(visibleNotes)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .animation(.snappy(duration: 0.28), value: visibleNotes.map(\.id))
    }

    @ViewBuilder
    private func noteRows(_ notes: [Note]) -> some View {
        ForEach(notes) { note in
            NavigationLink(value: note.id) {
                VStack(alignment: .leading, spacing: 6) {
                    NoteRowView(note: note)
                        .matchedTransitionSource(id: note.id, in: transitionNamespace)

                    if scope == .trash {
                        Text(retentionText(for: note))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .contextMenu {
                noteContextMenu(note)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: scope != .trash) {
                if scope == .trash {
                    Button("Delete", role: .destructive) {
                        NoteRepository.deletePermanently(note, in: modelContext)
                        dependencies.haptics.impact(.rigid)
                    }
                } else {
                    Button("Trash", role: .destructive) {
                        NoteRepository.moveToTrash(note, in: modelContext)
                        dependencies.haptics.impact(.medium)
                    }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if scope == .trash {
                    Button("Restore") {
                        NoteRepository.restoreFromTrash(note, in: modelContext)
                        dependencies.haptics.selection()
                    }
                    .tint(.green)
                } else {
                    Button(note.isPinned ? "Unpin" : "Pin") {
                        NoteRepository.togglePinned(note, in: modelContext)
                    }
                    .tint(.blue)
                }
            }
        }
    }

    @ViewBuilder
    private func noteContextMenu(_ note: Note) -> some View {
        if scope == .trash {
            Button("Restore", systemImage: "arrow.uturn.backward") {
                NoteRepository.restoreFromTrash(note, in: modelContext)
                dependencies.haptics.selection()
            }
            Button("Delete Permanently", systemImage: "trash", role: .destructive) {
                NoteRepository.deletePermanently(note, in: modelContext)
                dependencies.haptics.impact(.rigid)
            }
        } else {
            Button(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin") {
                NoteRepository.togglePinned(note, in: modelContext)
            }
            Button(note.isFavorite ? "Unfavorite" : "Favorite", systemImage: note.isFavorite ? "star.slash" : "star") {
                NoteRepository.toggleFavorite(note, in: modelContext)
            }
            Button("Move to Trash", systemImage: "trash", role: .destructive) {
                NoteRepository.moveToTrash(note, in: modelContext)
                dependencies.haptics.impact(.medium)
            }
        }
    }

    private func createAndOpenNote() {
        let note = NoteRepository.create(in: modelContext)
        dependencies.haptics.impact(.medium)
        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
            path = [note.id]
        }
    }

    private func retentionText(for note: Note) -> String {
        guard let days = NoteRepository.trashDaysRemaining(for: note) else {
            return "Scheduled for automatic deletion"
        }

        if days <= 0 {
            return "Deleting soon"
        }

        if days == 1 {
            return "Deletes in 1 day"
        }

        return "Deletes in \(days) days"
    }
}

private struct SecondaryDestinationSheet: View {
    let destination: NotesSecondaryDestination
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch destination {
                case .settings:
                    SettingsScreen()
                case .trash:
                    NotesListScreen(scope: .trash, showsPrimaryChrome: false)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, LNTheme.Spacing.small)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : .primary)
        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.14), in: Capsule(style: .continuous))
        .glassEffect(isSelected ? .regular : .clear, in: .capsule)
    }
}
