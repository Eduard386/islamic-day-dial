import SwiftUI

private let DIAL_VERTICAL_GAP: CGFloat = 18
private let DIAL_SECTION_HEIGHT: CGFloat = 436
/// Horizontal insets from ScrollView `.padding(20)` × 2
private let SCROLL_HORIZONTAL_INSET: CGFloat = 40
/// Quran 9:36 (matches web dashboard)
private let HEADER_AYAH_AR =
    "إِنَّ عِدَّةَ الشُّهُورِ عِندَ اللَّهِ اثْنَا عَشَرَ شَهْرًا"
/// Matches `App.tsx` dial-ayah-translation
private let HEADER_AYAH_EN =
    "\"Indeed, the number of months ordained by Allah is twelve\" [9:36]"
/// Islamic Day Dial + gap + Maghrib (fonts 18 / 14)
private let HEADER_TITLE_STACK_HEIGHT: CGFloat = 22 + 4 + 17
private let MS_PER_HOUR: Int64 = 3_600_000
private let MS_PER_DAY: Int64 = 24 * MS_PER_HOUR

/// Same layout as PhoneDialView: dialSize, holeTop, dateTop.
private func dateOffsetFromDialFrameTop(contentWidth: CGFloat) -> CGFloat {
    let h = DIAL_SECTION_HEIGHT
    let dialSize = min(contentWidth, h) * 1.28
    let holeTop = dialSize * (0.5 - 0.25125)
    let holeHeight = dialSize * 0.5025
    return holeTop + 100 * (holeHeight / 212)
}

/// Titles at 15% from ayah (0%) to date in ring (100%). padTop + titleH/2 = 0.15 * total, total = padTop + titleH + padBottom + dateOffset.
private func headerTitlePaddingPair(contentWidth: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
    let bottom: CGFloat = 8
    let dateOffset = dateOffsetFromDialFrameTop(contentWidth: contentWidth)
    // padTop + titleH/2 = 0.15 * (padTop + titleH + padBottom + dateOffset) => 0.85*padTop = 0.15*(bottom + dateOffset) - 0.35*titleH
    let padTop = (0.15 * (bottom + dateOffset) - 0.35 * HEADER_TITLE_STACK_HEIGHT) / 0.85
    return (max(0, padTop), bottom)
}

private func arabicBottomToDialFrameTop(contentWidth: CGFloat) -> CGFloat {
    let (t, b) = headerTitlePaddingPair(contentWidth: contentWidth)
    return t + HEADER_TITLE_STACK_HEIGHT + b
}

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
    
    private var effectiveNow: Date {
        if timeOffsetMs == 0 { return now }
        return now.addingTimeInterval(Double(timeOffsetMs) / 1000)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    dialSection
                    Spacer().frame(height: 24)
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .overlay {
                ShakeDetectorView { showTimeTravel = true }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
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
                try? await Task.sleep(for: .seconds(60))
                await refreshSnapshot(forceResolveLocation: false)
            }
        }
        .onChange(of: now) { _, _ in recalcSnapshot() }
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
    
    private var headerSection: some View {
        let w = UIScreen.main.bounds.width - SCROLL_HORIZONTAL_INSET
        let (padTop, padBottom) = headerTitlePaddingPair(contentWidth: w)
        return VStack(spacing: 0) {
            Text(HEADER_AYAH_AR)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Colors.warmSacredWhite)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 8)
            Color.clear
                .frame(height: padTop)
            VStack(spacing: 4) {
                Text("Islamic Day Dial")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Colors.neutralHeadingWhite)
                    .tracking(0.5)
                Text("Maghrib to Maghrib")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Colors.coolMutedSubtitle)
            }
            Color.clear
                .frame(height: padBottom)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var dialSection: some View {
        Group {
            if let snapshot {
                VStack(spacing: arabicBottomToDialFrameTop(contentWidth: UIScreen.main.bounds.width - SCROLL_HORIZONTAL_INSET)) {
                    PhoneDialView(snapshot: snapshot, now: effectiveNow)
                        .frame(height: DIAL_SECTION_HEIGHT)
                    Text(HEADER_AYAH_EN)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Colors.softQuoteWhite)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 20)
                }
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
    
    var body: some View {
        GeometryReader { geo in
            let dialSize = min(geo.size.width, geo.size.height) * 1.28
            let holeTop = dialSize * (0.5 - 0.25125)
            let holeHeight = dialSize * 0.5025
            let sectorTop = holeTop + 55 * (holeHeight / 212)
            let dateTop = holeTop + 100 * (holeHeight / 212)
            let countdownTop = holeTop + 165 * (holeHeight / 212)
            let centerOffsetY = dialSize * (-10 / 420)
            
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
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    private func countdownMs(snapshot snap: ComputedIslamicDay) -> Int64 {
        let target = getCountdownTarget(now: now, timeline: snap.timeline)
        return Int64(max(0, target.timeIntervalSince(now) * 1000))
    }
    
    @ViewBuilder
    private func currentPeriodView(snapshot snap: ComputedIslamicDay, now: Date) -> some View {
        Text(periodLabel(snapshot: snap, now: now).uppercased())
            .font(.system(size: 20, weight: .light))
            .foregroundColor(periodColor(snapshot: snap))
            .modifier(IshaShadowModifier(phase: snap.currentPhase))
    }
    
    private func periodLabel(snapshot snap: ComputedIslamicDay, now: Date) -> String {
        getSectorDisplayName(now: now, currentPhase: snap.currentPhase, timeline: (duhaStart: snap.timeline.duhaStart, dhuhr: snap.timeline.dhuhr))
    }
    
    private func periodColor(snapshot snap: ComputedIslamicDay) -> Color {
        Colors.coolLabel
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

private struct HijriDateLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)
    private let useCompactDayMonth: Bool
    
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
            Text(parts.year)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Colors.secondaryGold)
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
