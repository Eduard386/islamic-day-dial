import SwiftUI
import WidgetKit

private struct WidgetHijriEngravedLabelsModifier: ViewModifier {
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

private struct WidgetHijriDimensionalGoldModifier: ViewModifier {
    let isEid: Bool
    let secondary: Bool

    func body(content: Content) -> some View {
        if isEid {
            content
                .foregroundStyle(Color(red: 0.06, green: 0.73, blue: 0.51))
                .modifier(WidgetHijriEngravedLabelsModifier(isEid: true))
        } else {
            let top = secondary
                ? Color(red: 0.9, green: 0.8, blue: 0.55)
                : Color(red: 0.95, green: 0.84, blue: 0.58)
            let mid = secondary
                ? Color(red: 0.77, green: 0.61, blue: 0.24)
                : Color(red: 0.83, green: 0.66, blue: 0.24)
            let bottom = secondary
                ? Color(red: 0.49, green: 0.36, blue: 0.12)
                : Color(red: 0.57, green: 0.41, blue: 0.1)
            let topLight = Color.white.opacity(0.12)
            let warmLift = Color(red: 1, green: 0.95, blue: 0.78).opacity(0.06)
            let innerGlow = (secondary ? Colors.secondaryGold : Colors.primaryGold).opacity(0.07)
            let shade = Color.black.opacity(0.42)

            content
                .foregroundStyle(
                    LinearGradient(
                        colors: [top, mid, bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: topLight, radius: 0, x: 0, y: -0.7)
                .shadow(color: warmLift, radius: 1.0, x: 0, y: -0.2)
                .shadow(color: innerGlow, radius: 2.8)
                .shadow(color: shade, radius: 0, x: 0, y: 1.0)
                .shadow(color: shade.opacity(0.5), radius: 1.6, x: 0, y: 1.4)
        }
    }
}

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
            let refreshDate = nextHijriDateRefreshDate(from: entry.date, snapshot: entry.snapshot)
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
        HijriWidgetLabels(hijriDate: snap.hijriDate)
        .frame(maxWidth: .infinity)
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
                .modifier(WidgetHijriDimensionalGoldModifier(isEid: label.isEid, secondary: false))
            Text(label.secondary)
                .font(.system(size: 14, weight: .semibold))
                .minimumScaleFactor(0.6)
                .modifier(WidgetHijriDimensionalGoldModifier(isEid: label.isEid, secondary: true))
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
        .description("Show the current Hijri date.")
        .supportedFamilies([.systemSmall])
    }
}
