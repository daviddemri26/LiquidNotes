import SwiftUI
import SwiftData

struct AppCoordinator: View {
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        LiquidTabView()
            .task {
                dependencies.notificationService.registerCategories()
            }
    }
}
