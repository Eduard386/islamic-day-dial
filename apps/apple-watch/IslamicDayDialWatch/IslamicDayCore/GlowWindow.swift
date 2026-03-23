import Foundation

/// Jumu'ah (Friday): glow shown only when marker is in DUHA, MIDDAY or DHUHR.
/// Mirrors packages/core/src/glow-window.ts (source of truth).
/// Not during SUNRISE, Fajr, night (Maghrib…Last 3rd), Asr→Maghrib.
/// Mirrors apps/web-dashboard/src/lib/glow-window.ts isJumuahGlowWindow
func isJumuahGlowWindow(now: Date, timeline: ComputedTimeline, currentPhase: IslamicPhaseId) -> Bool {
    let isFriday = Calendar.current.component(.weekday, from: now) == 6
    if !isFriday { return false }
    if currentPhase == .dhuhr_to_asr { return true }
    if currentPhase == .sunrise_to_dhuhr {
        let sub = getSunriseToDhuhrSubPeriod(now: now, duhaStart: timeline.duhaStart, dhuhr: timeline.dhuhr)
        return sub == .duha || sub == .midday
    }
    return false
}
