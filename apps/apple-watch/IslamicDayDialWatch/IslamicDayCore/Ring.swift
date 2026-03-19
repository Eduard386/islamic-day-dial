import Foundation

/// Ring geometry: progress, markers, segments.
/// Mirrors packages/core/src/ring.ts

private let MARKER_DEFS: [(String, KeyPath<ComputedTimeline, Date>, RingMarkerKind)] = [
    ("maghrib", \.lastMaghrib, .primary),
    ("isha", \.isha, .primary),
    ("last_third_start", \.lastThirdStart, .secondary),
    ("fajr", \.fajr, .primary),
    ("sunrise", \.sunrise, .primary),
    ("dhuhr", \.dhuhr, .primary),
    ("asr", \.asr, .primary),
]

private let SEGMENT_BOUNDARIES: [(IslamicPhaseId, KeyPath<ComputedTimeline, Date>, KeyPath<ComputedTimeline, Date>)] = [
    (.maghrib_to_isha, \.lastMaghrib, \.isha),
    (.isha_to_midnight, \.isha, \.lastThirdStart),
    (.last_third_to_fajr, \.lastThirdStart, \.fajr),
    (.fajr_to_sunrise, \.fajr, \.sunrise),
    (.sunrise_to_dhuhr, \.sunrise, \.dhuhr),
    (.dhuhr_to_asr, \.dhuhr, \.asr),
    (.asr_to_maghrib, \.asr, \.nextMaghrib),
]

func getIslamicDayProgress(now: Date, lastMaghrib: Date, nextMaghrib: Date) -> Double {
    let total = nextMaghrib.timeIntervalSince(lastMaghrib)
    if total <= 0 { return 0 }
    let elapsed = now.timeIntervalSince(lastMaghrib)
    return min(1, max(0, elapsed / total))
}

func timestampToAngle(timestamp: Date, lastMaghrib: Date, nextMaghrib: Date) -> Double {
    return getIslamicDayProgress(now: timestamp, lastMaghrib: lastMaghrib, nextMaghrib: nextMaghrib) * 360
}

func getMarkers(timeline: ComputedTimeline) -> [RingMarker] {
    MARKER_DEFS.map { (id, key, kind) in
        let ts = timeline[keyPath: key]
        return RingMarker(
            id: id,
            timestamp: ts,
            angleDeg: timestampToAngle(timestamp: ts, lastMaghrib: timeline.lastMaghrib, nextMaghrib: timeline.nextMaghrib),
            kind: kind
        )
    }
}

func getRingSegments(timeline: ComputedTimeline) -> [RingSegment] {
    SEGMENT_BOUNDARIES.map { (id, startKey, endKey) in
        let start = timeline[keyPath: startKey]
        let end = timeline[keyPath: endKey]
        return RingSegment(
            id: id,
            start: start,
            end: end,
            startAngleDeg: timestampToAngle(timestamp: start, lastMaghrib: timeline.lastMaghrib, nextMaghrib: timeline.nextMaghrib),
            endAngleDeg: timestampToAngle(timestamp: end, lastMaghrib: timeline.lastMaghrib, nextMaghrib: timeline.nextMaghrib)
        )
    }
}
