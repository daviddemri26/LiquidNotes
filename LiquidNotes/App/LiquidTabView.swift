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
            NotesListScreen(
                scope: .notes,
                handlesExternalRouting: selectedScope == .notes,
                searchText: $searchText
            )
                .opacity(selectedScope == .notes ? 1 : 0)
                .allowsHitTesting(selectedScope == .notes)

            NotesListScreen(
                scope: .favorites,
                handlesExternalRouting: selectedScope == .favorites,
                searchText: $searchText
            )
                .opacity(selectedScope == .favorites ? 1 : 0)
                .allowsHitTesting(selectedScope == .favorites)
        }
        .animation(.snappy(duration: 0.3), value: selectedScope)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomDock
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: isSearchExpanded) { _, expanded in
            if expanded {
                Task { @MainActor in
                    await Task.yield()
                    isSearchFieldFocused = true
                }
            } else {
                isSearchFieldFocused = false
            }
        }
    }

    @ViewBuilder
    private var bottomDock: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                if isSearchExpanded {
                    expandedSearchDock
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomLeading)))
                } else {
                    compactDock
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomLeading)))
                }

                Spacer(minLength: 8)

                Button {
                    createAndOpenNote()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 21, weight: .semibold))
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(GlassIconButtonStyle(tinted: true))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                .accessibilityLabel("New Note")
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.clear)
        .animation(.spring(duration: 0.32, bounce: 0.14), value: isSearchExpanded)
    }

    private var compactDock: some View {
        HStack(spacing: 6) {
            DockSegmentButton(
                systemImage: "note.text",
                isSelected: selectedScope == .notes
            ) {
                withAnimation(.snappy(duration: 0.22)) {
                    selectedScope = .notes
                }
                dependencies.haptics.selection()
            }

            DockSegmentButton(
                systemImage: "star",
                isSelected: selectedScope == .favorites
            ) {
                withAnimation(.snappy(duration: 0.22)) {
                    selectedScope = .favorites
                }
                dependencies.haptics.selection()
            }

            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                    isSearchExpanded = true
                }
                dependencies.haptics.selection()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.headline.weight(.semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(GlassIconButtonStyle())
            .matchedGeometryEffect(id: "searchDock", in: dockNamespace)
            .accessibilityLabel("Search")
        }
        .padding(6)
        .background(.regularMaterial, in: Capsule(style: .continuous))
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private var expandedSearchDock: some View {
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
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(GlassIconButtonStyle())
            .accessibilityLabel("Close search")
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.regularMaterial, in: Capsule(style: .continuous))
        .glassEffect(.regular.interactive(), in: .capsule)
        .matchedGeometryEffect(id: "searchDock", in: dockNamespace)
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
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(GlassIconButtonStyle(tinted: isSelected))
    }
}

private struct GlassIconButtonStyle: ButtonStyle {
    var tinted = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tinted ? .white : .primary)
            .background((tinted ? Color.accentColor.opacity(0.95) : Color.clear), in: Circle())
            .background(.regularMaterial, in: Circle())
            .glassEffect(.regular.interactive(), in: .circle)
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(duration: 0.22, bounce: 0.18), value: configuration.isPressed)
    }
}
