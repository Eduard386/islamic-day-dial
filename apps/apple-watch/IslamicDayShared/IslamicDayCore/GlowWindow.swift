import Foundation

private let jumuahGlowMinStrength = 0.3

private func isEidDay(_ hijriDate: HijriDate?) -> Bool {
    guard let hijriDate else { return false }
    return (hijriDate.monthNumber == 10 && hijriDate.day == 1)
        || (hijriDate.monthNumber == 12 && hijriDate.day == 10)
}

/// Special noon glow (Jumu'ah / Eid): shown from the start of Duha until the end of Dhuhr.
/// It starts weak at Duha and reaches full strength by the end of Dhuhr.
/// Mirrors packages/core/src/glow-window.ts (source of truth).
func isJumuahGlowWindow(
    now: Date,
    timeline: ComputedTimeline,
    currentPhase: IslamicPhaseId,
    hijriDate: HijriDate? = nil
) -> Bool {
    getJumuahGlowStrength(now: now, timeline: timeline, currentPhase: currentPhase, hijriDate: hijriDate) > 0
}

func getJumuahGlowStrength(
    now: Date,
    timeline: ComputedTimeline,
    currentPhase: IslamicPhaseId,
    hijriDate: HijriDate? = nil
) -> Double {
    let progress = getJumuahGlowProgress(
        now: now,
        timeline: timeline,
        currentPhase: currentPhase,
        hijriDate: hijriDate
    )
    guard progress > 0 else { return 0 }
    return jumuahGlowMinStrength + (1 - jumuahGlowMinStrength) * progress
}

func getJumuahGlowProgress(
    now: Date,
    timeline: ComputedTimeline,
    currentPhase: IslamicPhaseId,
    hijriDate: HijriDate? = nil
) -> Double {
    let isFriday = Calendar.current.component(.weekday, from: now) == 6
    if !isFriday && !isEidDay(hijriDate) { return 0 }
    if currentPhase != .sunrise_to_dhuhr && currentPhase != .dhuhr_to_asr { return 0 }

    let start = timeline.duhaStart.timeIntervalSince1970
    let end = timeline.asr.timeIntervalSince1970
    let current = now.timeIntervalSince1970

    if current < start || current >= end { return 0 }
    if end <= start { return 1 }

    return max(0, min(1, (current - start) / (end - start)))
}

func getJumuahGlowSweepAngles(
    now: Date,
    timeline: ComputedTimeline,
    currentPhase: IslamicPhaseId,
    duhaStartAngleDeg: Double,
    dhuhrAngleDeg: Double,
    asrAngleDeg: Double,
    hijriDate: HijriDate? = nil
) -> (duhaToDhuhrEndAngleDeg: Double?, dhuhrToAsrEndAngleDeg: Double?) {
    let progress = getJumuahGlowProgress(
        now: now,
        timeline: timeline,
        currentPhase: currentPhase,
        hijriDate: hijriDate
    )
    guard progress > 0 else { return (nil, nil) }

    let totalSpan = asrAngleDeg - duhaStartAngleDeg
    guard totalSpan > 0 else { return (nil, nil) }

    let sweepEnd = duhaStartAngleDeg + totalSpan * progress
    return (
        min(sweepEnd, dhuhrAngleDeg),
        sweepEnd > dhuhrAngleDeg ? min(sweepEnd, asrAngleDeg) : nil
    )
}
