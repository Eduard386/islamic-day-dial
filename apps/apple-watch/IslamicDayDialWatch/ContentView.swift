import SwiftUI

private let WATCH_RING_OUTER_DIAMETER_RATIO: CGFloat = 0.6645
private let WATCH_DIAL_EDGE_FIT: CGFloat = 0.98
private let WATCH_DIAL_VERTICAL_OFFSET_RATIO: CGFloat = 8 / 420
private let WATCH_CURRENT_PERIOD_FONT_RATIO: CGFloat = 20 / 420
private let WATCH_HIJRI_COMPACT_FONT_RATIO: CGFloat = 25 / 420
private let WATCH_HIJRI_COMPACT_EMPHASIZED_FONT_RATIO: CGFloat = 26.5 / 420
private let WATCH_HIJRI_REGULAR_FONT_RATIO: CGFloat = 22 / 420
private let WATCH_HIJRI_YEAR_FONT_RATIO: CGFloat = 19 / 420

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var snapshot: ComputedIslamicDay?
    @State private var now = Date()
    @State private var location: Location = .mecca
    @State private var hasTrackedVisit = false
    @State private var hasResolvedLocation = false
    #if DEBUG
    @State private var debugNow: Date?
    #endif

    private var effectiveNow: Date {
        #if DEBUG
        return debugNow ?? now
        #else
        return now
        #endif
    }

    var body: some View {
        Group {
            if let snap = snapshot {
                GeometryReader { geo in
                    // Solve from the actual ring geometry so the outer edge of the ring reaches the watch edges.
                    let dialOuterDiameter = min(geo.size.width, geo.size.height) * WATCH_DIAL_EDGE_FIT
                    let dialSize = dialOuterDiameter / WATCH_RING_OUTER_DIAMETER_RATIO
                    // Web: center-info height 212px = hole diameter; positions 55, 100, 165 from hole top
                    let holeTop = dialSize * (0.5 - 0.25125)
                    let holeHeight = dialSize * 0.5025
                    let sectorTop = holeTop + 55 * (holeHeight / 212)
                    let dateTop = holeTop + 100 * (holeHeight / 212)
                    let yearTop = dateTop + (dateTop - sectorTop)
                    let centerOffsetY = dialSize * (-10 / 420)  // Web: -10px nudge
                    let dialVerticalOffset = dialSize * WATCH_DIAL_VERTICAL_OFFSET_RATIO
                    ZStack {
                        RingView(snapshot: snap, now: effectiveNow, renderVariant: .phone)
                            .frame(width: dialSize, height: dialSize)
                            .id(ringRenderIdentity(snapshot: snap, now: effectiveNow, dialSize: dialSize))
                        ZStack(alignment: .top) {
                            Color.clear
                            currentPeriodView(snapshot: snap, now: effectiveNow, dialSize: dialSize)
                                .frame(maxWidth: .infinity)
                                .offset(y: sectorTop)
                            HijriDayMonthLabel(
                                hijriDate: snap.hijriDate,
                                dialSize: dialSize,
                                maxTextWidth: holeHeight * 0.72
                            )
                                .frame(maxWidth: .infinity)
                                .offset(y: dateTop)
                            HijriYearLabel(
                                hijriDate: snap.hijriDate,
                                dialSize: dialSize,
                                maxTextWidth: holeHeight * 0.72
                            )
                                .frame(maxWidth: .infinity)
                                .offset(y: yearTop)
                        }
                        .frame(width: dialSize, height: dialSize)
                        .offset(y: centerOffsetY)
                    }
                    .offset(y: dialVerticalOffset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    #if DEBUG
                    .overlay(alignment: .topLeading) {
                        WatchDebugControls(
                            showsReset: debugNow != nil,
                            onNextMonth: advanceDebugMonth,
                            onForward15Minutes: advanceDebugQuarterHour,
                            onRandomNotification: sendRandomDebugNotification,
                            onReset: resetDebugTime
                        )
                        .padding(.top, 10)
                        .padding(.leading, 8)
                    }
                    #endif
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .task {
            let geo = await resolveGeoResult()
            location = geo.location
            hasResolvedLocation = true
            await PrayerNotificationScheduler.requestAndSchedule(location: geo.location)
            if !hasTrackedVisit {
                hasTrackedVisit = true
                await trackVisit(geo: geo, platform: "watchos", surface: "watch_app")
            }
            while !Task.isCancelled {
                let currentNow = Date()
                now = currentNow
                let renderNow = debugNow ?? currentNow
                snapshot = computeIslamicDaySnapshot(now: renderNow, location: location)
                let refreshNow = renderNow
                try? await Task.sleep(for: .seconds(secondsUntilNextRefresh(from: refreshNow, snapshot: snapshot)))
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, hasResolvedLocation else { return }
            Task {
                await PrayerNotificationScheduler.requestAndSchedule(location: location)
            }
        }
    }

    private func secondsUntilNextRefresh(from date: Date, snapshot: ComputedIslamicDay?) -> Double {
        let calendar = Calendar.current
        let nextMinute = calendar.nextDate(
            after: date,
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(60)
        let nextTransition = snapshot.map { getNextTransition(now: date, timeline: $0.timeline).at } ?? nextMinute
        let refreshAt = min(nextMinute, nextTransition)
        return max(1, refreshAt.timeIntervalSince(date) + 0.25)
    }

    @ViewBuilder
    private func currentPeriodView(snapshot snap: ComputedIslamicDay, now: Date, dialSize: CGFloat) -> some View {
        let phase = currentPhase(snapshot: snap, now: now)
        Text(periodLabel(snapshot: snap, now: now).uppercased())
            .font(.system(size: dialSize * WATCH_CURRENT_PERIOD_FONT_RATIO, weight: .regular))
            .foregroundColor(periodColor(snapshot: snap, now: now))
            .modifier(IshaShadowModifier(phase: phase))
    }

    private func periodLabel(snapshot snap: ComputedIslamicDay, now: Date) -> String {
        getSectorDisplayName(
            now: now,
            currentPhase: currentPhase(snapshot: snap, now: now),
            timeline: (duhaStart: snap.timeline.duhaStart, dhuhr: snap.timeline.dhuhr)
        )
    }

    private func periodColor(snapshot snap: ComputedIslamicDay, now: Date) -> Color {
        if periodLabel(snapshot: snap, now: now) == "Jumu'ah" {
            return Color(red: 0.06, green: 0.73, blue: 0.51)
        }
        return Colors.neutralHeadingWhite
    }

    private func currentPhase(snapshot snap: ComputedIslamicDay, now: Date) -> IslamicPhaseId {
        getCurrentPhase(now: now, timeline: snap.timeline)
    }

    private func ringRenderIdentity(snapshot snap: ComputedIslamicDay, now: Date, dialSize: CGFloat) -> String {
        let minuteBucket = Int(now.timeIntervalSince1970 / 60)
        let phase = currentPhase(snapshot: snap, now: now)
        return "\(phase.rawValue)-\(minuteBucket)-\(Int(dialSize.rounded()))"
    }

    #if DEBUG
    private func advanceDebugMonth() {
        let updatedNow = addIslamicMonths(1, to: debugNow ?? now)
        debugNow = updatedNow
        snapshot = computeIslamicDaySnapshot(now: updatedNow, location: location)
    }

    private func advanceDebugQuarterHour() {
        let updatedNow = (debugNow ?? now).addingTimeInterval(15 * 60)
        debugNow = updatedNow
        snapshot = computeIslamicDaySnapshot(now: updatedNow, location: location)
    }

    private func resetDebugTime() {
        debugNow = nil
        snapshot = computeIslamicDaySnapshot(now: now, location: location)
    }

    private func sendRandomDebugNotification() {
        Task {
            await PrayerNotificationScheduler.sendRandomDebugNotification(date: effectiveNow, location: location)
        }
    }
    #endif
}

#if DEBUG
private func addIslamicMonths(_ months: Int, to date: Date) -> Date {
    var calendar = Calendar(identifier: .islamicUmmAlQura)
    calendar.timeZone = .current
    return calendar.date(byAdding: .month, value: months, to: date) ?? date
}

private struct WatchDebugControls: View {
    let showsReset: Bool
    let onNextMonth: () -> Void
    let onForward15Minutes: () -> Void
    let onRandomNotification: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            debugButton("M+", action: onNextMonth)
            debugButton("+15", action: onForward15Minutes)
            debugButton("Push", action: onRandomNotification)
            if showsReset {
                debugButton("Now", action: onReset)
            }
        }
    }

    private func debugButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.62), in: Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                )
        }
        .buttonStyle(.plain)
    }
}

