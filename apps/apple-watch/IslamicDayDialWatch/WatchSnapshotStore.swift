import Combine
import Foundation
import OSLog
import WatchConnectivity

private let watchMirrorStoreLog = Logger(subsystem: "com.islamicdaydial.watchmirror", category: "watch")
private let WATCH_RENDER_SNAPSHOT_STORAGE_KEY = "watchRenderSnapshotEnvelope"

final class WatchSnapshotStore: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSnapshotStore()

    @Published private(set) var envelope: WatchRenderSnapshotEnvelope?

    var snapshot: ComputedIslamicDay? { envelope?.snapshot }

    private var hasStarted = false

    override private init() {
        super.init()
        loadPersistedEnvelope()
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        guard WCSession.isSupported() else {
            watchMirrorStoreLog.notice("WCSession not supported on watch")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func loadPersistedEnvelope() {
        guard let data = UserDefaults.standard.data(forKey: WATCH_RENDER_SNAPSHOT_STORAGE_KEY) else { return }
        applyPayload(data, persist: false)
    }

    private func persistEnvelopeData(_ data: Data) {
        UserDefaults.standard.set(data, forKey: WATCH_RENDER_SNAPSHOT_STORAGE_KEY)
    }

    private func applyPayload(_ data: Data, persist: Bool = true) {
        do {
            let envelope = try WatchRenderSnapshotCodec.decode(data)
            guard envelope.schemaVersion == WATCH_RENDER_SNAPSHOT_SCHEMA_VERSION else {
                watchMirrorStoreLog.error("Unsupported watch snapshot schema: \(envelope.schemaVersion, privacy: .public)")
                return
            }

            if persist {
                persistEnvelopeData(data)
            }

            DispatchQueue.main.async {
                self.envelope = envelope
            }
        } catch {
            watchMirrorStoreLog.error("Failed to decode mirrored watch snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func requestLatestSnapshotIfPossible() {
        let session = WCSession.default
        guard session.isReachable else { return }

        session.sendMessage([WATCH_RENDER_SNAPSHOT_REQUEST_KEY: true], replyHandler: { reply in
            guard let data = reply[WATCH_RENDER_SNAPSHOT_CONTEXT_KEY] as? Data else { return }
            self.applyPayload(data)
        }, errorHandler: { error in
            watchMirrorStoreLog.error("Failed to request mirrored watch snapshot: \(error.localizedDescription, privacy: .public)")
        })
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            watchMirrorStoreLog.error("Watch WCSession activation failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        if let data = session.receivedApplicationContext[WATCH_RENDER_SNAPSHOT_CONTEXT_KEY] as? Data {
            applyPayload(data)
        }
        requestLatestSnapshotIfPossible()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        requestLatestSnapshotIfPossible()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[WATCH_RENDER_SNAPSHOT_CONTEXT_KEY] as? Data else { return }
        applyPayload(data)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message[WATCH_RENDER_SNAPSHOT_CONTEXT_KEY] as? Data else { return }
        applyPayload(data)
    }
}
