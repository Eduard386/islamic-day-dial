import Foundation

private let jumuahGlowMinStrength = 0.3

/// Jumu'ah (Friday): glow shown from the start of Duha until the end of Dhuhr.
/// It starts weak at Duha and reaches full strength by the end of Dhuhr.
/// Mirrors packages/core/src/glow-window.ts (source of truth).
func isJumuahGlowWindow(now: Date, timeline: ComputedTimeline, currentPhase: IslamicPhaseId) -> Bool {
    getJumuahGlowStrength(now: now, timeline: timeline, currentPhase: currentPhase) > 0
}

func getJumuahGlowStrength(now: Date, timeline: ComputedTimeline, currentPhase: IslamicPhaseId) -> Double {
    let progress = getJumuahGlowProgress(now: now, timeline: timeline, currentPhase: currentPhase)
    guard progress > 0 else { return 0 }
    return jumuahGlowMinStrength + (1 - jumuahGlowMinStrength) * progress
}

func getJumuahGlowProgress(now: Date, timeline: ComputedTimeline, currentPhase: IslamicPhaseId) -> Double {
    let isFriday = Calendar.current.component(.weekday, from: now) == 6
    if !isFriday { return 0 }
    if currentPhase != .sunrise_to_dhuhr && currentPhase != .dhuhr_to_asr { return 0 }

    let start = timeline.duhaStart.timeIntervalSince1970
    let end = timeline.asr.timeIntervalSince1970
    let current = now.timeIntervalSince1970

    if current <= start || current >= end { return 0 }
    if end <= start { return 1 }

    return max(0, min(1, (current - start) / (end - start)))
}

func getJumuahGlowSweepAngles(
    now: Date,
    timeline: ComputedTimeline,
    currentPhase: IslamicPhaseId,
    duhaStartAngleDeg: Double,
    dhuhrAngleDeg: Double,
    asrAngleDeg: Double
) -> (duhaToDhuhrEndAngleDeg: Double?, dhuhrToAsrEndAngleDeg: Double?) {
    let progress = getJumuahGlowProgress(now: now, timeline: timeline, currentPhase: currentPhase)
    guard progress > 0 else { return (nil, nil) }

    let totalSpan = asrAngleDeg - duhaStartAngleDeg
    guard totalSpan > 0 else { return (nil, nil) }

    let sweepEnd = duhaStartAngleDeg + totalSpan * progress
    return (
        min(sweepEnd, dhuhrAngleDeg),
        sweepEnd > dhuhrAngleDeg ? min(sweepEnd, asrAngleDeg) : nil
    )
}
