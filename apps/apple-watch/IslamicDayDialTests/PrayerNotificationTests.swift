import XCTest

/// Notification content format: body = "day month year", with prayer-specific observable titles.
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

    func testFormatContent_FajrUsesObservableTitle() {
        let fireDate = dateFromISO("2026-03-20T04:30:00")
        let maghrib = dateFromISO("2026-03-19T18:00:00")
        let (title, _) = PrayerNotificationScheduler.formatContentForTesting(
            prayerName: "Fajr",
            fireDate: fireDate,
            maghrib: maghrib
        )
        XCTAssertEqual(title, "The sky is brightening, look to the east.")
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
        let expectedTitles = [
            "Fajr": "The sky is brightening, look to the east.",
            "Dhuhr": "Is your shadow lengthening again?",
            "Asr": "Compare the object and its shadow after the noon minimum.",
            "Maghrib": "Look west. Has the sun gone down?",
            "Isha": "Check the sky to see if the last twilight has disappeared."
        ]
        for (name, expectedTitle) in expectedTitles {
            let (title, body) = PrayerNotificationScheduler.formatContentForTesting(
                prayerName: name,
                fireDate: fireDate,
                maghrib: maghrib
            )
            XCTAssertEqual(title, expectedTitle)
            XCTAssertFalse(body.isEmpty)
        }
    }

    func testDescribeNotifications_UsesJumuahInsteadOfDhuhrOnFriday() {
        let friday = dateFromISO("2026-03-27T12:00:00")
        let notifications = PrayerNotificationScheduler.describeNotificationsForTesting(date: friday, location: mecca)
        let snapshot = computeIslamicDaySnapshot(now: friday, location: mecca)
        let jumuahTitle = "Prepare for Jumu'ah: take a bath, use perfume, dress well, and remain silent during the khutba."
        let jumuahNotification = notifications.first { $0.title == jumuahTitle }

        XCTAssertEqual(notifications.count, 5)
        XCTAssertTrue(notifications.contains { $0.title == jumuahTitle })
        XCTAssertFalse(notifications.contains { $0.title == "Is your shadow lengthening again?" })
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
        let eidTitle = "Eid al-Fitr prayer time has started."
        let eidNotification = notifications.first { $0.title == eidTitle }

        XCTAssertEqual(notifications.count, 6)
        XCTAssertTrue(notifications.contains { $0.title == eidTitle })
        XCTAssertFalse(notifications.contains { $0.title == "Prepare for Jumu'ah: take a bath, use perfume, dress well, and remain silent during the khutba." })
        XCTAssertFalse(notifications.contains { $0.title == "Is your shadow lengthening again?" })
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
        let eidTitle = "Eid al-Adha prayer time has started."
        let eidNotification = notifications.first { $0.title == eidTitle }

        XCTAssertEqual(notifications.count, 6)
        XCTAssertNotNil(eidNotification)
        XCTAssertTrue(notifications.contains { $0.title == eidTitle })
        XCTAssertFalse(notifications.contains { $0.title == "Is your shadow lengthening again?" })
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
