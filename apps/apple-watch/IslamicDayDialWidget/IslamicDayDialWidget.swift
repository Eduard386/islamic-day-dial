import SwiftUI
import WidgetKit

struct IslamicDayDialEntry: TimelineEntry {
    let date: Date
    let snapshot: ComputedIslamicDay
    let countdownTarget: Date
    let locationTitle: String
}

struct IslamicDayDialProvider: TimelineProvider {
    func placeholder(in context: Context) -> IslamicDayDialEntry {
        previewEntry()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (IslamicDayDialEntry) -> Void) {
        Task {
            completion(await makeEntry(date: Date(), prefersPreviewData: context.isPreview))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<IslamicDayDialEntry>) -> Void) {
        Task {
            let entry = await makeEntry(date: Date(), prefersPreviewData: false)
            let quarterHourRefresh = entry.date.addingTimeInterval(15 * 60)
            let transitionRefresh = entry.snapshot.nextTransitionAt.addingTimeInterval(15)
            let refreshDate = min(quarterHourRefresh, transitionRefresh)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }
    
    private func makeEntry(date: Date, prefersPreviewData: Bool) async -> IslamicDayDialEntry {
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
        
        let snapshot = computeIslamicDaySnapshot(now: date, location: location) ?? previewEntry().snapshot
        let countdownTarget = getCountdownTarget(now: date, timeline: snapshot.timeline)
        return IslamicDayDialEntry(date: date, snapshot: snapshot, countdownTarget: countdownTarget, locationTitle: title)
    }
    
    private func previewEntry() -> IslamicDayDialEntry {
        let date = Date()
        let snapshot = computeIslamicDaySnapshot(now: date, location: .mecca) ?? fallbackSnapshot(now: date)
        let countdownTarget = getCountdownTarget(now: date, timeline: snapshot.timeline)
        return IslamicDayDialEntry(date: date, snapshot: snapshot, countdownTarget: countdownTarget, locationTitle: "Preview")
    }
    
    private func fallbackSnapshot(now: Date) -> ComputedIslamicDay {
        guard let snapshot = computeIslamicDaySnapshot(now: now, location: .mecca) else {
            fatalError("Unable to compute preview snapshot for the widget.")
        }
        return snapshot
    }
}

struct IslamicDayDialWidgetEntryView: View {
    let entry: IslamicDayDialProvider.Entry
    
    var body: some View {
        mediumWidget
        .containerBackground(Color(red: 0.06, green: 0.06, blue: 0.1), for: .widget)
    }
    
    private var mediumWidget: some View {
        HStack(spacing: 12) {
            RingView(snapshot: entry.snapshot, now: entry.date, thicknessScale: 1.35)
                .frame(width: 118, height: 118)
            
            VStack(spacing: 6) {
                Text(periodLabel(snapshot: entry.snapshot, now: entry.date).uppercased())
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(periodColor(snapshot: entry.snapshot))
                    .lineLimit(1)
                
                HijriWidgetLabels(hijriDate: entry.snapshot.hijriDate)
                
                Text(formatCountdown(countdownMs(snapshot: entry.snapshot)))
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundStyle(Colors.ivory)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding(.trailing, 4)
            
            Spacer(minLength: 0)
        }
        .padding(16)
    }
    
    private func countdownMs(snapshot snap: ComputedIslamicDay) -> Int64 {
        let target = getCountdownTarget(now: entry.date, timeline: snap.timeline)
        return Int64(max(0, target.timeIntervalSince(entry.date) * 1000))
    }
    
    private func periodLabel(snapshot snap: ComputedIslamicDay, now: Date) -> String {
        let isFriday = Calendar.current.component(.weekday, from: now) == 6
        if snap.currentPhase == .dhuhr_to_asr && isFriday { return "Jumu'ah" }
        if snap.currentPhase == .sunrise_to_dhuhr {
            let sub = getSunriseToDhuhrSubPeriod(now: now, sunrise: snap.timeline.sunrise, dhuhr: snap.timeline.dhuhr)
            if sub == .sunrise { return "Sunrise" }
            if isFriday && (sub == .duha || sub == .midday) { return "Jumu'ah" }
            return sub == .duha ? "Duha" : "Midday"
        }
        if snap.currentPhase == .last_third_to_fajr { return "Isha" }
        return formatCurrentPeriod(snap.currentPhase)
    }
    
    private func periodColor(snapshot snap: ComputedIslamicDay) -> Color {
        snap.currentPhase == .last_third_to_fajr
            ? Color(red: 0.22, green: 0.74, blue: 0.97)
            : Colors.nobleIronLighter
    }
}

private let WIDGET_COMPACT_MONTH_NAMES: Set<String> = [
    "rabi al-awwal", "rabi al-thani", "jumada al-ula", "jumada al-thani"
]

private struct HijriWidgetLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)
    private let useCompactDayMonth: Bool
    
    init(hijriDate: HijriDate) {
        self.parts = formatHijriDateParts(hijriDate)
        self.useCompactDayMonth = WIDGET_COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(parts.dayMonth.uppercased())
                .font(.system(size: useCompactDayMonth ? 12 : 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.accent)
            Text(parts.year)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Colors.accent)
        }
    }
}

@main
struct IslamicDayDialWidgetBundle: WidgetBundle {
    var body: some Widget {
        IslamicDayDialWidget()
    }
}

struct IslamicDayDialWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "IslamicDayDialWidget", provider: IslamicDayDialProvider()) { entry in
            IslamicDayDialWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Islamic Day Dial")
        .description("Track the current Islamic day phase, countdown, and ring at a glance.")
        .supportedFamilies([.systemMedium])
    }
}
