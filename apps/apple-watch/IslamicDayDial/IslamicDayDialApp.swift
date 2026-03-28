import SwiftUI
import UserNotifications

private final class PhoneNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let overlayStore: PhoneNotificationOverlayStore

    init(overlayStore: PhoneNotificationOverlayStore) {
        self.overlayStore = overlayStore
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            overlayStore.present(from: notification.request.content)
        }
        completionHandler([])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            overlayStore.present(from: response.notification.request.content)
            completionHandler()
        }
    }
}

@main
struct IslamicDayDialApp: App {
    private static let notificationOverlayStore = PhoneNotificationOverlayStore()
    private static let notificationDelegate = PhoneNotificationDelegate(
        overlayStore: notificationOverlayStore
    )

    init() {
        WatchMirrorSyncService.shared.start()
        UNUserNotificationCenter.current().delegate = Self.notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Self.notificationOverlayStore)
        }
    }
}
