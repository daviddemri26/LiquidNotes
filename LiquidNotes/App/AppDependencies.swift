import Foundation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let notificationService = ReminderNotificationService()
    let router = NotificationRouter.shared
    let haptics = HapticsService.shared
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
}
