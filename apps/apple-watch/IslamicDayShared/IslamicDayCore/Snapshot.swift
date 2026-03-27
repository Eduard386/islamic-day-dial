import Foundation

/// Main orchestrator: computes full Islamic day snapshot.
/// Mirrors packages/core/src/snapshot.ts

public func computeIslamicDaySnapshot(
    now: Date = Date(),
    location: Location = .mecca,
    timezone: TimeZone = .current
) -> ComputedIslamicDay? {
    guard let todayPT = getPrayerTimesForDate(date: now, location: location),
          let yesterdayPT = getPrayerTimesForDate(date: addDays(date: now, days: -1), location: location),
          let tomorrowPT = getPrayerTimesForDate(date: addDays(date: now, days: 1), location: location) else {
        return nil
    }
    
    let timeline = buildTimeline(
        now: now,
        todayPT: todayPT,
        yesterdayPT: yesterdayPT,
        tomorrowPT: tomorrowPT,
        location: location
    )
    
    let hijriDate = getIslamicDayHijriDate(now: now, todayMaghrib: todayPT.maghrib)
    let currentPhase = getCurrentPhase(now: now, timeline: timeline)
    let (nextId, nextAt) = getNextTransition(now: now, timeline: timeline)
    let countdownTarget = getCountdownTarget(now: now, timeline: timeline)
    let countdownMs = Int64(max(0, countdownTarget.timeIntervalSince(now) * 1000))
    let progress = getIslamicDayProgress(now: now, lastMaghrib: timeline.lastMaghrib, nextMaghrib: timeline.nextMaghrib)
    let markers = getMarkers(timeline: timeline)
    let segments = getRingSegments(timeline: timeline)
    
    return ComputedIslamicDay(
        hijriDate: hijriDate,
        prayerTimes: todayPT,
        timeline: timeline,
        currentPhase: currentPhase,
        nextTransitionId: nextId,
        nextTransitionAt: nextAt,
        countdownMs: countdownMs,
        ringProgress: progress,
        ringMarkers: markers,
        ringSegments: segments
    )
}
