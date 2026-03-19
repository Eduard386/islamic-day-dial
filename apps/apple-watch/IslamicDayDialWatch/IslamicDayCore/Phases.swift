import Foundation

/// Current phase and next transition.
/// Mirrors packages/core/src/phases.ts

private let PHASE_BOUNDARIES: [(IslamicPhaseId, KeyPath<ComputedTimeline, Date>, KeyPath<ComputedTimeline, Date>)] = [
    (.maghrib_to_isha, \.lastMaghrib, \.isha),
    (.isha_to_midnight, \.isha, \.lastThirdStart),
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
        ("islamic_midnight", timeline.islamicMidnight),
        ("last_third_start", timeline.lastThirdStart),
        ("fajr", timeline.fajr),
        ("sunrise", timeline.sunrise),
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

/// DUHA label visibility: hidden first 20 min and last 5 min of sunrise_to_dhuhr
private let DUHA_LABEL_FIRST_SEC: TimeInterval = 20 * 60

/// Target for countdown based on current phase and DUHA visibility.
/// Mirrors packages/core/src/countdown.ts getCountdownTarget
func getCountdownTarget(now: Date, timeline: ComputedTimeline) -> Date {
    let t = now.timeIntervalSince1970
    let phase = getCurrentPhase(now: now, timeline: timeline)
    let duhaLabelAt = timeline.sunrise.timeIntervalSince1970 + DUHA_LABEL_FIRST_SEC

    switch phase {
    case .maghrib_to_isha:
        return timeline.isha
    case .isha_to_midnight, .last_third_to_fajr:
        return timeline.fajr
    case .fajr_to_sunrise:
        return Date(timeIntervalSince1970: duhaLabelAt)
    case .sunrise_to_dhuhr:
        return t < duhaLabelAt ? Date(timeIntervalSince1970: duhaLabelAt) : timeline.dhuhr
    case .dhuhr_to_asr:
        return timeline.asr
    case .asr_to_maghrib:
        return timeline.nextMaghrib
    }
}
