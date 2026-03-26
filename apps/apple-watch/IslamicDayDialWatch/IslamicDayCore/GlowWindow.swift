import Foundation

private let jumuahGlowMinStrength = 0.3

/// Jumu'ah (Friday): glow shown from the start of Duha until the end of Dhuhr.
/// It starts weak at Duha and reaches full strength by the end of Dhuhr.
/// Mirrors packages/core/src/glow-window.ts (source of truth).
func isJumuahGlowWindow(now: Date, timeline: ComputedTimeline, currentPhase: IslamicPhaseId) -> Bool {
    getJumuahGlowStrength(now: now, timeline: timeline, currentPhase: currentPhase) > 0
}

func getJumuahGlowStrength(now: Date, timeline: ComputedTimeline, currentPhase: IslamicPhaseId) -> Double {
    let isFriday = Calendar.current.component(.weekday, from: now) == 6
    if !isFriday { return 0 }
    if currentPhase != .sunrise_to_dhuhr && currentPhase != .dhuhr_to_asr { return 0 }

    let start = timeline.duhaStart.timeIntervalSince1970
    let end = timeline.asr.timeIntervalSince1970
    let current = now.timeIntervalSince1970

    if current < start || current >= end { return 0 }
    if end <= start { return 1 }

    let progress = max(0, min(1, (current - start) / (end - start)))
    return jumuahGlowMinStrength + (1 - jumuahGlowMinStrength) * progress
}
