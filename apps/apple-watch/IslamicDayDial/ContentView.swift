import SwiftUI

private let DIAL_VERTICAL_GAP: CGFloat = 18
private let DIAL_SECTION_HEIGHT: CGFloat = 436
private let MS_PER_HOUR: Int64 = 3_600_000
private let MS_PER_DAY: Int64 = 24 * MS_PER_HOUR
private let INFO_EXPANSION_DURATION = 1.0
private let PHONE_DATE_INFO_SCALE: CGFloat = 1.25
private let PHONE_TEXT_GLOW_PULSE_DURATION = 3.0
let PHONE_READING_TINT = Color(red: 0.82, green: 0.78, blue: 0.60)
let PHONE_READING_GLOW = Color(red: 0.99, green: 0.88, blue: 0.38)
private let PHONE_INSIGHT_AYAH_AR = "إِنَّ عِدَّةَ الشُّهُورِ عِندَ اللَّهِ اثْنَا عَشَرَ شَهْرًا"
private let PHONE_INSIGHT_AYAH_EN = "\"Indeed, the number of months ordained by Allah is twelve\" [9:36]"
private let PHONE_HIJRI_MONTH_NAMES = [
    "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
    "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Shaban",
    "Ramadan", "Shawwal", "Dhul Qadah", "Dhul Hijjah"
]

private func phoneGlowPulsePhase(_ date: Date) -> (base: Double, phase: Double) {
    let seconds = date.timeIntervalSince1970.truncatingRemainder(dividingBy: PHONE_TEXT_GLOW_PULSE_DURATION)
    let normalized = seconds / PHONE_TEXT_GLOW_PULSE_DURATION
    let phase = (sin(normalized * 2 * .pi) + 1) / 2
    let base = 0.35 * (1 - phase)
    return (base, phase)
}

