import Foundation

/// Formatting for display. Mirrors packages/core/src/formatting.ts

func formatHijriDateParts(_ date: HijriDate) -> (dayMonth: String, year: String, isEid: Bool) {
    if date.monthNumber == 10 && date.day == 1 {
        return ("EID AL-FITR", String(date.year), true)
    }
    if date.monthNumber == 12 && date.day == 10 {
        return ("EID AL-ADHA", String(date.year), true)
    }
    return ("\(date.day) \(date.monthNameEn)", String(date.year), false)
}

let PERIOD_NAMES: [IslamicPhaseId: String] = [
    .maghrib_to_isha: "Maghrib",
    .isha_to_midnight: "Isha",
    .midnight_to_last_third: "Isha 1/2",
    .last_third_to_fajr: "Isha 2/3",
    .fajr_to_sunrise: "Fajr",
    .sunrise_to_dhuhr: "Duha",
    .dhuhr_to_asr: "Dhuhr",
    .asr_to_maghrib: "Asr",
]

func formatCurrentPeriod(_ phase: IslamicPhaseId) -> String {
    PERIOD_NAMES[phase] ?? "Unknown"
}
