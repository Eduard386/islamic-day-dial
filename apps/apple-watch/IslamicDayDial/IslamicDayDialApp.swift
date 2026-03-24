import SwiftUI

@main
struct IslamicDayDialApp: App {
    init() {
        #if DEBUG
        WatchInstallDiagnostics.shared.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
