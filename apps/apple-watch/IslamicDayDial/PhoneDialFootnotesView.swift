import SwiftUI

private let footnoteStubBaseRatio: CGFloat = 0.048
private let phoneDiagramLabelColor = Color(red: 0.812, green: 0.79, blue: 0.748)
private let phoneDiagramActiveLabelColor = Color(red: 0.902, green: 0.875, blue: 0.824)
private let phoneDiagramLineColor = Color(red: 0.545, green: 0.518, blue: 0.467).opacity(0.6)

private struct PhoneFootnoteDef {
    let id: String
    let label: String
    let start: KeyPath<ComputedTimeline, Date>
    let end: KeyPath<ComputedTimeline, Date>
}

private let footnoteTopDefs: [PhoneFootnoteDef] = [
    .init(id: "dhuhr", label: "Dhuhr", start: \.dhuhr, end: \.asr),
    .init(id: "asr", label: "Asr", start: \.asr, end: \.nextMaghrib),
    .init(id: "maghrib", label: "Maghrib", start: \.lastMaghrib, end: \.isha),
    .init(id: "isha", label: "Isha", start: \.isha, end: \.lastThirdStart),
]

private let footnoteBottomDefs: [PhoneFootnoteDef] = [
    .init(id: "duha_end", label: "Midday", start: \.duhaEnd, end: \.dhuhr),
    .init(id: "duha_start", label: "Duha", start: \.duhaStart, end: \.duhaEnd),
    .init(id: "sunrise", label: "Sunrise", start: \.sunrise, end: \.duhaStart),
    .init(id: "fajr", label: "Fajr", start: \.fajr, end: \.sunrise),
    .init(id: "last_third_start", label: "Last 3rd", start: \.lastThirdStart, end: \.fajr),
]

private struct VerticalFootnoteItem: Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let points: [CGPoint]
    let labelPosition: CGPoint
    let labelWidth: CGFloat
    let lineColor: Color
    let labelColor: Color
}

private func phoneFootnoteLabelColor(_ label: String, currentLabel: String?) -> Color {
    label == currentLabel ? phoneDiagramActiveLabelColor : phoneDiagramLabelColor.opacity(0.82)
}

private func ringOuterR(dialSize: CGFloat) -> CGFloat {
    dialSize * 0.25125 + dialSize * 0.081
}

private func stubLength(dialSize: CGFloat, markerId: String) -> CGFloat {
    let base = dialSize * footnoteStubBaseRatio
    let mult: CGFloat = (markerId == "sunrise" || markerId == "maghrib") ? 2 : 1
    return base * mult
}

private func anchorOnRing(dialSize: CGFloat, angleDeg: Double, markerId: String) -> (rim: CGPoint, stub: CGPoint) {
    let cx = dialSize / 2
    let cy = dialSize / 2
    let r = ringOuterR(dialSize: dialSize)
    let rim = polarToXY(cx: Double(cx), cy: Double(cy), r: Double(r), angleDeg: angleDeg)
    let stubPt = polarToXY(
        cx: Double(cx),
        cy: Double(cy),
        r: Double(r + stubLength(dialSize: dialSize, markerId: markerId)),
        angleDeg: angleDeg
    )
    return (CGPoint(x: rim.x, y: rim.y), CGPoint(x: stubPt.x, y: stubPt.y))
}

private func midpoint(_ start: Date, _ end: Date) -> Date {
    Date(timeIntervalSince1970: start.timeIntervalSince1970 + (end.timeIntervalSince1970 - start.timeIntervalSince1970) / 2)
}

private func footnoteAngle(_ def: PhoneFootnoteDef, timeline: ComputedTimeline) -> Double {
    let start = timeline[keyPath: def.start]
    let end = timeline[keyPath: def.end]
    let total = timeline.nextMaghrib.timeIntervalSince(timeline.lastMaghrib)
    guard total > 0 else { return 0 }
    let mid = midpoint(start, end)
    let elapsed = mid.timeIntervalSince(timeline.lastMaghrib)
    return max(0, min(360, elapsed / total * 360))
}

