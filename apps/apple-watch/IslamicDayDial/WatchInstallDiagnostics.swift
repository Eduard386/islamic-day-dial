import Foundation
import OSLog
import UIKit
import WatchConnectivity

/// Debug-only diagnostics for Watch companion install / link quality.
/// Filter Xcode console by subsystem `com.islamicdaydial.watchlink` or search `IDD_WATCH`.
///
/// **Important:** Payload transfer + install are done by **iOS (appconduitd / Bridge)**, not your Swift code.
/// These logs show what **WatchConnectivity** believes about pairing / install / reachability — useful when
/// the on-watch spinner stalls or Xcode shows **Disconnected** (tunnel/radio), not a substitute for
/// **Console.app → process `appconduitd`** during install.
#if DEBUG
private let watchLinkLog = Logger(subsystem: "com.islamicdaydial.watchlink", category: "iphone")

private struct WatchSessionSnapshot: Equatable {
    let paired: Bool
    let watchAppInstalled: Bool
    let reachable: Bool
    let activationRaw: Int
    let hasContentPending: Bool
}

final class WatchInstallDiagnostics: NSObject, WCSessionDelegate {
    static let shared = WatchInstallDiagnostics()

    private var lastSnapshot: WatchSessionSnapshot?
    private var pollTimer: Timer?
    private var pollTick: Int = 0

    func start() {
        guard WCSession.isSupported() else {
            watchLinkLog.notice("IDD_WATCH iPhone: WatchConnectivity not supported on this device")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()

        watchLinkLog.notice("IDD_WATCH iPhone: WCSession.activate() requested — keep app in FOREGROUND during long watch installs; tunnel drops if phone locks or Xcode loses Core Device.")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            self?.pollTick += 1
            self?.logPoll()
        }
        if let t = pollTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    @objc private func onDidBecomeActive() {
        watchLinkLog.notice("IDD_WATCH iPhone: UIApplication.didBecomeActive — snapshot below")
        logSession(WCSession.default, prefix: "didBecomeActive")
    }

    @objc private func onWillResignActive() {
        watchLinkLog.notice("IDD_WATCH iPhone: UIApplication.willResignActive (screen lock / multitask) — install/tunnel often stalls here")
    }

    private func logPoll() {
        let session = WCSession.default
        let snap = snapshot(from: session)
        if snap != lastSnapshot {
            lastSnapshot = snap
            watchLinkLog.notice("IDD_WATCH iPhone: state CHANGED (poll #\(self.pollTick, privacy: .public))")
            logSession(session, prefix: "poll")
        } else {
            // Heartbeat so you see the process is alive during a long spinner.
            watchLinkLog.info(
                "IDD_WATCH iPhone: poll #\(self.pollTick, privacy: .public) unchanged paired=\(snap.paired, privacy: .public) watchAppInstalled=\(snap.watchAppInstalled, privacy: .public) reachable=\(snap.reachable, privacy: .public)"
            )
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            watchLinkLog.error("IDD_WATCH iPhone: activation FAILED \(error.localizedDescription, privacy: .public)")
            return
        }
        lastSnapshot = snapshot(from: session)
        watchLinkLog.notice("IDD_WATCH iPhone: activationDidComplete")
        logSession(session, prefix: "activationDidComplete")
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        watchLinkLog.notice("IDD_WATCH iPhone: reachabilityDidChange")
        logSession(session, prefix: "reachabilityDidChange")
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        watchLinkLog.notice("IDD_WATCH iPhone: sessionWatchStateDidChange (pairing / watch app install state may have changed)")
        lastSnapshot = snapshot(from: session)
        logSession(session, prefix: "watchStateDidChange")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        watchLinkLog.info("IDD_WATCH iPhone: sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        watchLinkLog.notice("IDD_WATCH iPhone: sessionDidDeactivate — calling activate() again")
        WCSession.default.activate()
    }

    private func snapshot(from session: WCSession) -> WatchSessionSnapshot {
        WatchSessionSnapshot(
            paired: session.isPaired,
            watchAppInstalled: session.isWatchAppInstalled,
            reachable: session.isReachable,
            activationRaw: session.activationState.rawValue,
            hasContentPending: session.hasContentPending
        )
    }

    private func logSession(_ session: WCSession, prefix: String) {
        let state = String(describing: session.activationState)
        let outstandingUserInfo = session.outstandingUserInfoTransfers.count
        let outstandingFiles = session.outstandingFileTransfers.count
        watchLinkLog.notice(
            "IDD_WATCH iPhone: [\(prefix, privacy: .public)] activationState=\(state, privacy: .public) raw=\(session.activationState.rawValue, privacy: .public) paired=\(session.isPaired, privacy: .public) watchAppInstalled=\(session.isWatchAppInstalled, privacy: .public) reachable=\(session.isReachable, privacy: .public) hasContentPending=\(session.hasContentPending, privacy: .public) outstandingUserInfo=\(outstandingUserInfo, privacy: .public) outstandingFiles=\(outstandingFiles, privacy: .public)"
        )

        if session.isPaired, !session.isWatchAppInstalled {
            watchLinkLog.info("IDD_WATCH iPhone: hint — watchAppInstalled=false while paired. (1) Console → appconduitd: if MIInstallerErrorDomain 111 / “free provisioning profile … not allowed to be installed from this source” → paid Apple Developer Program + same team on iOS+watch targets (see README). (2) Else: tunnel/USB/foreground; see README “Watch install stuck”.")
        }
    }
}
#endif
