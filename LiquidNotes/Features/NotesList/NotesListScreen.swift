import SwiftUI
import SwiftData

fileprivate enum NotesSecondaryDestination: String, Identifiable {
    case settings
    case archive
    case trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .settings: return "Settings"
        case .archive: return "Archive"
        case .trash: return "Trash"
        }
    }
}

struct NotesListScreen: View {
    let scope: NoteListScope
    var showsPrimaryChrome: Bool = true

    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: [SortDescriptor(\Note.updatedAt, order: .reverse)])
    private var allNotes: [Note]

    @Namespace private var transitionNamespace

    @AppStorage("settings.sortOrder") private var persistedSortOrder = NoteSortOrder.updatedDescending.rawValue
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var path: [UUID] = []
    @State private var secondaryDestination: NotesSecondaryDestination?

    private var sortOrder: NoteSortOrder {
        NoteSortOrder(rawValue: persistedSortOrder) ?? .updatedDescending
    }

    private var availableTags: [String] {
        let all = allNotes.flatMap(\.tagNames)
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

    private var canShowPrimaryNewNoteButton: Bool {
        showsPrimaryChrome && (scope == .notes || scope == .favorites)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if visibleNotes.isEmpty {
                    EmptyStateView(
                        title: scope == .trash ? "Trash is Empty" : "No Notes",
                        subtitle: scope == .trash ? "Deleted notes appear here." : "Capture your first thought in one tap.",
                        systemImage: scope == .trash ? "trash" : "square.and.pencil",
                        actionTitle: canShowPrimaryNewNoteButton ? "New Note" : nil,
                        action: canShowPrimaryNewNoteButton ? { createAndOpenNote() } : nil
                    )
                } else {
                    notesList
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(scope.title)
            .searchable(text: $searchText, prompt: "Search Notes")
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
                            Button("Settings", systemImage: "gearshape") {
                                secondaryDestination = .settings
                            }
                            Button("Archive", systemImage: "archivebox") {
                                secondaryDestination = .archive
                            }
                            Button("Trash", systemImage: "trash") {
                                secondaryDestination = .trash
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if canShowPrimaryNewNoteButton {
                    HStack {
                        Spacer()
                        Button {
                            createAndOpenNote()
                        } label: {
                            Label("New Note", systemImage: "square.and.pencil")
                                .font(.headline.weight(.semibold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                        .background(.regularMaterial, in: Capsule(style: .continuous))
                        .glassEffect(.regular.tint(.accentColor).interactive(), in: .capsule)
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                        .accessibilityLabel("New Note")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .animation(.spring(duration: 0.35, bounce: 0.2), value: visibleNotes.count)
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
                NoteRowView(note: note)
                    .matchedTransitionSource(id: note.id, in: transitionNamespace)
            }
            .contextMenu {
                noteContextMenu(note)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: scope != .trash) {
                if scope == .trash {
                    Button("Delete", role: .destructive) {
                        NoteRepository.deletePermanently(note, in: modelContext)
                    }
                } else {
                    Button("Trash", role: .destructive) {
                        NoteRepository.moveToTrash(note, in: modelContext)
                    }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if scope == .trash {
                    Button("Restore") {
                        NoteRepository.restoreFromTrash(note, in: modelContext)
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
            }
            Button("Delete Permanently", systemImage: "trash", role: .destructive) {
                NoteRepository.deletePermanently(note, in: modelContext)
            }
        } else {
            Button(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin") {
                NoteRepository.togglePinned(note, in: modelContext)
            }
            Button(note.isFavorite ? "Unfavorite" : "Favorite", systemImage: note.isFavorite ? "star.slash" : "star") {
                NoteRepository.toggleFavorite(note, in: modelContext)
            }

            if scope == .archived {
                Button("Unarchive", systemImage: "archivebox.fill") {
                    NoteRepository.unarchive(note, in: modelContext)
                }
            } else {
                Button("Archive", systemImage: "archivebox") {
                    NoteRepository.archive(note, in: modelContext)
                }
            }

            Button("Move to Trash", systemImage: "trash", role: .destructive) {
                NoteRepository.moveToTrash(note, in: modelContext)
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
                case .archive:
                    NotesListScreen(scope: .archived, showsPrimaryChrome: false)
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
