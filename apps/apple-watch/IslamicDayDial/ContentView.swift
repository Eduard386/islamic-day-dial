import SwiftUI

private let DIAL_VERTICAL_GAP: CGFloat = 18
private let DIAL_SECTION_HEIGHT: CGFloat = 436
private let MS_PER_HOUR: Int64 = 3_600_000
private let MS_PER_DAY: Int64 = 24 * MS_PER_HOUR

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var automaticLocation: Location = .mecca
    @State private var snapshot: ComputedIslamicDay?
    @State private var now = Date()
    
    // Debug Time Travel (shake to reveal)
    @State private var showTimeTravel = false
    @State private var monthOffset = 0
    @State private var dayOffset = 0
    @State private var hourOffset: Double = 0
    @State private var timeOffsetMs: Int64 = 0
    @State private var showFootnotes = false

    private var effectiveNow: Date {
        if timeOffsetMs == 0 { return now }
        return now.addingTimeInterval(Double(timeOffsetMs) / 1000)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    dialSection
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
            }
            .background(Color.black.ignoresSafeArea())
            .overlay {
                ShakeDetectorView { showTimeTravel = true }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomTrailing) {
                if snapshot != nil {
                    Button {
                        showFootnotes.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 26, weight: .regular))
                            .foregroundStyle(Colors.secondaryGold)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 18)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Prayer labels")
                }
            }
        }
        .task {
            await refreshSnapshot(forceResolveLocation: true)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = Date()
            }
        }
        .task {
            while !Task.isCancelled {
                await refreshSnapshot(forceResolveLocation: false)
                let currentSnapshot = snapshot
                let currentNow = effectiveNow
                try? await Task.sleep(for: .seconds(secondsUntilNextRefresh(from: currentNow, snapshot: currentSnapshot)))
            }
        }
        .onChange(of: timeOffsetMs) { _, _ in recalcSnapshot() }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .background && newPhase == .active {
                Task { await refreshSnapshot(forceResolveLocation: true) }
            }
        }
        .sheet(isPresented: $showTimeTravel) {
            TimeTravelSheet(
                monthOffset: $monthOffset,
                dayOffset: $dayOffset,
                hourOffset: $hourOffset,
                timeOffsetMs: $timeOffsetMs,
                currentHijriDay: snapshot?.hijriDate.day ?? 1
            )
        }
    }
    
    private func recalcSnapshot() {
        snapshot = computeIslamicDaySnapshot(now: effectiveNow, location: automaticLocation)
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
    
    private var dialSection: some View {
        Group {
            if let snapshot {
                PhoneDialView(snapshot: snapshot, now: effectiveNow, showFootnotes: $showFootnotes)
                    .frame(height: DIAL_SECTION_HEIGHT)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 320)
            }
        }
        .padding(.bottom, DIAL_VERTICAL_GAP)
    }
    
    private func refreshSnapshot(forceResolveLocation: Bool) async {
        if forceResolveLocation || snapshot == nil {
            let result = await resolveGeoResult()
            automaticLocation = result.location
            if forceResolveLocation {
                await trackVisit(geo: result)
                await PrayerNotificationScheduler.requestAndSchedule(location: automaticLocation)
            }
        }
        
        let currentNow = Date()
        now = currentNow
        let displayNow = currentNow.addingTimeInterval(Double(timeOffsetMs) / 1000)
        snapshot = computeIslamicDaySnapshot(now: displayNow, location: automaticLocation)
    }
}

