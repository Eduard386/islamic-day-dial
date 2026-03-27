import SwiftUI

/// Segment gradient palettes. Mirrors apps/web-dashboard/src/lib/segment-gradients.ts
/// Simplified for watch: fewer stops, same color flow.

private typealias RGB = (r: Double, g: Double, b: Double)

private func hexToRGB(_ hex: Int) -> RGB {
    (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
}

private func rgbToColor(_ rgb: RGB) -> Color {
    Color(red: rgb.r, green: rgb.g, blue: rgb.b)
}

/// Maghrib → Isha: red sunset → black night (exact match web MAGHRIB_PALETTE)
private let MAGHRIB_PALETTE: [RGB] = [0xC84A3A, 0xB04038, 0x983634, 0x802C30, 0x68242C, 0x501C28, 0x381420, 0x200C18, 0x080408, 0x000000].map(hexToRGB)

/// Fajr → Sunrise: dark → blue dawn (matches web flow: 0-45% dark, 45-75% blue, 75-100% dawn)
private let FAJR_SUNRISE_PALETTE: [RGB] = [0x000000, 0x000208, 0x000814, 0x001024, 0x001630, 0x182440, 0x284860, 0x385880, 0x5070B0, 0x6080D0, 0x70B0E8, 0x74BCE8, 0x7CB8E8].map(hexToRGB)

/// Asr → Maghrib: blue → red sunset (exact match web ASR_PALETTE)
private let ASR_PALETTE: [RGB] = [0x7CB8E8, 0x78B0E0, 0x80A8D8, 0x88A0D0, 0x9098C8, 0x9890C0, 0xA088B8, 0xA880A8, 0xB07898, 0xB87088, 0xC06878, 0xC86068, 0xD05858, 0xD85048, 0xC84A3A].map(hexToRGB)

/// Mirror gradient (night span): black → yellow → blue (matches web 22-stop, simplified to 14)
private let MIRROR_PALETTE: [RGB] = [0x000000, 0x080808, 0x282008, 0x585028, 0x887040, 0xB89050, 0xE8C060, 0xE8D070, 0xC8D090, 0xA8D0B0, 0x88D0D0, 0x74C4E8, 0x7CB8E8].map(hexToRGB)

private let DAY_BLUE_RGB = hexToRGB(0x7CB8E8)
private let NIGHT_BLACK_RGB = hexToRGB(0x000000)

fileprivate func getPaletteForSegment(_ phase: IslamicPhaseId) -> [RGB] {
    switch phase {
    case .maghrib_to_isha: return MAGHRIB_PALETTE
    case .isha_to_last_third: return [NIGHT_BLACK_RGB]
    case .last_third_to_fajr: return [NIGHT_BLACK_RGB]
    case .fajr_to_sunrise: return FAJR_SUNRISE_PALETTE
    case .sunrise_to_dhuhr: return [DAY_BLUE_RGB]
    case .dhuhr_to_asr: return [DAY_BLUE_RGB]
    case .asr_to_maghrib: return ASR_PALETTE
    }
}

private func lerpRGB(_ a: RGB, _ b: RGB, t: Double) -> RGB {
    let tt = max(0, min(1, t))
    return (
        a.r + (b.r - a.r) * tt,
        a.g + (b.g - a.g) * tt,
        a.b + (b.b - a.b) * tt
    )
}

private func rgbAtT(_ palette: [RGB], t: Double) -> Color {
    guard !palette.isEmpty else { return Color.black }
    guard palette.count > 1 else { return rgbToColor(palette[0]) }
    let idx = t * Double(palette.count - 1)
    let i0 = Int(idx)
    let i1 = min(i0 + 1, palette.count - 1)
    return rgbToColor(lerpRGB(palette[i0], palette[i1], t: idx - Double(i0)))
}

private func normAngle(_ a: Double) -> Double {
    var x = a.truncatingRemainder(dividingBy: 360)
    if x < 0 { x += 360 }
    return x
}

private func isInAngleRange(angle: Double, startDeg: Double, spanDeg: Double) -> Bool {
    let diff = normAngle(angle - startDeg)
    return diff < spanDeg
}

/// Mirror segment: Fajr span uses reversed Asr→Isha gradient (red→blue)
struct MirrorSegment {
    let startAngleDeg: Double
    let spanDeg: Double
}

/// Color at a given angle (0° = top, clockwise). Shared logic for buildAngularGradientStops.
private func colorAtAngle(
    _ midAngle: Double,
    segments: [(id: IslamicPhaseId, startAngleDeg: Double, endAngleDeg: Double)],
    mirrorSegment: MirrorSegment?
) -> Color {
    let lookupAngle = midAngle >= 360 ? 0 : midAngle
    if let mirror = mirrorSegment, isInAngleRange(angle: lookupAngle, startDeg: mirror.startAngleDeg, spanDeg: mirror.spanDeg) {
        let span = mirror.spanDeg > 0 ? mirror.spanDeg : 1
        let t = normAngle(lookupAngle - mirror.startAngleDeg) / span
        let clampedT = max(0, min(1, t))
        return rgbAtT(MIRROR_PALETTE, t: clampedT)
    }
    var seg: (id: IslamicPhaseId, start: Double, end: Double)?
    for s in segments {
        let inSegment: Bool
        if s.endAngleDeg > 360 {
            let wrapEnd = s.endAngleDeg - 360
            inSegment = (lookupAngle >= s.startAngleDeg && lookupAngle < 360) || (lookupAngle >= 0 && lookupAngle < wrapEnd)
        } else if s.endAngleDeg >= s.startAngleDeg {
            inSegment = lookupAngle >= s.startAngleDeg && lookupAngle < s.endAngleDeg
        } else {
            inSegment = (lookupAngle >= s.startAngleDeg && lookupAngle < 360) || (lookupAngle >= 0 && lookupAngle < s.endAngleDeg)
        }
        if inSegment {
            seg = (s.id, s.startAngleDeg, s.endAngleDeg)
            break
        }
    }
    let palette = seg.map { getPaletteForSegment($0.id) } ?? [NIGHT_BLACK_RGB]
    var t: Double = 0
    if let s = seg {
        let span = s.end >= s.start ? (s.end - s.start) : (360 - s.start + s.end)
        if span > 0 {
            if s.end > 360 {
                t = lookupAngle >= s.start
                    ? (lookupAngle - s.start) / span
                    : (360 - s.start + lookupAngle) / span
            } else if s.end >= s.start {
                t = (lookupAngle - s.start) / span
            } else {
                t = lookupAngle >= s.start
                    ? (lookupAngle - s.start) / span
                    : (360 - s.start + lookupAngle) / span
            }
            t = max(0, min(1, t))
        }
    }
    return rgbAtT(palette, t: t)
}

/// Gradient stops for AngularGradient. Web 0° = top, location 0. Sample every 1° for smooth gradient, no seam at Maghrib.
func buildAngularGradientStops(
    segments: [(id: IslamicPhaseId, startAngleDeg: Double, endAngleDeg: Double)],
    mirrorSegment: MirrorSegment?
) -> [Gradient.Stop] {
    let step: Double = 1
    var stops: [Gradient.Stop] = []
    var angle: Double = 0
    while angle < 360 {
        let color = colorAtAngle(angle, segments: segments, mirrorSegment: mirrorSegment)
        stops.append(Gradient.Stop(color: color, location: angle / 360))
        angle += step
    }
    stops.append(Gradient.Stop(color: colorAtAngle(0, segments: segments, mirrorSegment: mirrorSegment), location: 1.0))
    return stops
}
