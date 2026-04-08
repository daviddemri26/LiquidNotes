import SwiftUI
import SwiftData

struct AppCoordinator: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppDependencies.self) private var dependencies
    @State private var maintenanceTask: Task<Void, Never>?

    var body: some View {
        LiquidTabView()
            .task {
                dependencies.notificationService.registerCategories()
                scheduleTrashMaintenance(after: 1_000_000_000)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    scheduleTrashMaintenance(after: 300_000_000)
                }
            }
            .onDisappear {
                maintenanceTask?.cancel()
                maintenanceTask = nil
            }
    }

    private func scheduleTrashMaintenance(after delayNanoseconds: UInt64) {
        maintenanceTask?.cancel()
        maintenanceTask = Task { @MainActor in
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            guard !Task.isCancelled else { return }
            NoteRepository.purgeExpiredTrash(in: modelContext)
        }
    }
}