#endif

private struct IshaShadowModifier: ViewModifier {
    let phase: IslamicPhaseId
    func body(content: Content) -> some View {
        content
    }
}

private let COMPACT_MONTH_NAMES: Set<String> = [
    "rabi al-awwal", "rabi al-thani", "jumada al-ula", "jumada al-thani"
]

private let EMPHASIZED_COMPACT_MONTH_NAMES: Set<String> = [
    "rabi al-awwal", "jumada al-thani"
]

private struct WatchHijriLabelParts {
    let dayMonth: String
    let year: String
    let isEid: Bool
    let useCompactDayMonth: Bool
    let emphasizedCompactMonth: Bool
}

private func getWatchHijriLabelParts(_ hijriDate: HijriDate) -> WatchHijriLabelParts {
    let parts = formatHijriDateParts(hijriDate)
    return WatchHijriLabelParts(
        dayMonth: parts.dayMonth,
        year: parts.year,
        isEid: parts.isEid,
        useCompactDayMonth: COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased()),
        emphasizedCompactMonth: EMPHASIZED_COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
    )
}

private struct HijriEngravedLabelsModifier: ViewModifier {
    let isEid: Bool

    func body(content: Content) -> some View {
        let hi = isEid ? Color.white.opacity(0.32) : Color.white.opacity(0.24)
        let lo = isEid ? Color.black.opacity(0.42) : Color.black.opacity(0.52)
        content
            .shadow(color: hi, radius: 0, x: 0, y: -0.5)
            .shadow(color: lo, radius: 0, x: 0, y: 0.9)
            .shadow(color: lo.opacity(0.38), radius: 1.2, x: 0, y: 1.3)
    }
}

