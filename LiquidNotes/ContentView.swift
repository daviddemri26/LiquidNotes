import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        AppCoordinator()
    }
}

#Preview {
    ContentView()
        .environment(AppDependencies(modelContainer: AppModelContainer.shared))
        .modelContainer(AppModelContainer.shared)
}
