import XCTest

/// Duha sector starts when the sun reaches 4° above the horizon.
/// Mirrors packages/core snapshot.test.ts and apps/web-dashboard duha-sector.test.ts
final class DuhaStartTests: XCTestCase {

    private var originalTimeZone: TimeZone!

    override func setUp() {
        super.setUp()
        originalTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "Asia/Riyadh")!
    }

    override func tearDown() {
        NSTimeZone.default = originalTimeZone
        super.tearDown()
    }

    func testDuhaStartIsAfterSunriseAndBeforeDuhaEnd() {
        let mecca = Location.mecca
        let now = dateFromISO("2026-03-20T08:00:00")
        guard let snapshot = computeIslamicDaySnapshot(now: now, location: mecca, timezone: TimeZone(identifier: "Asia/Riyadh")!) else {
            XCTFail("computeIslamicDaySnapshot returned nil")
            return
        }
        let sunrise = snapshot.timeline.sunrise
        let duhaStart = snapshot.timeline.duhaStart
        let duhaEnd = snapshot.timeline.duhaEnd

        XCTAssertGreaterThan(duhaStart.timeIntervalSince1970, sunrise.timeIntervalSince1970)
        XCTAssertLessThan(duhaStart.timeIntervalSince1970, duhaEnd.timeIntervalSince1970)
    }

    func testDuhaStartAround4DegreesSolarAltitudeInMecca() {
        let mecca = Location.mecca
        let now = dateFromISO("2026-03-20T08:00:00")
        guard let snapshot = computeIslamicDaySnapshot(now: now, location: mecca, timezone: TimeZone(identifier: "Asia/Riyadh")!) else {
            XCTFail("computeIslamicDaySnapshot returned nil")
            return
        }
        let diffMinutes = (snapshot.timeline.duhaStart.timeIntervalSince1970 - snapshot.timeline.sunrise.timeIntervalSince1970) / 60
        XCTAssertGreaterThan(diffMinutes, 20)
        XCTAssertLessThan(diffMinutes, 26)
    }

    private func dateFromISO(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso + "Z") ?? Date()
    }
}
