import Foundation
import OSLog
import WatchConnectivity

private let watchMirrorLog = Logger(subsystem: "com.islamicdaydial.watchmirror", category: "iphone")

final class WatchMirrorSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchMirrorSyncService()

    private var hasStarted = false
    private var latestPayloadData: Data?

    func start() {
        guard !hasStarted else { return }
        guard WCSession.isSupported() else {
            watchMirrorLog.notice("WCSession not supported on iPhone")
            return
        }
        hasStarted = true
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func push(snapshot: ComputedIslamicDay?, location: Location, renderNow: Date, generatedAt: Date = Date()) {
        guard let snapshot else { return }
        start()

        let envelope = WatchRenderSnapshotEnvelope(
            generatedAt: generatedAt,
            renderNow: renderNow,
            location: location,
            snapshot: snapshot
        )

        do {
            let data = try WatchRenderSnapshotCodec.encode(envelope)
            latestPayloadData = data
            syncLatestPayload()
        } catch {
            watchMirrorLog.error("Failed to encode watch snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func syncLatestPayload() {
        guard hasStarted, let latestPayloadData else { return }
        let session = WCSession.default
        let context: [String: Any] = [WATCH_RENDER_SNAPSHOT_CONTEXT_KEY: latestPayloadData]

        do {
            try session.updateApplicationContext(context)
        } catch {
            watchMirrorLog.error("Failed to update watch application context: \(error.localizedDescription, privacy: .public)")
        }

        guard session.isReachable else { return }
        session.sendMessage(context, replyHandler: nil) { error in
            watchMirrorLog.error("Failed to send immediate watch snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            watchMirrorLog.error("WCSession activation failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        syncLatestPayload()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            syncLatestPayload()
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        syncLatestPayload()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[WATCH_RENDER_SNAPSHOT_REQUEST_KEY] as? Bool == true else {
            replyHandler([:])
            return
        }

        guard let latestPayloadData else {
            replyHandler([:])
            return
        }

        replyHandler([WATCH_RENDER_SNAPSHOT_CONTEXT_KEY: latestPayloadData])
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
