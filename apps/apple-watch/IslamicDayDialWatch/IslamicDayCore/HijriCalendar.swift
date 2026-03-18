import Foundation

/// Hijri (Umm al-Qura) calendar using Swift's built-in Calendar.
/// Mirrors packages/core/src/calendar.ts

private let MONTH_NAMES_EN = [
    "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
    "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Shaban",
    "Ramadan", "Shawwal", "Dhul Qadah", "Dhul Hijjah"
]

private var ummAlQuraCalendar: Calendar {
    var cal = Calendar(identifier: .islamicUmmAlQura)
    cal.timeZone = TimeZone.current
    return cal
}

/// Pure Gregorian → Hijri (Umm al-Qura) conversion.
func getHijriDate(gregorianDate: Date) -> HijriDate {
    let cal = ummAlQuraCalendar
    let components = cal.dateComponents([.day, .month, .year], from: gregorianDate)
    let day = components.day ?? 1
    let month = components.month ?? 1
    let year = components.year ?? 1
    let monthName = (1...12).contains(month) ? MONTH_NAMES_EN[month - 1] : "?"
    return HijriDate(
        day: day,
        monthNumber: month,
        monthNameEn: monthName,
        year: year
    )
}

/// Returns the Hijri date for the current Islamic day.
/// After Maghrib the Islamic date advances.
func getIslamicDayHijriDate(now: Date, todayMaghrib: Date) -> HijriDate {
    if now >= todayMaghrib {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return getHijriDate(gregorianDate: tomorrow)
    }
    return getHijriDate(gregorianDate: now)
}
