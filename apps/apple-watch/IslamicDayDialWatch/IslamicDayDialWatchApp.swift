import OSLog
import SwiftUI

#if DEBUG
private let watchLifecycleLog = Logger(subsystem: "com.islamicdaydial.watchlink", category: "watch")
#endif

@main
struct IslamicDayDialWatchApp: App {
    init() {
        #if DEBUG
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        watchLifecycleLog.notice(
            "IDD_WATCH watch: process start bundle=\(Bundle.main.bundleIdentifier ?? "?", privacy: .public) version=\(version, privacy: .public) build=\(build, privacy: .public)"
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WatchLifecycleSceneProbe())
        }
    }
}

#if DEBUG
/// Logs when the watch app actually gets foreground/background — appears only after install + launch.
private struct WatchLifecycleSceneProbe: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Color.clear
            .onChange(of: scenePhase) { _, phase in
                watchLifecycleLog.notice(
                    "IDD_WATCH watch: scenePhase=\(String(describing: phase), privacy: .public)"
                )
            }
    }
}
#else
private struct WatchLifecycleSceneProbe: View {
    var body: some View { Color.clear }
}
#endif