private struct PhoneDialView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    @Binding var showFootnotes: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let dialSize = min(w, h) * 1.28
            let dialCenter = CGPoint(x: w / 2, y: h / 2)
            let holeTop = dialSize * (0.5 - 0.25125)
            let holeHeight = dialSize * 0.5025
            let sectorTop = holeTop + 55 * (holeHeight / 212)
            let dateTop = holeTop + 100 * (holeHeight / 212)
            let countdownTop = holeTop + 165 * (holeHeight / 212)
            let centerOffsetY = dialSize * (-10 / 420)

            ZStack {
                if showFootnotes {
                    PhoneDialFootnotesView(
                        snapshot: snapshot,
                        dialSize: dialSize,
                        dialCenter: dialCenter,
                        bounds: geo.size
                    )
                }
                ZStack {
                    PhoneRingView(snapshot: snapshot, now: now)
                        .frame(width: dialSize, height: dialSize)
                    ZStack(alignment: .top) {
                        Color.clear
                        currentPeriodView(snapshot: snapshot, now: now)
                            .frame(maxWidth: .infinity)
                            .offset(y: sectorTop)
                        HijriDateLabels(hijriDate: snapshot.hijriDate)
                            .frame(maxWidth: .infinity)
                            .offset(y: dateTop)
                        Text(formatCountdown(countdownMs(snapshot: snapshot)))
                            .font(.system(size: 17, weight: .light))
                            .monospacedDigit()
                            .foregroundColor(Colors.softUtility)
                            .frame(maxWidth: .infinity)
                            .offset(y: countdownTop)
                    }
                    .frame(width: dialSize, height: dialSize)
                    .offset(y: centerOffsetY)
                }
                .frame(width: dialSize, height: dialSize)
                .position(dialCenter)
            }
            .frame(width: w, height: h)
        }
    }
    
    private func countdownMs(snapshot snap: ComputedIslamicDay) -> Int64 {
        let target = getCountdownTarget(now: now, timeline: snap.timeline)
        return Int64(max(0, target.timeIntervalSince(now) * 1000))
    }
    
    @ViewBuilder
    private func currentPeriodView(snapshot snap: ComputedIslamicDay, now: Date) -> some View {
        let phase = currentPhase(snapshot: snap, now: now)
        Text(periodLabel(snapshot: snap, now: now).uppercased())
            .font(.system(size: 20, weight: .light))
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
        Colors.coolLabel
    }

    private func currentPhase(snapshot snap: ComputedIslamicDay, now: Date) -> IslamicPhaseId {
        getCurrentPhase(now: now, timeline: snap.timeline)
    }
}

/// App-only entry point for the dial renderer.
/// Keep phone-specific visual changes here so watch rendering stays untouched.
private struct PhoneRingView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    var thicknessScale: CGFloat = 1

    var body: some View {
        RingView(snapshot: snapshot, now: now, thicknessScale: thicknessScale, renderVariant: .phone)
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
    @State private var pulseBright = false

    init(hijriDate: HijriDate) {
        self.parts = formatHijriDateParts(hijriDate)
        self.useCompactDayMonth = COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(parts.dayMonth.uppercased())
                .font(.system(size: useCompactDayMonth ? 15 : 18, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGold)
                .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
            Text(parts.year)
                .font(.system(size: 14, weight: .semibold))
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

// MARK: - Shake detector (debug Time Travel)

private struct ShakeDetectorView: UIViewRepresentable {
    var onShake: () -> Void
    
    func makeUIView(context: Context) -> ShakeDetectingUIView {
        let v = ShakeDetectingUIView()
        v.onShake = onShake
        return v
    }
    
    func updateUIView(_ uiView: ShakeDetectingUIView, context: Context) {
        uiView.onShake = onShake
    }
}

private class ShakeDetectingUIView: UIView {
    var onShake: (() -> Void)?
    
    override var canBecomeFirstResponder: Bool { true }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            _ = self?.becomeFirstResponder()
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
        super.motionEnded(motion, with: event)
    }
}

// MARK: - Time Travel sheet (debug)

private struct TimeTravelSheet: View {
    @Binding var monthOffset: Int
    @Binding var dayOffset: Int
    @Binding var hourOffset: Double
    @Binding var timeOffsetMs: Int64
    let currentHijriDay: Int
    @Environment(\.dismiss) private var dismiss
    
    private func applyOffset() {
        let totalDays = Int64(monthOffset) * 30 + Int64(dayOffset)
        timeOffsetMs = totalDays * MS_PER_DAY + Int64(hourOffset * Double(MS_PER_HOUR))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Shake to open • Debug Time Travel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Months") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(monthOffset) },
                            set: { monthOffset = Int($0); applyOffset() }
                        ), in: -6...6, step: 1)
                        Text(monthOffset == 0 ? "0" : "\(monthOffset > 0 ? "+" : "")\(monthOffset)m")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                Section("Days") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(dayOffset) },
                            set: { dayOffset = Int($0); applyOffset() }
                        ), in: -15...15, step: 1)
                        Text(dayOffset == 0 ? "0" : "\(dayOffset > 0 ? "+" : "")\(dayOffset)d")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                Section("Hours") {
                    HStack {
                        Slider(value: Binding(
                            get: { hourOffset },
                            set: { hourOffset = $0; applyOffset() }
                        ), in: -12...12, step: 0.5)
                        Text(hourOffset == 0 ? "0" : "\(hourOffset > 0 ? "+" : "")\(hourOffset, specifier: "%.1f")h")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                Section {
                    HStack {
                        Text("Day \(currentHijriDay)")
                            .fontWeight(.medium)
                        Spacer()
                        Button("Now") {
                            monthOffset = 0
                            dayOffset = 0
                            hourOffset = 0
                            timeOffsetMs = 0
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Colors.primaryGold)
                    }
                }
            }
            .navigationTitle("Time Travel")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black)
        }
    }
}

#Preview {
    ContentView()
}
