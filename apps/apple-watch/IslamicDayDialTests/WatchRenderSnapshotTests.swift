import XCTest
@testable import IslamicDayDial

final class WatchRenderSnapshotTests: XCTestCase {
    private let mecca = Location(latitude: 21.4225, longitude: 39.8262)

    func testEnvelopeRoundTripsThroughCodec() throws {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = try XCTUnwrap(computeIslamicDaySnapshot(now: base, location: mecca))
        let envelope = WatchRenderSnapshotEnvelope(
            generatedAt: base,
            renderNow: base.addingTimeInterval(900),
            location: mecca,
            snapshot: snapshot
        )

        let data = try WatchRenderSnapshotCodec.encode(envelope)
        let decoded = try WatchRenderSnapshotCodec.decode(data)

        XCTAssertEqual(decoded, envelope)
    }

    func testMirroredWatchRenderNowAdvancesFromRenderNowUsingGenerationTime() throws {
        let generatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let renderNow = generatedAt.addingTimeInterval(3_600)
        let snapshot = try XCTUnwrap(computeIslamicDaySnapshot(now: renderNow, location: mecca))
        let envelope = WatchRenderSnapshotEnvelope(
            generatedAt: generatedAt,
            renderNow: renderNow,
            location: mecca,
            snapshot: snapshot
        )

        let watchNow = generatedAt.addingTimeInterval(120)
        let mirroredNow = mirroredWatchRenderNow(envelope: envelope, currentDate: watchNow)

        XCTAssertEqual(mirroredNow.timeIntervalSince1970, renderNow.addingTimeInterval(120).timeIntervalSince1970, accuracy: 0.001)
    }
}
