import Foundation

public let WATCH_RENDER_SNAPSHOT_CONTEXT_KEY = "watchRenderSnapshot"
public let WATCH_RENDER_SNAPSHOT_REQUEST_KEY = "watchRequestLatestSnapshot"
public let WATCH_RENDER_SNAPSHOT_SCHEMA_VERSION = 1

public struct WatchRenderSnapshotEnvelope: Codable, Equatable {
    public let schemaVersion: Int
    public let generatedAt: Date
    public let renderNow: Date
    public let location: Location
    public let snapshot: ComputedIslamicDay

    public init(
        schemaVersion: Int = WATCH_RENDER_SNAPSHOT_SCHEMA_VERSION,
        generatedAt: Date = Date(),
        renderNow: Date,
        location: Location,
        snapshot: ComputedIslamicDay
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.renderNow = renderNow
        self.location = location
        self.snapshot = snapshot
    }
}

public enum WatchRenderSnapshotCodec {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()

    public static func encode(_ envelope: WatchRenderSnapshotEnvelope) throws -> Data {
        try encoder.encode(envelope)
    }

    public static func decode(_ data: Data) throws -> WatchRenderSnapshotEnvelope {
        try decoder.decode(WatchRenderSnapshotEnvelope.self, from: data)
    }
}

public func mirroredWatchRenderNow(
    envelope: WatchRenderSnapshotEnvelope,
    currentDate: Date = Date()
) -> Date {
    envelope.renderNow.addingTimeInterval(currentDate.timeIntervalSince(envelope.generatedAt))
}
