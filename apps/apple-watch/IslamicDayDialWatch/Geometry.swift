import SwiftUI

/// Polar to Cartesian. 0° = top, clockwise.
/// Mirrors apps/web-dashboard/src/lib/geometry.ts
func polarToXY(cx: Double, cy: Double, r: Double, angleDeg: Double) -> CGPoint {
    let rad = (angleDeg - 90) * .pi / 180
    return CGPoint(
        x: cx + r * cos(rad),
        y: cy + r * sin(rad)
    )
}

/// Arc path for segment. 0° = top, clockwise (matches web describeArc).
func arcPath(cx: Double, cy: Double, r: Double, startDeg: Double, endDeg: Double) -> Path {
    let span = endDeg - startDeg
    guard span > 0 else { return Path() }
    
    let start = polarToXY(cx: cx, cy: cy, r: r, angleDeg: startDeg)
    let end = polarToXY(cx: cx, cy: cy, r: r, angleDeg: endDeg)
    
    var path = Path()
    path.move(to: start)
    // SwiftUI: 0° = right, 90° = bottom. Our 0° = top = -90° in standard.
    path.addArc(
        center: CGPoint(x: cx, y: cy),
        radius: r,
        startAngle: .degrees(startDeg - 90),
        endAngle: .degrees(endDeg - 90),
        clockwise: true
    )
    return path
}
