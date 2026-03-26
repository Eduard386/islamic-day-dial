import XCTest

/// Notification content format: title = "PrayerName time has begun", body = "day month year".
final class PrayerNotificationTests: XCTestCase {
    private let mecca = Location.mecca

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

    func testFormatContent_TitleContainsPrayerStartMessage() {
        let fireDate = dateFromISO("2026-03-20T04:30:00")
        let maghrib = dateFromISO("2026-03-19T18:00:00")
        let (title, _) = PrayerNotificationScheduler.formatContentForTesting(
            prayerName: "Fajr",
            fireDate: fireDate,
            maghrib: maghrib
        )
        XCTAssertEqual(title, "Fajr time has begun")
    }

    func testFormatContent_BodyContainsHijriDate() {
        let fireDate = dateFromISO("2026-03-20T04:30:00")
        let maghrib = dateFromISO("2026-03-20T18:00:00")
        let (_, body) = PrayerNotificationScheduler.formatContentForTesting(
            prayerName: "Fajr",
            fireDate: fireDate,
            maghrib: maghrib
        )
        XCTAssertTrue(body.contains("1447") || body.contains("1448"))
        XCTAssertTrue(
            body.contains("Ramadan") || body.contains("Shaban") ||
            body.contains("Rabi") || body.contains("Shawwal")
        )
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
            XCTAssertEqual(title, "\(name) time has begun")
            XCTAssertFalse(body.isEmpty)
        }
    }

    func testDescribeNotifications_UsesJumuahInsteadOfDhuhrOnFriday() {
        let friday = dateFromISO("2026-03-27T12:00:00")
        let notifications = PrayerNotificationScheduler.describeNotificationsForTesting(date: friday, location: mecca)
        let snapshot = computeIslamicDaySnapshot(now: friday, location: mecca)
        let jumuahNotification = notifications.first { $0.name == "Jumu'ah" }

        XCTAssertEqual(notifications.count, 5)
        XCTAssertTrue(notifications.contains { $0.name == "Jumu'ah" })
        XCTAssertFalse(notifications.contains { $0.name == "Dhuhr" })
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(
            Int(jumuahNotification?.fireDate.timeIntervalSince1970 ?? -1),
            Int(snapshot?.timeline.duhaStart.timeIntervalSince1970 ?? -2)
        )
    }

    func testDescribeNotifications_UsesEidInsteadOfDhuhrOnFridayEid() {
        let eidFriday = dateFromISO("2026-03-20T12:00:00")
        let notifications = PrayerNotificationScheduler.describeNotificationsForTesting(date: eidFriday, location: mecca)
        let snapshot = computeIslamicDaySnapshot(now: eidFriday, location: mecca)
        let eidNotification = notifications.first { $0.name == "EID AL-FITR" }

        XCTAssertEqual(notifications.count, 6)
        XCTAssertTrue(notifications.contains { $0.name == "EID AL-FITR" })
        XCTAssertFalse(notifications.contains { $0.name == "Jumu'ah" })
        XCTAssertFalse(notifications.contains { $0.name == "Dhuhr" })
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(
            Int(eidNotification?.fireDate.timeIntervalSince1970 ?? -1),
            Int(snapshot?.timeline.duhaStart.timeIntervalSince1970 ?? -2)
        )
    }

    func testDescribeNotifications_UsesEidAtDuhaOnNonFridayEid() {
        let eidDay = dateFromISO("2026-05-27T12:00:00")
        let notifications = PrayerNotificationScheduler.describeNotificationsForTesting(date: eidDay, location: mecca)
        let prayerTimes = getPrayerTimesForDate(date: eidDay, location: mecca)
        let snapshot = computeIslamicDaySnapshot(now: eidDay, location: mecca)
        let eidNotification = notifications.first { $0.name == "EID AL-ADHA" }

        XCTAssertEqual(notifications.count, 6)
        XCTAssertNotNil(eidNotification)
        XCTAssertFalse(notifications.contains { $0.name == "Dhuhr" })
        XCTAssertNotNil(prayerTimes)
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(
            Int(eidNotification?.fireDate.timeIntervalSince1970 ?? -1),
            Int(snapshot?.timeline.duhaStart.timeIntervalSince1970 ?? -2)
        )
        XCTAssertNotEqual(
            Int(eidNotification?.fireDate.timeIntervalSince1970 ?? -1),
            Int(prayerTimes?.dhuhr.timeIntervalSince1970 ?? -1)
        )
    }

    func testDescribeNotificationPayloads_AddsEidGreetingTwoHoursAfterDuha() {
        let eidDay = dateFromISO("2026-05-27T12:00:00")
        let payloads = PrayerNotificationScheduler.describeNotificationPayloadsForTesting(date: eidDay, location: mecca)
        let snapshot = computeIslamicDaySnapshot(now: eidDay, location: mecca)
        let greeting = payloads.first { $0.title == "Taqabbal Allahu minna wa minkum!" }

        XCTAssertNotNil(snapshot)
        XCTAssertNotNil(greeting)
        XCTAssertEqual(greeting?.body, "May Allah accept from us and from you!")
        XCTAssertEqual(
            Int(greeting?.fireDate.timeIntervalSince1970 ?? -1),
            Int((snapshot?.timeline.duhaStart.addingTimeInterval(2 * 60 * 60).timeIntervalSince1970) ?? -2)
        )
    }

    private func dateFromISO(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso + "Z") ?? Date()
    }
}
