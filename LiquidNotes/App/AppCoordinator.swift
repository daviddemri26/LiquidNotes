import SwiftUI
import SwiftData

struct AppCoordinator: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        LiquidTabView()
            .task {
                dependencies.notificationService.registerCategories()
                NoteRepository.purgeExpiredTrash(in: modelContext)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    NoteRepository.purgeExpiredTrash(in: modelContext)
                }
            }
    }
}
