import SwiftUI
import SwiftData

struct LiquidTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies

    @State private var selectedScope: NoteListScope = .notes
    @State private var searchText = ""
    @State private var isSearchExpanded = false

    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var dockNamespace

    var body: some View {
        ZStack {
            NotesListScreen(scope: .notes, searchText: $searchText)
                .opacity(selectedScope == .notes ? 1 : 0)
                .allowsHitTesting(selectedScope == .notes)

            NotesListScreen(scope: .favorites, searchText: $searchText)
                .opacity(selectedScope == .favorites ? 1 : 0)
                .allowsHitTesting(selectedScope == .favorites)
        }
        .animation(.snappy(duration: 0.3), value: selectedScope)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomDock
        }
        .onChange(of: isSearchExpanded) { _, expanded in
            if expanded {
                withAnimation(.snappy(duration: 0.2)) {
                    isSearchFieldFocused = true
                }
            } else {
                isSearchFieldFocused = false
            }
        }
    }

    @ViewBuilder
    private var bottomDock: some View {
        GlassEffectContainer(spacing: 24) {
            if isSearchExpanded {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search", text: $searchText)
                        .focused($isSearchFieldFocused)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.search)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }

                    Button {
                        collapseSearch()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.semibold))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial, in: Circle())
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("Close search")
                }
                .padding(.horizontal, 14)
                .frame(height: 56)
                .background(.regularMaterial, in: Capsule(style: .continuous))
                .glassEffect(.regular.interactive(), in: .capsule)
                .matchedGeometryEffect(id: "searchDock", in: dockNamespace)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                HStack(alignment: .center, spacing: 16) {
                    HStack(spacing: 4) {
                        DockSegmentButton(
                            title: "Notes",
                            systemImage: "note.text",
                            isSelected: selectedScope == .notes
                        ) {
                            withAnimation(.snappy(duration: 0.25)) {
                                selectedScope = .notes
                            }
                            dependencies.haptics.selection()
                        }

                        DockSegmentButton(
                            title: "Favorites",
                            systemImage: "star",
                            isSelected: selectedScope == .favorites
                        ) {
                            withAnimation(.snappy(duration: 0.25)) {
                                selectedScope = .favorites
                            }
                            dependencies.haptics.selection()
                        }

                        Button {
                            withAnimation(.spring(duration: 0.32, bounce: 0.16)) {
                                isSearchExpanded = true
                            }
                            dependencies.haptics.selection()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.headline.weight(.semibold))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                        .background(.regularMaterial, in: Circle())
                        .glassEffect(.regular.interactive(), in: .circle)
                        .matchedGeometryEffect(id: "searchDock", in: dockNamespace)
                        .accessibilityLabel("Search")
                    }
                    .padding(6)
                    .background(.regularMaterial, in: Capsule(style: .continuous))
                    .glassEffect(.regular, in: .capsule)

                    Spacer(minLength: 10)

                    Button {
                        createAndOpenNote()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 24, weight: .semibold))
                            .frame(width: 62, height: 62)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial, in: Circle())
                    .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                    .accessibilityLabel("New Note")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.clear)
        .animation(.spring(duration: 0.34, bounce: 0.16), value: isSearchExpanded)
    }

    private func collapseSearch() {
        withAnimation(.spring(duration: 0.32, bounce: 0.14)) {
            isSearchExpanded = false
            searchText = ""
        }
    }

    private func createAndOpenNote() {
        let note = NoteRepository.create(in: modelContext)
        dependencies.haptics.impact(.medium)
        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
            dependencies.router.routeToNote(with: note.id)
        }
    }
}

private struct DockSegmentButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .frame(height: 36)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : .primary)
        .background(isSelected ? Color.accentColor : Color.clear, in: Capsule(style: .continuous))
        .glassEffect(isSelected ? .regular.tint(.accentColor) : .clear, in: .capsule)
    }
}
