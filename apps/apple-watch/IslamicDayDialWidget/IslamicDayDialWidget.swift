import SwiftUI
import WidgetKit

struct IslamicDayDialEntry: TimelineEntry {
    let date: Date
    let snapshot: ComputedIslamicDay?
    let countdownTarget: Date?
    let locationTitle: String
    let isPlaceholder: Bool

    init(date: Date, snapshot: ComputedIslamicDay?, countdownTarget: Date?, locationTitle: String, isPlaceholder: Bool = false) {
        self.date = date
        self.snapshot = snapshot
        self.countdownTarget = countdownTarget
        self.locationTitle = locationTitle
        self.isPlaceholder = isPlaceholder
    }
}

struct IslamicDayDialProvider: TimelineProvider {
    func placeholder(in context: Context) -> IslamicDayDialEntry {
        IslamicDayDialEntry(date: Date(), snapshot: nil, countdownTarget: nil, locationTitle: "", isPlaceholder: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (IslamicDayDialEntry) -> Void) {
        Task {
            completion(await makeEntry(date: Date(), prefersPreviewData: context.isPreview))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<IslamicDayDialEntry>) -> Void) {
        Task {
            let entry = await makeEntry(date: Date(), prefersPreviewData: false)
            let refreshDate = entry.date.addingTimeInterval(60) // Every minute for countdown accuracy
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
        
        guard let snapshot = computeIslamicDaySnapshot(now: date, location: location) else {
            return IslamicDayDialEntry(date: date, snapshot: nil, countdownTarget: nil, locationTitle: title)
        }
        let countdownTarget = getCountdownTarget(now: date, timeline: snapshot.timeline)
        return IslamicDayDialEntry(date: date, snapshot: snapshot, countdownTarget: countdownTarget, locationTitle: title)
    }
}

struct IslamicDayDialWidgetEntryView: View {
    let entry: IslamicDayDialProvider.Entry

    var body: some View {
        Group {
            if entry.isPlaceholder {
                placeholderContent
            } else if let snap = entry.snapshot {
                dataContent(snapshot: snap)
            } else {
                fallbackContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .padding(8)
        .containerBackground(Color(red: 0.06, green: 0.06, blue: 0.1), for: .widget)
    }

    private var placeholderContent: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Colors.softUtility.opacity(0.3))
                .frame(height: 16)
            RoundedRectangle(cornerRadius: 3)
                .fill(Colors.primaryGold.opacity(0.3))
                .frame(height: 20)
            RoundedRectangle(cornerRadius: 3)
                .fill(Colors.softUtility.opacity(0.3))
                .frame(height: 14)
        }
        .frame(maxWidth: .infinity)
    }

    private var fallbackContent: some View {
        VStack(spacing: 4) {
            Text("—")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Colors.coolLabel)
            Text("—")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Colors.secondaryGold)
            Text("—")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Colors.secondaryGold)
            Text("—")
                .font(.system(size: 16, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Colors.softUtility)
        }
    }

    private func dataContent(snapshot snap: ComputedIslamicDay) -> some View {
        VStack(spacing: 4) {
            Text(periodLabel(snapshot: snap, now: entry.date).uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(periodColor(snapshot: snap))
                .lineLimit(1)
            HijriWidgetLabels(hijriDate: snap.hijriDate)
            Text(formatCountdown(countdownMs(snapshot: snap)))
                .font(.system(size: 16, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Colors.softUtility)
        }
        .frame(maxWidth: .infinity)
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
        Colors.coolLabel
    }
}

private struct HijriWidgetLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)

    init(hijriDate: HijriDate) {
        self.parts = formatHijriDateParts(hijriDate)
    }

    var body: some View {
        return VStack(spacing: 1) {
            Text(parts.dayMonth.uppercased())
                .font(.system(size: 28, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGold)
            Text(parts.year)
                .font(.system(size: 14, weight: .semibold))
                .minimumScaleFactor(0.6)
                .foregroundStyle(Colors.secondaryGold)
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
        .description("Track the current Islamic day phase and countdown.")
        .supportedFamilies([.systemSmall])
    }
}
