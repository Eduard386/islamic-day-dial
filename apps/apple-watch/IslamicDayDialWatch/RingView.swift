import SwiftUI

private let GAP_SEGMENT_IDS: Set<IslamicPhaseId> = [.midnight_to_last_third, .last_third_to_fajr]
private let NIGHT_SECTORS_GROUP: Set<IslamicPhaseId> = [.isha_to_midnight, .midnight_to_last_third, .last_third_to_fajr]
private let PRIMARY_MARKER_IDS: Set<String> = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
private let SECONDARY_MARKER_IDS: Set<String> = ["sunrise", "islamic_midnight", "last_third_start"]

struct RingView: View {
    let snapshot: ComputedIslamicDay
    
    private var progressAngle: Double { snapshot.ringProgress * 360 }
    
    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let cx = s / 2
            let cy = s / 2
            let stroke = s * 0.081
            let inner = s * 0.25125
            let r = inner + stroke / 2
            
            // Segments
            let inNightGroup = NIGHT_SECTORS_GROUP.contains(snapshot.currentPhase)
            for seg in snapshot.ringSegments {
                let isGap = GAP_SEGMENT_IDS.contains(seg.id)
                let isActive = seg.id == snapshot.currentPhase ||
                    (inNightGroup && NIGHT_SECTORS_GROUP.contains(seg.id))
                let color = segmentColor(phase: seg.id, isActive: isActive)
                let path = arcPath(cx: cx, cy: cy, r: r, startDeg: seg.startAngleDeg, endDeg: seg.endAngleDeg)
                context.stroke(
                    path,
                    with: .color(color.opacity(isGap ? 1 : (isActive ? 1 : 0.65))),
                    lineWidth: stroke
                )
            }
            
            // Markers
            for m in snapshot.ringMarkers {
                let innerPt = polarToXY(cx: cx, cy: cy, r: inner, angleDeg: m.angleDeg)
                let tickLen = PRIMARY_MARKER_IDS.contains(m.id) ? s * 0.032 : s * 0.014
                let outerPt = polarToXY(cx: cx, cy: cy, r: inner - tickLen, angleDeg: m.angleDeg)
                var linePath = Path()
                linePath.move(to: innerPt)
                linePath.addLine(to: outerPt)
                context.stroke(linePath, with: .color(MARKER_STROKE), lineWidth: PRIMARY_MARKER_IDS.contains(m.id) ? 1.8 : 1.2)
            }
            
            // Current marker (simple circle, scaled)
            let markerR = s * 0.027
            let pos = polarToXY(cx: cx, cy: cy, r: r, angleDeg: progressAngle)
            let isNight = GAP_SEGMENT_IDS.contains(snapshot.currentPhase) || snapshot.currentPhase == .isha_to_midnight || snapshot.currentPhase == .maghrib_to_isha
            let markerColor: Color = isNight ? NIGHT : Color(red: 0.92, green: 0.70, blue: 0.03)
            context.fill(
                Circle().path(in: CGRect(x: pos.x - markerR, y: pos.y - markerR, width: markerR * 2, height: markerR * 2)),
                with: .color(markerColor)
            )
            context.stroke(
                Circle().path(in: CGRect(x: pos.x - markerR, y: pos.y - markerR, width: markerR * 2, height: markerR * 2)),
                with: .color(MARKER_STROKE.opacity(0.8)),
                lineWidth: 1.5
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
