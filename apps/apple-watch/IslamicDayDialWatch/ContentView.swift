import SwiftUI

private let WATCH_DIAL_SIZE_SCALE: CGFloat = 1.28
private let WATCH_CURRENT_PERIOD_FONT_RATIO: CGFloat = 20 / 420
private let WATCH_HIJRI_COMPACT_FONT_RATIO: CGFloat = 15 / 420
private let WATCH_HIJRI_REGULAR_FONT_RATIO: CGFloat = 18 / 420
private let WATCH_HIJRI_YEAR_FONT_RATIO: CGFloat = 14 / 420

struct ContentView: View {
    @State private var snapshot: ComputedIslamicDay?
    @State private var now = Date()
    @State private var location: Location = .mecca
    @State private var hasTrackedVisit = false

    var body: some View {
        Group {
            if let snap = snapshot {
                GeometryReader { geo in
                    // Match iPhone dial proportions: slightly oversized ring clipped by screen edges.
                    let dialSize = min(geo.size.width, geo.size.height) * WATCH_DIAL_SIZE_SCALE
                    // Web: center-info height 212px = hole diameter; positions 55, 100, 165 from hole top
                    let holeTop = dialSize * (0.5 - 0.25125)
                    let holeHeight = dialSize * 0.5025
                    let sectorTop = holeTop + 55 * (holeHeight / 212)
                    let dateTop = holeTop + 100 * (holeHeight / 212)
                    let centerOffsetY = dialSize * (-10 / 420)  // Web: -10px nudge
                    ZStack {
                        RingView(snapshot: snap, now: now)
                            .frame(width: dialSize, height: dialSize)
                        ZStack(alignment: .top) {
                            Color.clear
                            currentPeriodView(snapshot: snap, now: now, dialSize: dialSize)
                                .frame(maxWidth: .infinity)
                                .offset(y: sectorTop)
                            HijriDateLabels(hijriDate: snap.hijriDate, dialSize: dialSize)
                                .frame(maxWidth: .infinity)
                                .offset(y: dateTop)
                        }
                        .frame(width: dialSize, height: dialSize)
                        .offset(y: centerOffsetY)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .task {
            let geo = await resolveGeoResult()
            location = geo.location
            if !hasTrackedVisit {
                hasTrackedVisit = true
                await trackVisit(geo: geo, platform: "watchos", surface: "watch_app")
            }
            while !Task.isCancelled {
                let currentNow = Date()
                now = currentNow
                snapshot = computeIslamicDaySnapshot(now: currentNow, location: location)
                try? await Task.sleep(for: .seconds(secondsUntilNextRefresh(from: currentNow, snapshot: snapshot)))
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
            .font(.system(size: dialSize * WATCH_CURRENT_PERIOD_FONT_RATIO, weight: .light))
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
        return currentPhase(snapshot: snap, now: now) == .last_third_to_fajr
            ? Color(red: 0.22, green: 0.74, blue: 0.97)
            : Colors.coolLabel
    }

    private func currentPhase(snapshot snap: ComputedIslamicDay, now: Date) -> IslamicPhaseId {
        getCurrentPhase(now: now, timeline: snap.timeline)
    }
}

private struct IshaShadowModifier: ViewModifier {
    let phase: IslamicPhaseId
    func body(content: Content) -> some View {
        if phase == .last_third_to_fajr {
            content.shadow(color: Color(red: 0.22, green: 0.74, blue: 0.97).opacity(0.7), radius: 4)
        } else {
            content
        }
    }
}

private let COMPACT_MONTH_NAMES: Set<String> = [
    "rabi al-awwal", "rabi al-thani", "jumada al-ula", "jumada al-thani"
]

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

private struct HijriDateLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)
    private let useCompactDayMonth: Bool
    private let dialSize: CGFloat

    init(hijriDate: HijriDate, dialSize: CGFloat) {
        self.parts = formatHijriDateParts(hijriDate)
        self.useCompactDayMonth = COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
        self.dialSize = dialSize
    }

    @State private var pulseBright = false

    var body: some View {
        VStack(spacing: 2) {
            Text(parts.dayMonth.uppercased())
                .font(.system(size: dialSize * (useCompactDayMonth ? WATCH_HIJRI_COMPACT_FONT_RATIO : WATCH_HIJRI_REGULAR_FONT_RATIO), weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGold)
                .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
            Text(parts.year)
                .font(.system(size: dialSize * WATCH_HIJRI_YEAR_FONT_RATIO, weight: .semibold))
                .foregroundColor(Colors.secondaryGold)
                .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
        }
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
