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
    .last_third_to_fajr: "Isha",
    .fajr_to_sunrise: "Fajr",
    .sunrise_to_dhuhr: "Duha",
    .dhuhr_to_asr: "Dhuhr",
    .asr_to_maghrib: "Asr",
]

func formatCurrentPeriod(_ phase: IslamicPhaseId) -> String {
    PERIOD_NAMES[phase] ?? "Unknown"
}

/// Format countdown ms as HH:mm:ss
func formatCountdown(_ ms: Int64) -> String {
    if ms <= 0 { return "00:00:00" }
    let totalSeconds = Int(ms / 1000)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}