struct PhoneDialFootnotesView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let dialSize: CGFloat
    let dialCenter: CGPoint
    let bounds: CGSize
    var isInteractive: Bool = false
    var onLabelTap: ((String) -> Void)? = nil

    private var dialOrigin: CGPoint {
        CGPoint(x: dialCenter.x - dialSize / 2, y: dialCenter.y - dialSize / 2)
    }

    private var labelFont: CGFloat { max(8.8, dialSize * (9.7 / 420)) }
    private var labelWidth: CGFloat { max(50, dialSize * 0.148) }
    private var labelHeight: CGFloat { max(28, labelFont * 2.4) }
    private var lineColor: Color { phoneDiagramLineColor }

    private var topLineY: CGFloat { dialOrigin.y - dialSize * 0.032 }
    private var topLabelY: CGFloat { dialOrigin.y - dialSize * 0.079 }
    private var bottomLineY: CGFloat { dialOrigin.y + dialSize + dialSize * 0.03 }
    private var bottomLabelY: CGFloat { dialOrigin.y + dialSize + dialSize * 0.074 }

    private var currentLabel: String? {
        let phase = getCurrentPhase(now: now, timeline: snapshot.timeline)
        switch phase {
        case .maghrib_to_isha:
            return "Maghrib"
        case .isha_to_last_third:
            return "Isha"
        case .last_third_to_fajr:
            return "Last 3rd"
        case .fajr_to_sunrise:
            return "Fajr"
        case .sunrise_to_dhuhr:
            switch getSunriseToDhuhrSubPeriod(now: now, duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr) {
            case .sunrise:
                return "Sunrise"
            case .duha:
                return "Duha"
            case .midday:
                return "Midday"
            }
        case .dhuhr_to_asr:
            return "Dhuhr"
        case .asr_to_maghrib:
            return "Asr"
        }
    }

    var body: some View {
        let items = buildItems()
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                for item in items {
                    guard let first = item.points.first else { continue }
                    var path = Path()
                    path.move(to: first)
                    for point in item.points.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(item.lineColor), lineWidth: max(0.8, dialSize / 420))
                }
            }
            .allowsHitTesting(false)

            ForEach(items) { item in
                Text(item.label)
                    .font(.system(size: labelFont, weight: .semibold, design: .default))
                    .foregroundStyle(item.labelColor)
                    .textCase(.uppercase)
                    .tracking(labelFont * 0.1)
                    .multilineTextAlignment(.center)
                    .frame(width: item.labelWidth, height: labelHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isInteractive else { return }
                        onLabelTap?(item.label)
                    }
                .position(item.labelPosition)
                .allowsHitTesting(isInteractive)
            }
        }
        .frame(width: bounds.width, height: bounds.height)
    }

    private func buildItems() -> [VerticalFootnoteItem] {
        let timeline = snapshot.timeline
        let origin = dialOrigin

        func toAbs(_ point: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + point.x, y: origin.y + point.y)
        }

        let clusterCenters: [String: CGFloat] = [
            "dhuhr": origin.x + dialSize * 0.145,
            "asr": origin.x + dialSize * 0.33,
            "maghrib": origin.x + dialSize * 0.55,
            "isha": origin.x + dialSize * 0.83,
            "duha_end": origin.x + dialSize * 0.135,
            "duha_start": origin.x + dialSize * 0.27,
            "sunrise": origin.x + dialSize * 0.405,
            "fajr": origin.x + dialSize * 0.72,
            "last_third_start": origin.x + dialSize * 0.89,
        ]

        let clusterWidths: [String: CGFloat] = [
            "maghrib": labelWidth * 1.14,
            "duha_end": labelWidth * 0.92,
            "duha_start": labelWidth * 0.9,
            "sunrise": labelWidth * 0.94,
            "last_third_start": labelWidth * 1.18,
        ]

        func buildRow(
            defs: [PhoneFootnoteDef],
            lineY: CGFloat,
            labelY: CGFloat
        ) -> [VerticalFootnoteItem] {
            defs.compactMap { def in
                let angle = footnoteAngle(def, timeline: timeline)
                let anchor = anchorOnRing(dialSize: dialSize, angleDeg: angle, markerId: def.id)
                let rimAbs = toAbs(anchor.rim)
                let stubAbs = toAbs(anchor.stub)
                let labelCenterX = clusterCenters[def.id] ?? stubAbs.x
                let labelJoinY = labelY + (labelY < lineY ? labelFont * 0.18 : -labelFont * 0.18)
                let itemLabelWidth = clusterWidths[def.id] ?? labelWidth
                let isCurrent = def.label == currentLabel
                let points = [
                    rimAbs,
                    stubAbs,
                    CGPoint(x: labelCenterX, y: lineY),
                    CGPoint(x: labelCenterX, y: labelJoinY),
                ]

                return VerticalFootnoteItem(
                    key: def.id,
                    label: def.label,
                    points: points,
                    labelPosition: CGPoint(x: labelCenterX, y: labelY),
                    labelWidth: itemLabelWidth,
                    lineColor: isCurrent ? lineColor.opacity(0.88) : lineColor.opacity(0.7),
                    labelColor: phoneFootnoteLabelColor(def.label, currentLabel: currentLabel)
                )
            }
        }

        return buildRow(defs: footnoteTopDefs, lineY: topLineY, labelY: topLabelY)
            + buildRow(defs: footnoteBottomDefs, lineY: bottomLineY, labelY: bottomLabelY)
    }
}
