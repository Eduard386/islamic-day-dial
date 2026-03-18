import Foundation

/// Current phase and next transition.
/// Mirrors packages/core/src/phases.ts

private let PHASE_BOUNDARIES: [(IslamicPhaseId, KeyPath<ComputedTimeline, Date>, KeyPath<ComputedTimeline, Date>)] = [
    (.maghrib_to_isha, \.lastMaghrib, \.isha),
    (.isha_to_midnight, \.isha, \.islamicMidnight),
    (.midnight_to_last_third, \.islamicMidnight, \.lastThirdStart),
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
