import Foundation
import UserNotifications

/// Schedules local notifications for the five daily prayer/day markers.
/// Notifications are scheduled for today and tomorrow based on user location.
/// Rescheduling runs on app launch and when app returns from background (handles travel).
///
/// Notification format:
/// - Title: "PrayerName time has begun"
/// - Body: "5 Shawwal 1447"
enum PrayerNotificationScheduler {
    private static let categoryId = "PRAYER_REMINDER"
    private static let identifierPrefix = "prayer_"
    private static let eidGreetingDelay: TimeInterval = 2 * 60 * 60
    private static let eidGreetingTitle = "Taqabbal Allahu minna wa minkum!"
    private static let eidGreetingBody = "May Allah accept from us and from you!"

    private enum NotificationKind: String {
        case fajr
        case dhuhr
        case asr
        case maghrib
        case isha
        case jumuah
        case eid
        case eidGreeting
    }

    private struct NotificationPlan {
        let kind: NotificationKind
        let title: String
        let body: String
        let fireDate: Date
    }

    /// Request notification authorization and schedule prayer notifications.
    /// Call when app has resolved user location.
    static func requestAndSchedule(location: Location) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true else { return }
        await schedule(location: location)
    }

    /// Schedule prayer notifications for today and tomorrow.
    static func schedule(location: Location) async {
        let center = UNUserNotificationCenter.current()
        let now = Date()
        let cal = Calendar.current

        guard let todayPlans = buildPlans(for: now, location: location),
              let tomorrowDate = cal.date(byAdding: .day, value: 1, to: now),
              let tomorrowPlans = buildPlans(for: tomorrowDate, location: location) else {
            return
        }

        // Remove existing prayer notifications
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending.filter { $0.identifier.hasPrefix(Self.identifierPrefix) }
        let ids = toRemove.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)

        var requests: [UNNotificationRequest] = []
        for plan in (todayPlans + tomorrowPlans) where plan.fireDate > now {
            if let req = makeRequest(plan: plan) {
                requests.append(req)
            }
        }

        for req in requests {
            try? await center.add(req)
        }
    }

    private static func formatHijriTitle(hijri: HijriDate) -> String {
        "\(hijri.day) \(hijri.monthNameEn) \(hijri.year)"
    }

    private static func buildPlans(for date: Date, location: Location) -> [NotificationPlan]? {
        guard let prayerTimes = getPrayerTimesForDate(date: date, location: location),
              let midday = localMidday(for: date),
              let snapshot = computeIslamicDaySnapshot(now: midday, location: location) else {
            return nil
        }

        let hijriDate = getIslamicDayHijriDate(now: prayerTimes.dhuhr, todayMaghrib: prayerTimes.maghrib)
        let hijriParts = formatHijriDateParts(hijriDate)
        let isFriday = Calendar.current.component(.weekday, from: prayerTimes.dhuhr) == 6

        var plans = [
            prayerPlan(kind: .fajr, prayerName: "Fajr", fireDate: prayerTimes.fajr, maghribForDay: prayerTimes.maghrib),
            noonPlan(
                prayerTimes: prayerTimes,
                duhaStart: snapshot.timeline.duhaStart,
                isFriday: isFriday,
                hijriParts: hijriParts
            ),
            prayerPlan(kind: .asr, prayerName: "Asr", fireDate: prayerTimes.asr, maghribForDay: prayerTimes.maghrib),
            prayerPlan(kind: .maghrib, prayerName: "Maghrib", fireDate: prayerTimes.maghrib, maghribForDay: prayerTimes.maghrib),
            prayerPlan(kind: .isha, prayerName: "Isha", fireDate: prayerTimes.isha, maghribForDay: prayerTimes.maghrib),
        ]

        if hijriParts.isEid {
            plans.append(
                NotificationPlan(
                    kind: .eidGreeting,
                    title: eidGreetingTitle,
                    body: eidGreetingBody,
                    fireDate: snapshot.timeline.duhaStart.addingTimeInterval(eidGreetingDelay)
                )
            )
        }

        return plans
    }

    private static func prayerPlan(
        kind: NotificationKind,
        prayerName: String,
        fireDate: Date,
        maghribForDay: Date
    ) -> NotificationPlan {
        let hijriDate = getIslamicDayHijriDate(now: fireDate, todayMaghrib: maghribForDay)
        return NotificationPlan(
            kind: kind,
            title: "\(prayerName) time has begun",
            body: formatHijriTitle(hijri: hijriDate),
            fireDate: fireDate
        )
    }

    private static func noonPlan(
        prayerTimes: PrayerTimesData,
        duhaStart: Date,
        isFriday: Bool,
        hijriParts: (dayMonth: String, year: String, isEid: Bool)
    ) -> NotificationPlan {
        if hijriParts.isEid {
            return prayerPlan(
                kind: .eid,
                prayerName: hijriParts.dayMonth,
                fireDate: duhaStart,
                maghribForDay: prayerTimes.maghrib
            )
        }
        if isFriday {
            return prayerPlan(
                kind: .jumuah,
                prayerName: "Jumu'ah",
                fireDate: duhaStart,
                maghribForDay: prayerTimes.maghrib
            )
        }
        return prayerPlan(
            kind: .dhuhr,
            prayerName: "Dhuhr",
            fireDate: prayerTimes.dhuhr,
            maghribForDay: prayerTimes.maghrib
        )
    }

    private static func localMidday(for date: Date) -> Date? {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date)
    }

    private static func makeRequest(plan: NotificationPlan) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        content.title = plan.title
        content.body = plan.body
        content.sound = .default
        content.categoryIdentifier = Self.categoryId

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: plan.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = "\(Self.identifierPrefix)\(plan.kind.rawValue)_\(comps.year ?? 0)_\(comps.month ?? 0)_\(comps.day ?? 0)_\(comps.hour ?? 0)_\(comps.minute ?? 0)"
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    /// For unit testing notification naming and timing rules.
    static func describeNotificationsForTesting(date: Date, location: Location) -> [(name: String, fireDate: Date)] {
        (buildPlans(for: date, location: location) ?? []).map { ($0.title.replacingOccurrences(of: " time has begun", with: ""), $0.fireDate) }
    }

    /// For unit testing full notification payloads.
    static func describeNotificationPayloadsForTesting(date: Date, location: Location) -> [(title: String, body: String, fireDate: Date)] {
        (buildPlans(for: date, location: location) ?? []).map { ($0.title, $0.body, $0.fireDate) }
    }

    /// For unit testing notification content format only.
    static func formatContentForTesting(prayerName: String, fireDate: Date, maghrib: Date) -> (title: String, body: String) {
        let hijriDate = getIslamicDayHijriDate(now: fireDate, todayMaghrib: maghrib)
        let title = "\(prayerName) time has begun"
        let body = "\(hijriDate.day) \(hijriDate.monthNameEn) \(hijriDate.year)"
        return (title, body)
    }
}
