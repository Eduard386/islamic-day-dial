import XCTest

/// Notification content format: prayer-day reminders use observable titles with empty bodies.
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
        XCTAssertEqual(title, "Fajr. Check the horizon")
    }

    func testFormatContent_UsesEmptyBodyForPrayerReminders() {
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
        let expectedTitles = [
            "Fajr": "Fajr. Check the horizon",
            "Dhuhr": "Dhuhr. Check the shadow",
            "Asr": "Asr. Check the shadow",
            "Maghrib": "Maghrib. Watch for sunset",
            "Isha": "Isha. Check the sky"
        ]
        for (name, expectedTitle) in expectedTitles {
            let (title, body) = PrayerNotificationScheduler.formatContentForTesting(
                prayerName: name,
                fireDate: fireDate,
                maghrib: maghrib
            )
            XCTAssertEqual(title, expectedTitle)
            XCTAssertEqual(body, "")
        }
    }

    func testDescribeNotifications_UsesJumuahInsteadOfDhuhrOnFriday() {
        let friday = dateFromISO("2026-03-27T12:00:00")
        let notifications = PrayerNotificationScheduler.describeNotificationsForTesting(date: friday, location: mecca)
        let snapshot = computeIslamicDaySnapshot(now: friday, location: mecca)
        let jumuahTitle = "Prepare for Jumu'ah"
        let jumuahNotification = notifications.first { $0.title == jumuahTitle }

        XCTAssertEqual(notifications.count, 5)
        XCTAssertTrue(notifications.contains { $0.title == jumuahTitle })
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
        let eidTitle = "Eid al-Fitr"
        let eidNotification = notifications.first { $0.title == eidTitle }

        XCTAssertEqual(notifications.count, 5)
        XCTAssertTrue(notifications.contains { $0.title == eidTitle })
        XCTAssertFalse(notifications.contains { $0.title == "Prepare for Jumu'ah" })
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
        let eidTitle = "Eid al-Adha"
        let eidNotification = notifications.first { $0.title == eidTitle }

        XCTAssertEqual(notifications.count, 5)
        XCTAssertNotNil(eidNotification)
        XCTAssertTrue(notifications.contains { $0.title == eidTitle })
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

    func testDescribeNotificationPayloads_PrayerRemindersUseEmptyBodies() {
        let regularDay = dateFromISO("2026-03-23T12:00:00")
        let payloads = PrayerNotificationScheduler.describeNotificationPayloadsForTesting(date: regularDay, location: mecca)
        let prayerPayloads = payloads

        XCTAssertFalse(prayerPayloads.isEmpty)
        XCTAssertTrue(prayerPayloads.allSatisfy { $0.body.isEmpty })
    }

    /// Full matrix: every scheduled prayer notification kind, titles, fire times vs computed times, empty bodies.
    func testAllNotifications_RegularWeekday_OrderTitlesAndFireTimesMatchPrayerTimes() {
        let day = dateFromISO("2026-03-24T12:00:00")
        guard let prayerTimes = getPrayerTimesForDate(date: day, location: mecca) else {
            XCTFail("expected prayer times for Mecca")
            return
        }
        let payloads = PrayerNotificationScheduler.describeNotificationPayloadsForTesting(date: day, location: mecca)
        XCTAssertEqual(payloads.count, 5)
        XCTAssertTrue(payloads.allSatisfy { $0.body.isEmpty })

        let sorted = payloads.sorted { $0.fireDate < $1.fireDate }
        XCTAssertEqual(sorted[0].title, "Fajr. Check the horizon")
        XCTAssertEqual(sorted[1].title, "Dhuhr. Check the shadow")
        XCTAssertEqual(sorted[2].title, "Asr. Check the shadow")
        XCTAssertEqual(sorted[3].title, "Maghrib. Watch for sunset")
        XCTAssertEqual(sorted[4].title, "Isha. Check the sky")

        XCTAssertEqual(Int(sorted[0].fireDate.timeIntervalSince1970), Int(prayerTimes.fajr.timeIntervalSince1970))
        XCTAssertEqual(Int(sorted[1].fireDate.timeIntervalSince1970), Int(prayerTimes.dhuhr.timeIntervalSince1970))
        XCTAssertEqual(Int(sorted[2].fireDate.timeIntervalSince1970), Int(prayerTimes.asr.timeIntervalSince1970))
        XCTAssertEqual(Int(sorted[3].fireDate.timeIntervalSince1970), Int(prayerTimes.maghrib.timeIntervalSince1970))
        XCTAssertEqual(Int(sorted[4].fireDate.timeIntervalSince1970), Int(prayerTimes.isha.timeIntervalSince1970))
    }

    func testAllNotifications_Friday_NoonSlotIsJumuahAtDuhaStart() {
        let friday = dateFromISO("2026-03-27T12:00:00")
        guard let prayerTimes = getPrayerTimesForDate(date: friday, location: mecca),
              let snapshot = computeIslamicDaySnapshot(now: friday, location: mecca) else {
            XCTFail("expected snapshot")
            return
        }
        let payloads = PrayerNotificationScheduler.describeNotificationPayloadsForTesting(date: friday, location: mecca)
        XCTAssertEqual(payloads.count, 5)
        XCTAssertTrue(payloads.allSatisfy { $0.body.isEmpty })

        let sorted = payloads.sorted { $0.fireDate < $1.fireDate }
        XCTAssertEqual(sorted[0].title, "Fajr. Check the horizon")
        XCTAssertEqual(sorted[1].title, "Prepare for Jumu'ah")
        XCTAssertEqual(Int(sorted[1].fireDate.timeIntervalSince1970), Int(snapshot.timeline.duhaStart.timeIntervalSince1970))
        XCTAssertNotEqual(
            Int(sorted[1].fireDate.timeIntervalSince1970),
            Int(prayerTimes.dhuhr.timeIntervalSince1970)
        )
        XCTAssertEqual(sorted[2].title, "Asr. Check the shadow")
        XCTAssertEqual(sorted[3].title, "Maghrib. Watch for sunset")
        XCTAssertEqual(sorted[4].title, "Isha. Check the sky")
    }

    func testAllNotifications_EidFriday_EidAtDuhaNotJumuahAndOtherSlotsUnchanged() {
        let eidFriday = dateFromISO("2026-03-20T12:00:00")
        guard let prayerTimes = getPrayerTimesForDate(date: eidFriday, location: mecca),
              let snapshot = computeIslamicDaySnapshot(now: eidFriday, location: mecca) else {
            XCTFail("expected snapshot")
            return
        }
        let payloads = PrayerNotificationScheduler.describeNotificationPayloadsForTesting(date: eidFriday, location: mecca)
        XCTAssertEqual(payloads.count, 5)
        XCTAssertTrue(payloads.allSatisfy { $0.body.isEmpty })

        let sorted = payloads.sorted { $0.fireDate < $1.fireDate }
        XCTAssertEqual(sorted[0].title, "Fajr. Check the horizon")
        XCTAssertEqual(sorted[1].title, "Eid al-Fitr")
        XCTAssertEqual(Int(sorted[1].fireDate.timeIntervalSince1970), Int(snapshot.timeline.duhaStart.timeIntervalSince1970))
        XCTAssertEqual(sorted[2].title, "Asr. Check the shadow")
        XCTAssertEqual(Int(sorted[2].fireDate.timeIntervalSince1970), Int(prayerTimes.asr.timeIntervalSince1970))
        XCTAssertEqual(sorted[3].title, "Maghrib. Watch for sunset")
        XCTAssertEqual(sorted[4].title, "Isha. Check the sky")
        XCTAssertFalse(payloads.contains { $0.title == "Prepare for Jumu'ah" })
    }

    func testAllNotifications_EidWeekday_EidAtDuha() {
        let eidDay = dateFromISO("2026-05-27T12:00:00")
        guard let prayerTimes = getPrayerTimesForDate(date: eidDay, location: mecca),
              let snapshot = computeIslamicDaySnapshot(now: eidDay, location: mecca) else {
            XCTFail("expected snapshot")
            return
        }
        let payloads = PrayerNotificationScheduler.describeNotificationPayloadsForTesting(date: eidDay, location: mecca)
        XCTAssertEqual(payloads.count, 5)
        XCTAssertTrue(payloads.allSatisfy { $0.body.isEmpty })

        let sorted = payloads.sorted { $0.fireDate < $1.fireDate }
        XCTAssertEqual(sorted[0].title, "Fajr. Check the horizon")
        XCTAssertEqual(sorted[1].title, "Eid al-Adha")
        XCTAssertEqual(Int(sorted[1].fireDate.timeIntervalSince1970), Int(snapshot.timeline.duhaStart.timeIntervalSince1970))
        XCTAssertEqual(sorted[2].title, "Asr. Check the shadow")
        XCTAssertEqual(Int(sorted[2].fireDate.timeIntervalSince1970), Int(prayerTimes.asr.timeIntervalSince1970))
    }

    func testFormatContent_JumuahAndEidTitles() {
        let d = dateFromISO("2026-03-20T12:00:00")
        let m = dateFromISO("2026-03-20T18:00:00")
        XCTAssertEqual(
            PrayerNotificationScheduler.formatContentForTesting(prayerName: "Jumu'ah", fireDate: d, maghrib: m).title,
            "Prepare for Jumu'ah"
        )
        XCTAssertEqual(
            PrayerNotificationScheduler.formatContentForTesting(prayerName: "EID AL-FITR", fireDate: d, maghrib: m).title,
            "Eid al-Fitr"
        )
        XCTAssertEqual(
            PrayerNotificationScheduler.formatContentForTesting(prayerName: "EID AL-ADHA", fireDate: d, maghrib: m).title,
            "Eid al-Adha"
        )
    }

    private func dateFromISO(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso + "Z") ?? Date()
    }
}
