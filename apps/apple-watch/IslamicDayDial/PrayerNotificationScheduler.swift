import Foundation
import UserNotifications

/// Schedules local notifications for the five daily prayer/day markers.
/// Notifications are scheduled for today and tomorrow based on user location.
/// Rescheduling runs on app launch and when app returns from background (handles travel).
///
/// Notification format:
/// - Fard prayer titles: observable prompts tied to the Jibril signs
/// - Special-day titles: current Jumu'ah / Eid labels
/// - Body: empty for prayer-day reminders; retained only for the Eid greeting
enum PrayerNotificationScheduler {
    private static let categoryId = "PRAYER_REMINDER"
    private static let identifierPrefix = "prayer_"
    private static let debugSequenceKeyPrefix = "prayer_debug_sequence"

    private enum NotificationKind: String {
        case fajr
        case dhuhr
        case asr
        case maghrib
        case isha
        case jumuah
        case eid
    }

    private struct NotificationPlan {
        let kind: NotificationKind
        let title: String
        let body: String
        let fireDate: Date
    }

    /// Short reminder line (text after the em dash in product copy).
    private static let fajrTitle = "Fajr. Check the horizon"
    private static let dhuhrTitle = "Dhuhr. Check the shadow"
    private static let asrTitle = "Asr. Check the shadow"
    private static let maghribTitle = "Maghrib. Watch for sunset"
    private static let ishaTitle = "Isha. Check the sky"
    private static let jumuahTitle = "Prepare for Jumu'ah"
    private static let eidAlFitrTitle = "Eid al-Fitr"
    private static let eidAlAdhaTitle = "Eid al-Adha"

    private static var authorizationOptions: UNAuthorizationOptions {
        #if os(watchOS)
        return [.alert, .sound]
        #else
        return [.alert, .sound, .badge]
        #endif
    }

