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
            let refreshDate = nextWidgetRefreshDate(from: entry.date, snapshot: entry.snapshot)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }
    
    private func makeEntry(date: Date, prefersPreviewData: Bool) async -> IslamicDayDialEntry {
        let payload = await makeWidgetSnapshotPayload(date: date, prefersPreviewData: prefersPreviewData)
        return IslamicDayDialEntry(
            date: date,
            snapshot: payload.snapshot,
            countdownTarget: payload.countdownTarget,
            locationTitle: payload.locationTitle
        )
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
        }
    }

    private func dataContent(snapshot snap: ComputedIslamicDay) -> some View {
        VStack(spacing: 4) {
            Text(widgetPeriodLabel(snapshot: snap, now: entry.date).uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(periodColor(snapshot: snap, now: entry.date))
                .lineLimit(1)
            HijriWidgetLabels(hijriDate: snap.hijriDate)
        }
        .frame(maxWidth: .infinity)
    }

    private func periodColor(snapshot snap: ComputedIslamicDay, now: Date) -> Color {
        Colors.coolLabel
    }
}

private struct HijriWidgetLabels: View {
    private let label: CompactHijriLabel

    init(hijriDate: HijriDate) {
        self.label = compactHijriLabel(hijriDate: hijriDate)
    }

    var body: some View {
        return VStack(spacing: 1) {
            Text(label.primary)
                .font(.system(size: 28, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(label.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGold)
            Text(label.secondary)
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
        .description("Track the current Islamic day phase and Hijri date.")
        .supportedFamilies([.systemSmall])
    }
}
