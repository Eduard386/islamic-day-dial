import XCTest

/// Notification content format: "PrayerName. day month year" in title and empty body.
final class PrayerNotificationTests: XCTestCase {

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

    func testFormatContent_TitleContainsPrayerAndHijriDate() {
        let fireDate = dateFromISO("2026-03-20T04:30:00")
        let maghrib = dateFromISO("2026-03-19T18:00:00")
        let (title, _) = PrayerNotificationScheduler.formatContentForTesting(
            prayerName: "Fajr",
            fireDate: fireDate,
            maghrib: maghrib
        )
        XCTAssertTrue(title.hasPrefix("Fajr. "))
        XCTAssertTrue(title.contains("1447") || title.contains("1448"))
        XCTAssertTrue(
            title.contains("Ramadan") || title.contains("Shaban") ||
            title.contains("Rabi") || title.contains("Shawwal")
        )
    }

    func testFormatContent_BodyIsEmpty() {
        let fireDate = dateFromISO("2026-03-20T04:30:00")
        let maghrib = dateFromISO("2026-03-20T18:00:00")
        let (_, body) = PrayerNotificationScheduler.formatContentForTesting(
            prayerName: "Fajr",
            fireDate: fireDate,
            maghrib: maghrib
        )
        XCTAssertEqual(body, "")
    }

    func testFormatContent_AllFivePrayers() {
        let fireDate = dateFromISO("2026-03-20T12:00:00")
        let maghrib = dateFromISO("2026-03-20T18:00:00")
        let prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        for name in prayers {
            let (title, body) = PrayerNotificationScheduler.formatContentForTesting(
                prayerName: name,
                fireDate: fireDate,
                maghrib: maghrib
            )
            XCTAssertTrue(title.hasPrefix("\(name). "))
            XCTAssertEqual(body, "")
        }
    }

    private func dateFromISO(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso + "Z") ?? Date()
    }
}
