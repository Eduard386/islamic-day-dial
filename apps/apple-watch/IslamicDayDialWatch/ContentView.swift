import SwiftUI

struct ContentView: View {
    @State private var snapshot: ComputedIslamicDay?
    @State private var now = Date()
    @State private var location: Location = .mecca

    var body: some View {
        Group {
            if let snap = snapshot {
                GeometryReader { geo in
                    // Кольцо: с запасом от границ (1.5x вместо 1.65)
                    let dialSize = min(geo.size.width, geo.size.height) * 1.5
                    // Web: center-info height 212px = hole diameter; positions 55, 100, 165 from hole top
                    let holeTop = dialSize * (0.5 - 0.25125)
                    let holeHeight = dialSize * 0.5025
                    let sectorTop = holeTop + 55 * (holeHeight / 212)
                    let dateTop = holeTop + 100 * (holeHeight / 212)
                    let countdownTop = holeTop + 165 * (holeHeight / 212)
                    let centerOffsetY = dialSize * (-10 / 420)  // Web: -10px nudge
                    ZStack {
                        RingView(snapshot: snap, now: now)
                            .frame(width: dialSize, height: dialSize)
                        ZStack(alignment: .top) {
                            Color.clear
                            currentPeriodView(snapshot: snap, now: now)
                                .frame(maxWidth: .infinity)
                                .offset(y: sectorTop)
                            HijriDateLabels(hijriDate: snap.hijriDate)
                                .frame(maxWidth: .infinity)
                                .offset(y: dateTop)
                            Text(formatCountdown(countdownMs(snapshot: snap)))
                                .font(.system(size: 10, weight: .light, design: .monospaced))
                                .foregroundColor(Colors.softUtility)
                                .frame(maxWidth: .infinity)
                                .offset(y: countdownTop)
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
        .task {
            location = await resolveLocation()
            snapshot = computeIslamicDaySnapshot(location: location)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = Date()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                snapshot = computeIslamicDaySnapshot(location: location)
            }
        }
    }

    private func countdownMs(snapshot snap: ComputedIslamicDay) -> Int64 {
        let target = getCountdownTarget(now: now, timeline: snap.timeline)
        return Int64(max(0, target.timeIntervalSince(now) * 1000))
    }
    
    @ViewBuilder
    private func currentPeriodView(snapshot snap: ComputedIslamicDay, now: Date) -> some View {
        // Web: current-period-subsectors 0.85em of 1.4rem, weight 300
        Text(periodLabel(snapshot: snap, now: now))
            .font(.system(size: 10, weight: .light))
            .foregroundColor(periodColor(snapshot: snap))
            .modifier(IshaShadowModifier(phase: snap.currentPhase))
    }

    private func periodLabel(snapshot snap: ComputedIslamicDay, now: Date) -> String {
        getSectorDisplayName(now: now, currentPhase: snap.currentPhase, timeline: (sunrise: snap.timeline.sunrise, dhuhr: snap.timeline.dhuhr))
    }

    private func periodColor(snapshot snap: ComputedIslamicDay) -> Color {
        snap.currentPhase == .last_third_to_fajr
            ? Color(red: 0.22, green: 0.74, blue: 0.97)
            : Colors.coolLabel
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

private struct HijriDateLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)
    private let useCompactDayMonth: Bool

    init(hijriDate: HijriDate) {
        self.parts = formatHijriDateParts(hijriDate)
        self.useCompactDayMonth = COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
    }

    var body: some View {
        // Web: hijri-date 1.2rem/1.0rem(compact), year 0.9rem — date крупнее года
        VStack(spacing: 2) {
            Text(parts.dayMonth.uppercased())
                .font(.system(size: useCompactDayMonth ? 11 : 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGold)
            Text(parts.year)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Colors.secondaryGold)
        }
    }
}

#Preview {
    ContentView()
}
