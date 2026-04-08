import SwiftUI
import SwiftData
import UserNotifications

final class LiquidNotesAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        guard let noteIDRaw = response.notification.request.content.userInfo["noteID"] as? String,
              let noteID = UUID(uuidString: noteIDRaw) else { return }

        NotificationRouter.shared.routeToNote(with: noteID)
    }
}

@main
struct LiquidNotesApp: App {
    @UIApplicationDelegateAdaptor(LiquidNotesAppDelegate.self) private var appDelegate
    @State private var dependencies = AppDependencies(modelContainer: AppModelContainer.shared)

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environment(dependencies)
        }
        .modelContainer(dependencies.modelContainer)
    }
}
