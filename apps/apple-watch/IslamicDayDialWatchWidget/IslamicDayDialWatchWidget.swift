import SwiftUI
import WidgetKit

struct IslamicDayDialWatchEntry: TimelineEntry {
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

struct IslamicDayDialWatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> IslamicDayDialWatchEntry {
        IslamicDayDialWatchEntry(date: Date(), snapshot: nil, countdownTarget: nil, locationTitle: "", isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (IslamicDayDialWatchEntry) -> Void) {
        Task {
            completion(await makeEntry(date: Date(), prefersPreviewData: context.isPreview))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IslamicDayDialWatchEntry>) -> Void) {
        Task {
            let entry = await makeEntry(date: Date(), prefersPreviewData: false)
            completion(Timeline(entries: [entry], policy: .after(nextWidgetRefreshDate(from: entry.date, snapshot: entry.snapshot))))
        }
    }

    private func makeEntry(date: Date, prefersPreviewData: Bool) async -> IslamicDayDialWatchEntry {
        let payload = await makeWidgetSnapshotPayload(date: date, prefersPreviewData: prefersPreviewData)
        return IslamicDayDialWatchEntry(
            date: date,
            snapshot: payload.snapshot,
            countdownTarget: payload.countdownTarget,
            locationTitle: payload.locationTitle
        )
    }
}

struct IslamicDayDialWatchWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: IslamicDayDialWatchEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                circularContent
            case .accessoryRectangular:
                rectangularContent
            case .accessoryInline:
                inlineContent
            default:
                inlineContent
            }
        }
        .containerBackground(Color.black, for: .widget)
    }

    private var circularContent: some View {
        ZStack {
            if let snapshot = entry.snapshot {
                RingView(snapshot: snapshot, now: entry.date, thicknessScale: 0.88, renderVariant: .watch)
                    .padding(4)
                Text(compactHijriCenterText(hijriDate: snapshot.hijriDate))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Colors.primaryGold)
                    .minimumScaleFactor(0.6)
            } else {
                Text("—")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Colors.coolLabel)
            }
        }
    }

    private var rectangularContent: some View {
        HStack(spacing: 8) {
            ZStack {
                if let snapshot = entry.snapshot {
                    RingView(snapshot: snapshot, now: entry.date, thicknessScale: 0.9, renderVariant: .watch)
                        .padding(3)
                    Text(compactHijriCenterText(hijriDate: snapshot.hijriDate))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Colors.primaryGold)
                        .minimumScaleFactor(0.6)
                } else {
                    Text("—")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Colors.coolLabel)
                }
            }
            .frame(width: 42, height: 42)

            if let snapshot = entry.snapshot {
                let hijri = compactHijriLabel(hijriDate: snapshot.hijriDate)
                VStack(alignment: .leading, spacing: 1) {
                    Text(widgetPeriodLabel(snapshot: snapshot, now: entry.date).uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Colors.coolLabel)
                        .lineLimit(1)
                    Text(hijri.primary)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(hijri.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            } else {
                Text("No data")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Colors.softUtility)
            }
        }
    }

    private var inlineContent: some View {
        Group {
            if let snapshot = entry.snapshot {
                Text(watchInlineLabel(snapshot: snapshot, now: entry.date))
            } else {
                Text("ISLAMIC DAY")
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Colors.primaryGold)
    }
}

@main
struct IslamicDayDialWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        IslamicDayDialWatchWidget()
    }
}

struct IslamicDayDialWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "IslamicDayDialWatchWidget", provider: IslamicDayDialWatchProvider()) { entry in
            IslamicDayDialWatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Islamic Day Dial")
        .description("Add the Islamic day ring to your watch face or Smart Stack.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
