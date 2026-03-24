import SwiftUI

private let footnoteStubBaseRatio: CGFloat = 0.048

private struct PhoneFootnoteDef {
    let id: String
    let label: String
    let bendsToCenter: Bool
}

private let footnoteTopDefs: [PhoneFootnoteDef] = [
    .init(id: "dhuhr", label: "Dhuhr", bendsToCenter: false),
    .init(id: "asr", label: "Asr", bendsToCenter: true),
    .init(id: "maghrib", label: "Maghrib", bendsToCenter: true),
    .init(id: "isha", label: "Isha", bendsToCenter: true),
]

private let footnoteBottomDefs: [PhoneFootnoteDef] = [
    .init(id: "duha_end", label: "Midday", bendsToCenter: false),
    .init(id: "duha_start", label: "Duha", bendsToCenter: true),
    .init(id: "sunrise", label: "Sunrise", bendsToCenter: true),
    .init(id: "fajr", label: "Fajr", bendsToCenter: true),
    .init(id: "last_third_start", label: "Last 3rd", bendsToCenter: false),
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

struct PhoneDialFootnotesView: View {
    let snapshot: ComputedIslamicDay
    let dialSize: CGFloat
    let dialCenter: CGPoint
    let bounds: CGSize

    private var dialOrigin: CGPoint {
        CGPoint(x: dialCenter.x - dialSize / 2, y: dialCenter.y - dialSize / 2)
    }

    private var labelFont: CGFloat { max(9, dialSize * (10.9 / 420)) }
    private var labelWidth: CGFloat { max(56, dialSize * 0.17) }
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

            ForEach(items) { item in
                Text(item.label)
                    .font(.system(size: labelFont, weight: .medium))
                    .foregroundStyle(Colors.coolLabel)
                    .textCase(.uppercase)
                    .tracking(1.0)
                    .multilineTextAlignment(.center)
                    .frame(width: item.labelWidth)
                    .position(item.labelPosition)
            }
        }
        .frame(width: bounds.width, height: bounds.height)
        .allowsHitTesting(false)
    }

    private func buildItems() -> [VerticalFootnoteItem] {
        let markers = snapshot.ringMarkers
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
            let centers = evenlySpacedCenters(count: defs.count, minX: minCenterX, maxX: maxCenterX)

            return defs.enumerated().compactMap { index, def in
                guard let marker = markers.first(where: { $0.id == def.id }) else { return nil }
                let anchor = anchorOnRing(dialSize: dialSize, angleDeg: marker.angleDeg, markerId: def.id)
                let rimAbs = toAbs(anchor.rim)
                let stubAbs = toAbs(anchor.stub)
                let labelCenterX = centers[index]

                let points: [CGPoint]
                if def.bendsToCenter {
                    let centerJoinY = labelY + (labelY < lineY ? labelFont * 0.07 : -labelFont * 0.07)
                    points = [
                        rimAbs,
                        stubAbs,
                        CGPoint(x: labelCenterX, y: centerJoinY),
                    ]
                } else {
                    let edgeInset = labelWidth * 0.17
                    let anchorX = stubAbs.x < labelCenterX ? (labelCenterX - edgeInset) : (labelCenterX + edgeInset)
                    points = [
                        rimAbs,
                        stubAbs,
                        CGPoint(x: stubAbs.x, y: lineY),
                        CGPoint(x: anchorX, y: lineY),
                    ]
                }

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
