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
    .isha_to_last_third: "Isha",
    .last_third_to_fajr: "Isha",
    .fajr_to_sunrise: "Fajr",
    .sunrise_to_dhuhr: "Duha",
    .dhuhr_to_asr: "Dhuhr",
    .asr_to_maghrib: "Asr",
]

func formatCurrentPeriod(_ phase: IslamicPhaseId) -> String {
    PERIOD_NAMES[phase] ?? "Unknown"
}

/// Display name for current sector: Jumu'ah on Fri (Duha/Midday/Dhuhr), Sunrise/Duha/Midday, or default phase label.
/// Mirrors packages/core getSectorDisplayName
func getSectorDisplayName(now: Date, currentPhase: IslamicPhaseId, timeline: (duhaStart: Date, dhuhr: Date)) -> String {
    let isFriday = Calendar.current.component(.weekday, from: now) == 6
    if currentPhase == .dhuhr_to_asr && isFriday { return "Jumu'ah" }
    if currentPhase != .sunrise_to_dhuhr { return formatCurrentPeriod(currentPhase) }
    let sub = getSunriseToDhuhrSubPeriod(now: now, duhaStart: timeline.duhaStart, dhuhr: timeline.dhuhr)
    if sub == .sunrise { return "Sunrise" }
    if isFriday && (sub == .duha || sub == .midday) { return "Jumu'ah" }
    return sub == .duha ? "Duha" : "Midday"
}

/// Sub-period within sunrise_to_dhuhr: SUNRISE (until Duha start), DUHA (until 5 min before Dhuhr), MIDDAY (last 5 min)
/// Mirrors packages/core getSunriseToDhuhrSubPeriod
enum SunriseToDhuhrSubPeriod {
    case sunrise  // until dynamic Duha start (sun reaches 4° altitude)
    case duha     // from Duha start until 5 min before Dhuhr
    case midday   // last 5 min before Dhuhr
}

func getSunriseToDhuhrSubPeriod(now: Date, duhaStart: Date, dhuhr: Date) -> SunriseToDhuhrSubPeriod {
    let t = now.timeIntervalSince1970
    let duhaEnd = dhuhr.timeIntervalSince1970 - 5 * 60
    if t < duhaStart.timeIntervalSince1970 { return .sunrise }
    if t >= duhaEnd { return .midday }
    return .duha
}

/// Format countdown ms as "-HH:MM" (no seconds). Mirrors packages/core formatCountdown.
func formatCountdown(_ ms: Int64) -> String {
    if ms <= 0 { return "-00:00" }
    let totalSeconds = Int(ms / 1000)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    return "-" + String(format: "%02d:%02d", hours, minutes)
}