private func phoneSentenceCaseMonth(_ value: String) -> String {
    let lower = value.lowercased()
    guard let first = lower.first else { return value }
    return String(first).uppercased() + String(lower.dropFirst())
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
    @State private var showFootnotes = false
    @State private var infoPresentationProgress = 0.0
    @State private var footnoteOpacity = 0.0
    @State private var footnoteRevealTask: Task<Void, Never>?
    @State private var dialContentOpacity = 1.0
    @State private var insightOpacity = 0.0
    @State private var showInsightOverlay = false
    @State private var insightTransitionTask: Task<Void, Never>?

    private var effectiveNow: Date {
        if timeOffsetMs == 0 { return now }
        return now.addingTimeInterval(Double(timeOffsetMs) / 1000)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    dialSection
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .background(Color.black.ignoresSafeArea())
                .overlay {
                    ShakeDetectorView { showTimeTravel = true }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }
                .overlay {
                    if let snapshot, showInsightOverlay || insightOpacity > 0.001 {
                        ZStack {
                            PhoneDialInsightView(
                                snapshot: snapshot,
                                containerSize: geo.size
                            )
                            .opacity(insightOpacity)

                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    dismissInsightPresentation(toMainScreen: false)
                                }
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if snapshot != nil {
                        Button {
                            toggleInfoMode()
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
        .onDisappear {
            footnoteRevealTask?.cancel()
            insightTransitionTask?.cancel()
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
                PhoneDialView(
                    snapshot: snapshot,
                    now: effectiveNow,
                    infoProgress: infoPresentationProgress,
                    footnoteOpacity: footnoteOpacity,
                    dialContentOpacity: dialContentOpacity,
                    showsInsightOverlay: showInsightOverlay,
                    onDateTap: beginInsightPresentation
                )
                    .frame(height: DIAL_SECTION_HEIGHT)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 320)
            }
        }
        .padding(.bottom, DIAL_VERTICAL_GAP)
    }

    private func toggleInfoMode() {
        footnoteRevealTask?.cancel()
        insightTransitionTask?.cancel()

        if showInsightOverlay || insightOpacity > 0.001 {
            dismissInsightPresentation(toMainScreen: true)
            return
        }

        if showFootnotes {
            showFootnotes = false
            withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
                dialContentOpacity = 1
                insightOpacity = 0
                infoPresentationProgress = 0
                footnoteOpacity = 0
            }
            return
        }

        showFootnotes = true
        showInsightOverlay = false
        insightOpacity = 0
        dialContentOpacity = 1
        footnoteOpacity = 0
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            infoPresentationProgress = 1
        }

        footnoteRevealTask = Task {
            try? await Task.sleep(for: .seconds(INFO_EXPANSION_DURATION))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard showFootnotes else { return }
                withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
                    footnoteOpacity = 1
                }
            }
        }
    }

    private func beginInsightPresentation() {
        guard
            showFootnotes,
            infoPresentationProgress > 0.99,
            footnoteOpacity > 0.99,
            dialContentOpacity > 0.99,
            !showInsightOverlay
        else { return }

        insightTransitionTask?.cancel()
        showInsightOverlay = true
        insightOpacity = 0

        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            dialContentOpacity = 0
        }

        insightTransitionTask = Task {
            try? await Task.sleep(for: .seconds(INFO_EXPANSION_DURATION))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard showInsightOverlay else { return }
                withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
                    insightOpacity = 1
                }
            }
        }
    }

    private func dismissInsightPresentation(toMainScreen: Bool) {
        guard showInsightOverlay || insightOpacity > 0.001 else { return }

        insightTransitionTask?.cancel()
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            insightOpacity = 0
        }

        insightTransitionTask = Task {
            try? await Task.sleep(for: .seconds(INFO_EXPANSION_DURATION))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                showInsightOverlay = false
                dialContentOpacity = 0

                if toMainScreen {
                    showFootnotes = false
                    infoPresentationProgress = 0
                    footnoteOpacity = 0
                } else {
                    showFootnotes = true
                    infoPresentationProgress = 1
                    footnoteOpacity = 1
                }

                withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
                    dialContentOpacity = 1
                }
            }
        }
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
    let infoProgress: Double
    let footnoteOpacity: Double
    let dialContentOpacity: Double
    let showsInsightOverlay: Bool
    let onDateTap: () -> Void

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
            let centerOffsetY = dialSize * (-10 / 420)
            let canEnterInsight = infoProgress > 0.99
                && footnoteOpacity > 0.99
                && dialContentOpacity > 0.99
                && !showsInsightOverlay

            ZStack {
                PhoneDialFootnotesView(
                    snapshot: snapshot,
                    dialSize: dialSize,
                    dialCenter: dialCenter,
                    bounds: geo.size
                )
                .opacity(footnoteOpacity * dialContentOpacity)
                ZStack {
                    PhoneRingView(snapshot: snapshot, now: now, phoneInfoProgress: infoProgress)
                        .frame(width: dialSize, height: dialSize)
                    ZStack(alignment: .top) {
                        Color.clear
                        currentPeriodView(snapshot: snapshot, now: now)
                            .frame(maxWidth: .infinity)
                            .offset(y: sectorTop)
                            .opacity(max(0, 1 - infoProgress))
                        HijriDateLabels(
                            hijriDate: snapshot.hijriDate,
                            infoProgress: infoProgress,
                            isInteractive: canEnterInsight,
                            onTap: onDateTap
                        )
                            .frame(maxWidth: .infinity)
                            .offset(y: dateTop)
                    }
                    .frame(width: dialSize, height: dialSize)
                    .offset(y: centerOffsetY)
                }
                .frame(width: dialSize, height: dialSize)
                .position(dialCenter)
                .opacity(dialContentOpacity)
            }
            .frame(width: w, height: h)
        }
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
    var phoneInfoProgress: Double = 0

    var body: some View {
        RingView(
            snapshot: snapshot,
            now: now,
            thicknessScale: thicknessScale,
            renderVariant: .phone,
            phoneInfoProgress: phoneInfoProgress
        )
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
    private let infoProgress: Double
    private let isInteractive: Bool
    private let onTap: (() -> Void)?

    init(hijriDate: HijriDate, infoProgress: Double = 0, isInteractive: Bool = false, onTap: (() -> Void)? = nil) {
        self.parts = formatHijriDateParts(hijriDate)
        self.useCompactDayMonth = COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
        self.infoProgress = max(0, min(1, infoProgress))
        self.isInteractive = isInteractive
        self.onTap = onTap
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = 0.25 + phoneGlowPulsePhase(timeline.date).phase * 0.75
            let glowStrength = CGFloat(infoProgress)
            let phaseValue = CGFloat(phase)
            let scale = 1 + glowStrength * (PHONE_DATE_INFO_SCALE - 1)
            let goldOpacity = (0.14 + phase * 0.32) * Double(glowStrength)
            let whiteOpacity = (0.05 + phase * 0.14) * Double(glowStrength)
            let goldRadius = CGFloat(7) + glowStrength * CGFloat(4) + phaseValue * CGFloat(10)
            let whiteRadius = CGFloat(3) + glowStrength * CGFloat(2) + phaseValue * CGFloat(6)

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
            .scaleEffect(scale)
            .brightness(-0.01 + phase * 0.04)
            .shadow(color: Colors.primaryGold.opacity(goldOpacity), radius: goldRadius)
            .shadow(color: Colors.secondaryGold.opacity(goldOpacity * 0.82), radius: goldRadius + CGFloat(5))
            .shadow(color: Color.white.opacity(whiteOpacity), radius: whiteRadius)
        }
        .contentShape(Rectangle())
        .allowsHitTesting(isInteractive)
        .onTapGesture {
            onTap?()
        }
    }
}

