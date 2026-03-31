import Foundation

/// Current phase and next transition.
/// Mirrors packages/core/src/phases.ts

private let PHASE_BOUNDARIES: [(IslamicPhaseId, KeyPath<ComputedTimeline, Date>, KeyPath<ComputedTimeline, Date>)] = [
    (.maghrib_to_isha, \.lastMaghrib, \.isha),
    (.isha_to_last_third, \.isha, \.lastThirdStart),
    (.last_third_to_fajr, \.lastThirdStart, \.fajr),
    (.fajr_to_sunrise, \.fajr, \.sunrise),
    (.sunrise_to_dhuhr, \.sunrise, \.dhuhr),
    (.dhuhr_to_asr, \.dhuhr, \.asr),
    (.asr_to_maghrib, \.asr, \.nextMaghrib),
]

func getCurrentPhase(now: Date, timeline: ComputedTimeline) -> IslamicPhaseId {
    let t = now.timeIntervalSince1970
    for (id, startKey, endKey) in PHASE_BOUNDARIES {
        let start = timeline[keyPath: startKey].timeIntervalSince1970
        let end = timeline[keyPath: endKey].timeIntervalSince1970
        if t >= start && t < end {
            return id
        }
    }
    return .asr_to_maghrib
}

func getNextTransition(now: Date, timeline: ComputedTimeline) -> (id: String, at: Date) {
    let ordered: [(String, Date)] = [
        ("isha", timeline.isha),
        ("last_third_start", timeline.lastThirdStart),
        ("fajr", timeline.fajr),
        ("sunrise", timeline.sunrise),
        ("duha_start", timeline.duhaStart),
        ("duha_end", timeline.duhaEnd),
        ("dhuhr", timeline.dhuhr),
        ("asr", timeline.asr),
        ("maghrib", timeline.nextMaghrib),
    ]
    let t = now.timeIntervalSince1970
    for (id, at) in ordered {
        if at.timeIntervalSince1970 > t {
            return (id, at)
        }
    }
    return ("maghrib", timeline.nextMaghrib)
}

/// Target for countdown: always the start of the next sector.
/// Mirrors packages/core/src/countdown.ts getCountdownTarget
func getCountdownTarget(now: Date, timeline: ComputedTimeline) -> Date {
    let phase = getCurrentPhase(now: now, timeline: timeline)
    let sub = getSunriseToDhuhrSubPeriod(now: now, duhaStart: timeline.duhaStart, dhuhr: timeline.dhuhr)

    switch phase {
    case .maghrib_to_isha:
        return timeline.isha
    case .isha_to_last_third, .last_third_to_fajr:
        return timeline.fajr
    case .fajr_to_sunrise:
        return timeline.sunrise
    case .sunrise_to_dhuhr:
        switch sub {
        case .sunrise: return timeline.duhaStart
        case .duha: return timeline.duhaEnd
        case .midday: return timeline.dhuhr
        }
    case .dhuhr_to_asr:
        return timeline.asr
    case .asr_to_maghrib:
        return timeline.nextMaghrib
    }
}
