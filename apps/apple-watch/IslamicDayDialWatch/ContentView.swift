import SwiftUI

private let WATCH_RING_OUTER_DIAMETER_RATIO: CGFloat = 0.6645
private let WATCH_CURRENT_PERIOD_FONT_RATIO: CGFloat = 20 / 420
private let WATCH_HIJRI_COMPACT_FONT_RATIO: CGFloat = 25 / 420
private let WATCH_HIJRI_COMPACT_EMPHASIZED_FONT_RATIO: CGFloat = 26.5 / 420
private let WATCH_HIJRI_COMPACT_EXTRA_EMPHASIZED_FONT_RATIO: CGFloat = 27.5 / 420
private let WATCH_HIJRI_REGULAR_FONT_RATIO: CGFloat = 22 / 420
private let WATCH_HIJRI_YEAR_FONT_RATIO: CGFloat = 19 / 420
private let WATCH_METRICS_COMPACT_MIN_SIDE: CGFloat = 176
private let WATCH_METRICS_REGULAR_MIN_SIDE: CGFloat = 208

private struct WatchDialMetrics {
    let dialSize: CGFloat
    let sectorTop: CGFloat
    let dateTop: CGFloat
    let yearTop: CGFloat
    let centerOffsetY: CGFloat
    let dialVerticalOffset: CGFloat
    let maxTextWidth: CGFloat

    init(containerSize: CGSize) {
        let minSide = min(containerSize.width, containerSize.height)
        let compactness = Self.compactnessFactor(for: minSide)
        let glowPadding = minSide * Self.lerp(0.017, 0.032, compactness)
        let ringOuterDiameter = max(0, minSide - glowPadding * 2)

        dialSize = ringOuterDiameter / WATCH_RING_OUTER_DIAMETER_RATIO

        let holeTop = dialSize * (0.5 - 0.25125)
        let holeHeight = dialSize * 0.5025
        sectorTop = holeTop + 55 * (holeHeight / 212)
        dateTop = holeTop + 100 * (holeHeight / 212)
        yearTop = dateTop + (dateTop - sectorTop)
        centerOffsetY = dialSize * Self.lerp(-10 / 420, -8 / 420, compactness)
        dialVerticalOffset = dialSize * Self.lerp(8 / 420, 10 / 420, compactness)
        maxTextWidth = holeHeight * Self.lerp(0.72, 0.77, compactness)
    }

    private static func compactnessFactor(for minSide: CGFloat) -> CGFloat {
        let clamped = max(WATCH_METRICS_COMPACT_MIN_SIDE, min(WATCH_METRICS_REGULAR_MIN_SIDE, minSide))
        let span = WATCH_METRICS_REGULAR_MIN_SIDE - WATCH_METRICS_COMPACT_MIN_SIDE
        guard span > 0 else { return 0 }
        return 1 - ((clamped - WATCH_METRICS_COMPACT_MIN_SIDE) / span)
    }

    private static func lerp(_ regular: CGFloat, _ compact: CGFloat, _ compactness: CGFloat) -> CGFloat {
        regular + (compact - regular) * compactness
    }
}

struct ContentView: View {
    @StateObject private var mirrorStore = WatchSnapshotStore.shared
    @State private var now = Date()

    private var activeSnapshot: ComputedIslamicDay? {
        mirrorStore.snapshot
    }

    private var effectiveNow: Date {
        if let envelope = mirrorStore.envelope {
            return mirroredWatchRenderNow(envelope: envelope, currentDate: now)
        }
        return now
    }

