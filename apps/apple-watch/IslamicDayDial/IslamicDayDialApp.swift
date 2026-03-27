import SwiftUI
import UserNotifications

#if DEBUG
private final class DebugPhoneNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
#endif

@main
struct IslamicDayDialApp: App {
    #if DEBUG
    private static let debugNotificationDelegate = DebugPhoneNotificationDelegate()
    #endif

    init() {
        WatchMirrorSyncService.shared.start()
        #if DEBUG
        UNUserNotificationCenter.current().delegate = Self.debugNotificationDelegate
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