private struct HijriDayMonthLabel: View {
    private let parts: WatchHijriLabelParts
    private let dialSize: CGFloat
    private let maxTextWidth: CGFloat

    init(hijriDate: HijriDate, dialSize: CGFloat, maxTextWidth: CGFloat) {
        self.parts = getWatchHijriLabelParts(hijriDate)
        self.dialSize = dialSize
        self.maxTextWidth = maxTextWidth
    }

    @State private var pulseBright = false

    var body: some View {
        let dayMonthFontRatio: CGFloat = {
            if parts.emphasizedCompactMonth { return WATCH_HIJRI_COMPACT_EMPHASIZED_FONT_RATIO }
            if parts.useCompactDayMonth { return WATCH_HIJRI_COMPACT_FONT_RATIO }
            return WATCH_HIJRI_REGULAR_FONT_RATIO
        }()

        Text(parts.dayMonth.uppercased())
            .font(.system(size: dialSize * dayMonthFontRatio, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.58)
            .allowsTightening(true)
            .frame(width: maxTextWidth)
            .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGoldBright)
            .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
            .brightness(pulseBright ? 0.05 : -0.025)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    pulseBright = true
                }
            }
    }
}

private struct HijriYearLabel: View {
    private let parts: WatchHijriLabelParts
    private let dialSize: CGFloat
    private let maxTextWidth: CGFloat

    init(hijriDate: HijriDate, dialSize: CGFloat, maxTextWidth: CGFloat) {
        self.parts = getWatchHijriLabelParts(hijriDate)
        self.dialSize = dialSize
        self.maxTextWidth = maxTextWidth
    }

    @State private var pulseBright = false

    var body: some View {
        Text(parts.year)
            .font(.system(size: dialSize * WATCH_HIJRI_YEAR_FONT_RATIO, weight: .semibold))
            .frame(width: maxTextWidth)
            .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.secondaryGoldBright)
            .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
        .brightness(pulseBright ? 0.05 : -0.025)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseBright = true
            }
        }
    }
}

#Preview {
    ContentView()
}
