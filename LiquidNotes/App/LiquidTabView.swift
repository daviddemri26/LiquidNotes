import SwiftUI

struct LiquidTabView: View {
    @State private var selectedTab: NoteListScope = .notes

    var body: some View {
        TabView(selection: $selectedTab) {
            NotesListScreen(scope: .notes)
                .tag(NoteListScope.notes)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            NotesListScreen(scope: .favorites)
                .tag(NoteListScope.favorites)
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
