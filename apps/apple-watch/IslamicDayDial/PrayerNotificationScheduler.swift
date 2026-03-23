import Foundation
import UserNotifications

/// Schedules local notifications for the five daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha).
/// Notifications are scheduled for today and tomorrow based on user location.
/// Rescheduling runs on app launch and when app returns from background (handles travel).
///
/// Notification format:
/// - Title: Hijri date from ring (day month year), e.g. "11 Ramadan 1446"
/// - Body: PrayerName. "ayah" [4:103]
enum PrayerNotificationScheduler {
    private static let categoryId = "PRAYER_REMINDER"
    private static let identifierPrefix = "prayer_"
    private static let bodyAyah = "Indeed, performing prayers is a duty on the believers at the appointed times."

    private enum PrayerKind: String {
        case fajr
        case dhuhr
        case asr
        case maghrib
        case isha
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

        guard let todayPT = getPrayerTimesForDate(date: now, location: location),
              let tomorrowDate = cal.date(byAdding: .day, value: 1, to: now),
              let tomorrowPT = getPrayerTimesForDate(date: tomorrowDate, location: location) else {
            return
        }

        // Remove existing prayer notifications
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending.filter { $0.identifier.hasPrefix(Self.identifierPrefix) }
        let ids = toRemove.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)

        var requests: [UNNotificationRequest] = []
        let prayers: [(PrayerKind, Date, Date)] = [
            (.fajr, todayPT.fajr, todayPT.maghrib),
            (.dhuhr, todayPT.dhuhr, todayPT.maghrib),
            (.asr, todayPT.asr, todayPT.maghrib),
            (.maghrib, todayPT.maghrib, todayPT.maghrib),
            (.isha, todayPT.isha, todayPT.maghrib),
            (.fajr, tomorrowPT.fajr, tomorrowPT.maghrib),
            (.dhuhr, tomorrowPT.dhuhr, tomorrowPT.maghrib),
            (.asr, tomorrowPT.asr, tomorrowPT.maghrib),
            (.maghrib, tomorrowPT.maghrib, tomorrowPT.maghrib),
            (.isha, tomorrowPT.isha, tomorrowPT.maghrib),
        ]

        for (kind, date, maghrib) in prayers {
            guard date > now else { continue }
            if let req = makeRequest(kind: kind, fireDate: date, maghribForDay: maghrib) {
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

    private static func makeRequest(kind: PrayerKind, fireDate: Date, maghribForDay: Date) -> UNNotificationRequest? {
        let name: String
        switch kind {
        case .fajr: name = "Fajr"
        case .dhuhr: name = "Dhuhr"
        case .asr: name = "Asr"
        case .maghrib: name = "Maghrib"
        case .isha: name = "Isha"
        }

        let hijriDate = getIslamicDayHijriDate(now: fireDate, todayMaghrib: maghribForDay)
        let content = UNMutableNotificationContent()
        content.title = formatHijriTitle(hijri: hijriDate)
        content.body = "\(name).\n\"\(bodyAyah)\" [4:103]"
        content.sound = .default
        content.categoryIdentifier = Self.categoryId

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = "\(Self.identifierPrefix)\(kind.rawValue)_\(comps.year ?? 0)_\(comps.month ?? 0)_\(comps.day ?? 0)_\(comps.hour ?? 0)_\(comps.minute ?? 0)"
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    /// For unit testing notification content format only.
    static func formatContentForTesting(prayerName: String, fireDate: Date, maghrib: Date) -> (title: String, body: String) {
        let hijriDate = getIslamicDayHijriDate(now: fireDate, todayMaghrib: maghrib)
        let title = "\(hijriDate.day) \(hijriDate.monthNameEn) \(hijriDate.year)"
        let body = "\(prayerName).\n\"\(bodyAyah)\" [4:103]"
        return (title, body)
    }
}