private struct PhoneDialInsightView: View {
    let snapshot: ComputedIslamicDay
    let containerSize: CGSize

    var body: some View {
        TimelineView(.animation) { timeline in
            let (_, phase) = phoneGlowPulsePhase(timeline.date)
            let monthGlowPhase = CGFloat(phase)
            let listWidth = min(containerSize.width - 52, 280)

            VStack(spacing: containerSize.height * 0.012) {
                Text(PHONE_INSIGHT_AYAH_AR)
                    .font(.system(size: min(containerSize.width * 0.052, 22), weight: .medium, design: .serif))
                    .foregroundColor(PHONE_READING_TINT)
                    .multilineTextAlignment(.center)
                    .lineSpacing(containerSize.height * 0.006)
                    .frame(maxWidth: min(containerSize.width - 36, 420))

                Text(PHONE_INSIGHT_AYAH_EN)
                    .font(.system(size: min(containerSize.width * 0.04, 17), weight: .regular, design: .serif))
                    .foregroundColor(PHONE_READING_TINT)
                    .multilineTextAlignment(.center)
                    .lineSpacing(containerSize.height * 0.003)
                    .frame(maxWidth: min(containerSize.width - 56, 360))

                Color.clear
                    .frame(height: containerSize.height * 0.03)

                VStack(alignment: .leading, spacing: containerSize.height * 0.005) {
                    ForEach(Array(PHONE_HIJRI_MONTH_NAMES.enumerated()), id: \.offset) { index, monthName in
                        let isCurrentMonth = snapshot.hijriDate.monthNumber == index + 1
                        let currentMonthGlowOpacity = isCurrentMonth ? 0.2 + Double(phase) * 0.16 : 0
                        let currentMonthWhiteOpacity = isCurrentMonth ? 0.08 + Double(phase) * 0.08 : 0
                        let currentMonthRadius = isCurrentMonth ? CGFloat(4) + monthGlowPhase * CGFloat(4) : 0

                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1).")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .monospacedDigit()
                                .frame(width: 24, alignment: .trailing)
                            Text(phoneSentenceCaseMonth(monthName))
                                .font(.system(size: 18, weight: .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                            .foregroundColor(PHONE_READING_TINT)
                            .modifier(HijriEngravedLabelsModifier(isEid: false))
                            .shadow(color: PHONE_READING_GLOW.opacity(currentMonthGlowOpacity), radius: currentMonthRadius)
                            .shadow(color: Color.white.opacity(currentMonthWhiteOpacity), radius: currentMonthRadius * 0.6)
                    }
                }
                .frame(width: listWidth, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, containerSize.height * 0.15)
            .padding(.horizontal, 18)
        }
        .allowsHitTesting(false)
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