    /// Request notification authorization and schedule prayer notifications.
    /// Call when app has resolved user location.
    static func requestAndSchedule(location: Location) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: authorizationOptions)) == true else { return }
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

    private static func buildPlans(for date: Date, location: Location) -> [NotificationPlan]? {
        guard let prayerTimes = getPrayerTimesForDate(date: date, location: location),
              let midday = localMidday(for: date),
              let snapshot = computeIslamicDaySnapshot(now: midday, location: location) else {
            return nil
        }

        let hijriDate = getIslamicDayHijriDate(now: prayerTimes.dhuhr, todayMaghrib: prayerTimes.maghrib)
        let hijriParts = formatHijriDateParts(hijriDate)
        let isFriday = Calendar.current.component(.weekday, from: prayerTimes.dhuhr) == 6

        let plans = [
            prayerPlan(kind: .fajr, prayerName: "Fajr", fireDate: prayerTimes.fajr),
            noonPlan(
                prayerTimes: prayerTimes,
                duhaStart: snapshot.timeline.duhaStart,
                isFriday: isFriday,
                hijriParts: hijriParts,
                hijriDate: hijriDate
            ),
            prayerPlan(kind: .asr, prayerName: "Asr", fireDate: prayerTimes.asr),
            prayerPlan(kind: .maghrib, prayerName: "Maghrib", fireDate: prayerTimes.maghrib),
            prayerPlan(kind: .isha, prayerName: "Isha", fireDate: prayerTimes.isha),
        ]

        return plans
    }

    private static func prayerPlan(
        kind: NotificationKind,
        prayerName: String,
        fireDate: Date
    ) -> NotificationPlan {
        return NotificationPlan(
            kind: kind,
            title: title(for: kind, prayerName: prayerName),
            body: "",
            fireDate: fireDate
        )
    }

    private static func title(for kind: NotificationKind, prayerName: String) -> String {
        switch kind {
        case .fajr:
            return fajrTitle
        case .dhuhr:
            return dhuhrTitle
        case .asr:
            return asrTitle
        case .maghrib:
            return maghribTitle
        case .isha:
            return ishaTitle
        case .jumuah:
            return jumuahTitle
        case .eid:
            switch prayerName {
            case "EID AL-FITR":
                return eidAlFitrTitle
            case "EID AL-ADHA":
                return eidAlAdhaTitle
            default:
                return "\(prayerName) prayer time has started."
            }
        }
    }

    private static func noonPlan(
        prayerTimes: PrayerTimesData,
        duhaStart: Date,
        isFriday: Bool,
        hijriParts: (dayMonth: String, year: String, isEid: Bool),
        hijriDate: HijriDate
    ) -> NotificationPlan {
        if hijriParts.isEid {
            let eidKey = hijriDate.monthNumber == 10 ? "EID AL-FITR" : "EID AL-ADHA"
            return prayerPlan(
                kind: .eid,
                prayerName: eidKey,
                fireDate: duhaStart
            )
        }
        if isFriday {
            return prayerPlan(
                kind: .jumuah,
                prayerName: "Jumu'ah",
                fireDate: duhaStart
            )
        }
        return prayerPlan(
            kind: .dhuhr,
            prayerName: "Dhuhr",
            fireDate: prayerTimes.dhuhr
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

    static func sendRandomDebugNotification(date: Date, location: Location) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: authorizationOptions)) == true else { return }

        let sourcePlans = buildPlans(for: date, location: location) ?? []
        guard let selected = sourcePlans.randomElement() else { return }

        let content = UNMutableNotificationContent()
        content.title = selected.title
        content.body = selected.body
        content.sound = .default
        content.categoryIdentifier = Self.categoryId

        let request = UNNotificationRequest(
            identifier: "\(Self.identifierPrefix)debug_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try? await center.add(request)
    }

    static func sendSequentialDebugNotification(date: Date, location: Location, surface: String) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: authorizationOptions)) == true else { return }

        let sourcePlans = buildPlans(for: date, location: location) ?? []
        guard !sourcePlans.isEmpty else { return }

        let defaults = UserDefaults.standard
        let key = debugSequenceKey(for: date, surface: surface)
        let nextIndex = defaults.integer(forKey: key) % sourcePlans.count
        let selected = sourcePlans[nextIndex]
        defaults.set((nextIndex + 1) % sourcePlans.count, forKey: key)

        let content = UNMutableNotificationContent()
        content.title = selected.title
        content.body = selected.body
        content.sound = .default
        content.categoryIdentifier = Self.categoryId

        let request = UNNotificationRequest(
            identifier: "\(Self.identifierPrefix)debug_seq_\(surface)_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try? await center.add(request)
    }

    private static func debugSequenceKey(for date: Date, surface: String) -> String {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let stamp = Int(startOfDay.timeIntervalSince1970)
        return "\(debugSequenceKeyPrefix)_\(surface)_\(stamp)"
    }

    /// For unit testing notification naming and timing rules.
    static func describeNotificationsForTesting(date: Date, location: Location) -> [(title: String, fireDate: Date)] {
        (buildPlans(for: date, location: location) ?? []).map { ($0.title, $0.fireDate) }
    }

    /// For unit testing full notification payloads.
    static func describeNotificationPayloadsForTesting(date: Date, location: Location) -> [(title: String, body: String, fireDate: Date)] {
        (buildPlans(for: date, location: location) ?? []).map { ($0.title, $0.body, $0.fireDate) }
    }

    /// For unit testing notification content format only.
    static func formatContentForTesting(prayerName: String, fireDate: Date, maghrib: Date) -> (title: String, body: String) {
        _ = fireDate
        _ = maghrib
        let kind: NotificationKind
        switch prayerName {
        case "Fajr":
            kind = .fajr
        case "Dhuhr":
            kind = .dhuhr
        case "Asr":
            kind = .asr
        case "Maghrib":
            kind = .maghrib
        case "Isha":
            kind = .isha
        case "Jumu'ah":
            kind = .jumuah
        case "EID AL-FITR":
            kind = .eid
        case "EID AL-ADHA":
            kind = .eid
        default:
            kind = .dhuhr
        }
        let title = title(for: kind, prayerName: prayerName)
        return (title, "")
    }
}