    var body: some View {
        Group {
            if let snap = activeSnapshot {
                GeometryReader { geo in
                    let metrics = WatchDialMetrics(containerSize: geo.size)
                    ZStack {
                        RingView(snapshot: snap, now: effectiveNow, renderVariant: .phone)
                            .frame(width: metrics.dialSize, height: metrics.dialSize)
                            .id(ringRenderIdentity(snapshot: snap, now: effectiveNow, dialSize: metrics.dialSize))
                        ZStack(alignment: .top) {
                            Color.clear
                            currentPeriodView(snapshot: snap, now: effectiveNow, dialSize: metrics.dialSize)
                                .frame(maxWidth: .infinity)
                                .offset(y: metrics.sectorTop)
                            HijriDayMonthLabel(
                                snapshot: snap,
                                now: effectiveNow,
                                dialSize: metrics.dialSize,
                                maxTextWidth: metrics.maxTextWidth
                            )
                                .frame(maxWidth: .infinity)
                                .offset(y: metrics.dateTop)
                            HijriYearLabel(
                                snapshot: snap,
                                now: effectiveNow,
                                isVisible: !isEidJumuahConflict(snapshot: snap, now: effectiveNow),
                                dialSize: metrics.dialSize,
                                maxTextWidth: metrics.maxTextWidth
                            )
                                .frame(maxWidth: .infinity)
                                .offset(y: metrics.yearTop)
                        }
                        .frame(width: metrics.dialSize, height: metrics.dialSize)
                        .offset(y: metrics.centerOffsetY)
                    }
                    .offset(y: metrics.dialVerticalOffset)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            } else {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Waiting for iPhone snapshot…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.76))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    @ViewBuilder
    private func currentPeriodView(snapshot snap: ComputedIslamicDay, now: Date, dialSize: CGFloat) -> some View {
        if isEidJumuahConflict(snapshot: snap, now: now) {
            EmptyView()
        } else {
        let phase = currentPhase(snapshot: snap, now: now)
        Text(periodLabel(snapshot: snap, now: now).uppercased())
            .font(.system(size: dialSize * WATCH_CURRENT_PERIOD_FONT_RATIO, weight: .regular))
            .foregroundColor(periodColor(snapshot: snap, now: now))
            .modifier(IshaShadowModifier(phase: phase))
        }
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

    private func isEidJumuahConflict(snapshot snap: ComputedIslamicDay, now: Date) -> Bool {
        formatHijriDateParts(snap.hijriDate).isEid && periodLabel(snapshot: snap, now: now) == "Jumu'ah"
    }
}

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
    let dayText: String
    let monthText: String
    let year: String
    let isEid: Bool
    let showsEidHeading: Bool
    let useCompactDayMonth: Bool
    let emphasizedCompactMonth: Bool
    let extraEmphasizedCompactMonth: Bool
}

private func watchEidHeadingTitle(hijriDate: HijriDate) -> String {
    if hijriDate.monthNumber == 10 && hijriDate.day == 1 {
        return "EID AL-FITR"
    }
    if hijriDate.monthNumber == 12 && hijriDate.day == 10 {
        return "EID AL-ADHA"
    }
    return ""
}

private func watchShowsEidHeading(snapshot: ComputedIslamicDay, now: Date) -> Bool {
    let parts = formatHijriDateParts(snapshot.hijriDate)
    guard parts.isEid else { return false }

    switch getCurrentPhase(now: now, timeline: snapshot.timeline) {
    case .sunrise_to_dhuhr:
        let sub = getSunriseToDhuhrSubPeriod(
            now: now,
            duhaStart: snapshot.timeline.duhaStart,
            dhuhr: snapshot.timeline.dhuhr
        )
        return sub == .duha || sub == .midday
    case .dhuhr_to_asr:
        return true
    default:
        return false
    }
}

private func getWatchHijriLabelParts(
    hijriDate: HijriDate,
    snapshot: ComputedIslamicDay,
    now: Date
) -> WatchHijriLabelParts {
    let parts = formatHijriDateParts(hijriDate)
    let monthName = hijriDate.monthNameEn
    let isEid = parts.isEid
    let showsEidHeading = watchShowsEidHeading(snapshot: snapshot, now: now)
    let dayText = showsEidHeading ? watchEidHeadingTitle(hijriDate: hijriDate) : String(hijriDate.day)
    let monthText = showsEidHeading ? "" : monthName
    let lowerMonthName = monthName.lowercased()
    return WatchHijriLabelParts(
        dayMonth: parts.dayMonth,
        dayText: dayText,
        monthText: monthText,
        year: parts.year,
        isEid: isEid,
        showsEidHeading: showsEidHeading,
        useCompactDayMonth: COMPACT_MONTH_NAMES.contains(lowerMonthName),
        emphasizedCompactMonth: EMPHASIZED_COMPACT_MONTH_NAMES.contains(lowerMonthName),
        extraEmphasizedCompactMonth: lowerMonthName == "jumada al-thani"
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

    init(snapshot: ComputedIslamicDay, now: Date, dialSize: CGFloat, maxTextWidth: CGFloat) {
        self.parts = getWatchHijriLabelParts(
            hijriDate: snapshot.hijriDate,
            snapshot: snapshot,
            now: now
        )
        self.dialSize = dialSize
        self.maxTextWidth = maxTextWidth
    }

    @State private var pulseBright = false

    var body: some View {
        let monthFontRatio: CGFloat = {
            if parts.extraEmphasizedCompactMonth { return WATCH_HIJRI_COMPACT_EXTRA_EMPHASIZED_FONT_RATIO }
            if parts.emphasizedCompactMonth { return WATCH_HIJRI_COMPACT_EMPHASIZED_FONT_RATIO }
            if parts.useCompactDayMonth { return WATCH_HIJRI_COMPACT_FONT_RATIO }
            return WATCH_HIJRI_REGULAR_FONT_RATIO
        }()

        let content: Text = {
            if parts.showsEidHeading {
                return Text(parts.dayText)
                    .font(.system(size: dialSize * monthFontRatio, weight: .semibold))
            }

            return
                Text(parts.dayText)
                .font(.system(size: dialSize * monthFontRatio, weight: .semibold))
                + Text(" ")
                .font(.system(size: dialSize * monthFontRatio, weight: .semibold))
                + Text(parts.monthText.uppercased())
                .font(.system(size: dialSize * monthFontRatio, weight: .semibold))
        }()

        content
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
    private let isVisible: Bool
    private let dialSize: CGFloat
    private let maxTextWidth: CGFloat

    init(snapshot: ComputedIslamicDay, now: Date, isVisible: Bool = true, dialSize: CGFloat, maxTextWidth: CGFloat) {
        self.parts = getWatchHijriLabelParts(
            hijriDate: snapshot.hijriDate,
            snapshot: snapshot,
            now: now
        )
        self.isVisible = isVisible
        self.dialSize = dialSize
        self.maxTextWidth = maxTextWidth
    }

    @State private var pulseBright = false

    var body: some View {
        Group {
            if isVisible {
                Text(parts.year)
                    .font(.system(size: dialSize * WATCH_HIJRI_YEAR_FONT_RATIO, weight: .semibold))
                    .frame(width: maxTextWidth)
                    .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.secondaryGoldBright)
                    .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
            }
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
