import SwiftUI

private let footnoteStubBaseRatio: CGFloat = 0.048

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

private func evenlySpacedCenters(count: Int, minX: CGFloat, maxX: CGFloat) -> [CGFloat] {
    guard count > 0 else { return [] }
    guard count > 1 else { return [(minX + maxX) / 2] }
    let step = (maxX - minX) / CGFloat(count - 1)
    return (0..<count).map { minX + CGFloat($0) * step }
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

private func spreadCenters(
    refs: [(key: String, targetX: CGFloat)],
    minX: CGFloat,
    maxX: CGFloat,
    minGap: CGFloat
) -> [String: CGFloat] {
    guard !refs.isEmpty else { return [:] }
    let sorted = refs.sorted { $0.targetX < $1.targetX }
    let clampedTargets = sorted.map { min(max($0.targetX, minX), maxX) }
    var positions = clampedTargets

    for index in 1..<positions.count {
        positions[index] = max(positions[index], positions[index - 1] + minGap)
    }
    if let overflow = positions.last.map({ $0 - maxX }), overflow > 0 {
        positions = positions.map { $0 - overflow }
    }
    if let underflow = positions.first.map({ minX - $0 }), underflow > 0 {
        positions = positions.map { $0 + underflow }
    }
    for index in stride(from: positions.count - 2, through: 0, by: -1) {
        positions[index] = min(positions[index], positions[index + 1] - minGap)
    }
    if let underflow = positions.first.map({ minX - $0 }), underflow > 0 {
        positions = positions.map { $0 + underflow }
    }

    var resolved: [String: CGFloat] = [:]
    for (index, item) in sorted.enumerated() {
        resolved[item.key] = positions[index]
    }
    return resolved
}

struct PhoneDialFootnotesView: View {
    let snapshot: ComputedIslamicDay
    let dialSize: CGFloat
    let dialCenter: CGPoint
    let bounds: CGSize
    var isInteractive: Bool = false
    var onLabelTap: ((String) -> Void)? = nil

    private var dialOrigin: CGPoint {
        CGPoint(x: dialCenter.x - dialSize / 2, y: dialCenter.y - dialSize / 2)
    }

    private var labelFont: CGFloat { max(9, dialSize * (10.9 / 420)) }
    private var labelWidth: CGFloat { max(56, dialSize * 0.17) }
    private var labelHeight: CGFloat { max(28, labelFont * 2.4) }
    private var lineColor: Color { Color(red: 0.984, green: 0.925, blue: 0.796).opacity(0.45) }

    private var topLineY: CGFloat { dialOrigin.y - dialSize * 0.07 }
    private var topLabelY: CGFloat { dialOrigin.y - dialSize * 0.145 }
    private var bottomLineY: CGFloat { dialOrigin.y + dialSize + dialSize * 0.07 }
    private var bottomLabelY: CGFloat { dialOrigin.y + dialSize + dialSize * 0.145 }

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
                    context.stroke(path, with: .color(lineColor), lineWidth: max(0.8, dialSize / 420))
                }
            }
            .allowsHitTesting(false)

            ForEach(items) { item in
                Text(item.label)
                    .font(.system(size: labelFont, weight: .medium))
                    .foregroundStyle(PHONE_READING_TINT)
                    .textCase(.uppercase)
                    .tracking(1.0)
                    .multilineTextAlignment(.center)
                    .shadow(color: PHONE_READING_GLOW.opacity(0.42), radius: 6)
                    .shadow(color: PHONE_READING_GLOW.opacity(0.24), radius: 12)
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
        let minCenterX = origin.x + 28 + labelWidth / 2
        let maxCenterX = origin.x + dialSize - 28 - labelWidth / 2

        func toAbs(_ point: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + point.x, y: origin.y + point.y)
        }

        func buildRow(
            defs: [PhoneFootnoteDef],
            lineY: CGFloat,
            labelY: CGFloat
        ) -> [VerticalFootnoteItem] {
            let targets = defs.map { def -> (String, CGFloat) in
                let angle = footnoteAngle(def, timeline: timeline)
                let anchor = anchorOnRing(dialSize: dialSize, angleDeg: angle, markerId: def.id)
                let stubAbs = toAbs(anchor.stub)
                return (def.id, stubAbs.x)
            }
            let fallbackCenters = evenlySpacedCenters(count: defs.count, minX: minCenterX, maxX: maxCenterX)
            let resolvedCenters = spreadCenters(
                refs: targets,
                minX: minCenterX,
                maxX: maxCenterX,
                minGap: labelWidth * 0.94
            )

            return defs.enumerated().compactMap { index, def in
                let angle = footnoteAngle(def, timeline: timeline)
                let anchor = anchorOnRing(dialSize: dialSize, angleDeg: angle, markerId: def.id)
                let rimAbs = toAbs(anchor.rim)
                let stubAbs = toAbs(anchor.stub)
                let labelCenterX = resolvedCenters[def.id] ?? fallbackCenters[index]
                let labelJoinY = labelY + (labelY < lineY ? labelFont * 0.18 : -labelFont * 0.18)
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
                    labelWidth: labelWidth
                )
            }
        }

        return buildRow(defs: footnoteTopDefs, lineY: topLineY, labelY: topLabelY)
            + buildRow(defs: footnoteBottomDefs, lineY: bottomLineY, labelY: bottomLabelY)
    }
}
