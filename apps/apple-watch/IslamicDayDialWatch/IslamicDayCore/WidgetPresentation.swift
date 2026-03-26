import Foundation

struct WidgetSnapshotPayload {
    let snapshot: ComputedIslamicDay?
    let countdownTarget: Date?
    let locationTitle: String
}

struct CompactHijriLabel {
    let primary: String
    let secondary: String
    let isEid: Bool
}

func makeWidgetSnapshotPayload(date: Date, prefersPreviewData: Bool) async -> WidgetSnapshotPayload {
    let location: Location
    let title: String

    if prefersPreviewData {
        location = .mecca
        title = "Mecca"
    } else {
        let resolved = await resolveLocation()
        location = resolved
        title = TimeZone.current.identifier.replacingOccurrences(of: "_", with: " ")
    }

    guard let snapshot = computeIslamicDaySnapshot(now: date, location: location) else {
        return WidgetSnapshotPayload(snapshot: nil, countdownTarget: nil, locationTitle: title)
    }

    return WidgetSnapshotPayload(
        snapshot: snapshot,
        countdownTarget: getCountdownTarget(now: date, timeline: snapshot.timeline),
        locationTitle: title
    )
}

func nextWidgetRefreshDate(from date: Date, snapshot: ComputedIslamicDay?) -> Date {
    let calendar = Calendar.current
    let nextMinute = calendar.nextDate(
        after: date,
        matching: DateComponents(second: 0),
        matchingPolicy: .nextTime
    ) ?? date.addingTimeInterval(60)

    guard let snapshot else {
        return nextMinute
    }

    let nextTransition = getNextTransition(now: date, timeline: snapshot.timeline).at.addingTimeInterval(0.25)
    return min(nextMinute, nextTransition)
}

func nextHijriDateRefreshDate(from date: Date, snapshot: ComputedIslamicDay?) -> Date {
    guard let snapshot else {
        return date.addingTimeInterval(60 * 60)
    }

    return snapshot.timeline.nextMaghrib.addingTimeInterval(0.25)
}

func widgetCurrentPhase(snapshot: ComputedIslamicDay, now: Date) -> IslamicPhaseId {
    getCurrentPhase(now: now, timeline: snapshot.timeline)
}

func widgetPeriodLabel(snapshot: ComputedIslamicDay, now: Date) -> String {
    getSectorDisplayName(
        now: now,
        currentPhase: widgetCurrentPhase(snapshot: snapshot, now: now),
        timeline: (duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr)
    )
}

func widgetCountdownTarget(snapshot: ComputedIslamicDay, now: Date) -> Date {
    getCountdownTarget(now: now, timeline: snapshot.timeline)
}

func widgetCountdownMs(snapshot: ComputedIslamicDay, now: Date) -> Int64 {
    Int64(max(0, widgetCountdownTarget(snapshot: snapshot, now: now).timeIntervalSince(now) * 1000))
}

func widgetCountdownText(snapshot: ComputedIslamicDay, now: Date) -> String {
    formatCountdown(widgetCountdownMs(snapshot: snapshot, now: now))
}

func compactHijriLabel(hijriDate: HijriDate) -> CompactHijriLabel {
    let parts = formatHijriDateParts(hijriDate)
    return CompactHijriLabel(
        primary: parts.dayMonth.uppercased(),
        secondary: parts.year,
        isEid: parts.isEid
    )
}

func compactHijriCenterText(hijriDate: HijriDate) -> String {
    let label = compactHijriLabel(hijriDate: hijriDate)
    return label.isEid ? "EID" : String(hijriDate.day)
}

func watchInlineLabel(snapshot: ComputedIslamicDay, now: Date) -> String {
    widgetPeriodLabel(snapshot: snapshot, now: now).uppercased()
}
