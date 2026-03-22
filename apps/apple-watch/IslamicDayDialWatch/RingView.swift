import SwiftUI

private let ROLL_ZONE_DEG: Double = 10
private let RED_SUN_ZONE_DEG: Double = 8
private let MIN_REVEAL: Double = 0.12
private let SUN_PHASES: Set<IslamicPhaseId> = [.sunrise_to_dhuhr, .dhuhr_to_asr, .asr_to_maghrib]
private let MOON_ONLY_PHASES: Set<IslamicPhaseId> = [.maghrib_to_isha, .isha_to_midnight, .last_third_to_fajr, .fajr_to_sunrise]
private let GAP_SEGMENT_IDS: Set<IslamicPhaseId> = [.last_third_to_fajr]
private let NIGHT_SECTORS_GROUP: Set<IslamicPhaseId> = [.isha_to_midnight, .last_third_to_fajr]
private let PRIMARY_MARKER_IDS: Set<String> = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
private let SECONDARY_MARKER_IDS: Set<String> = ["sunrise", "last_third_start", "duha_start", "duha_end"]
private let MOON_INNER_R: Double = 0.82

private struct MoonPhaseParams {
    let shadowOffset: Double
}

private func getMoonPhaseByHijriDay(_ day: Int) -> MoonPhaseParams {
    let d = max(1, min(30, day))
    switch d {
    case 1...3:
        return MoonPhaseParams(shadowOffset: -0.18)
    case 4...7:
        return MoonPhaseParams(shadowOffset: -0.5)
    case 8...10:
        return MoonPhaseParams(shadowOffset: -1.0)
    case 11...13:
        return MoonPhaseParams(shadowOffset: -1.35)
    case 14...16:
        return MoonPhaseParams(shadowOffset: 0)
    case 17...20:
        return MoonPhaseParams(shadowOffset: 1.35)
    case 21...23:
        return MoonPhaseParams(shadowOffset: 1.0)
    case 24...27:
        return MoonPhaseParams(shadowOffset: 0.5)
    default:
        return MoonPhaseParams(shadowOffset: 0.18)
    }
}

private func normAngle(_ a: Double) -> Double {
    var x = a.truncatingRemainder(dividingBy: 360)
    if x < 0 { x += 360 }
    return x
}

/// Roll-out (Sunrise) / roll-in (Maghrib) — port of web getBlackDiskReveal
private func getBlackDiskReveal(
    progressAngle: Double,
    sunriseAngleDeg: Double,
    maghribAngleDeg: Double,
    isMoonOnlySector: Bool
) -> (reveal: Double, boundaryAngle: Double, isRollIn: Bool, isInRedZone: Bool) {
    let pa = normAngle(progressAngle)
    let sun = normAngle(sunriseAngleDeg)
    let mag = normAngle(maghribAngleDeg)

    if isMoonOnlySector {
        return (0, 0, false, false)
    }

    let rollOutEndRaw = sun + ROLL_ZONE_DEG
    if rollOutEndRaw <= 360 {
        if pa >= sun && pa <= rollOutEndRaw {
            let raw = (pa - sun) / ROLL_ZONE_DEG
            return (max(MIN_REVEAL, min(1, raw)), sun, false, false)
        }
    } else {
        if pa >= sun {
            let raw = (pa - sun) / ROLL_ZONE_DEG
            return (max(MIN_REVEAL, min(1, raw)), sun, false, false)
        }
        if pa <= rollOutEndRaw - 360 {
            let raw = (pa + 360 - sun) / ROLL_ZONE_DEG
            return (max(MIN_REVEAL, min(1, raw)), sun, false, false)
        }
    }
    let rollInStart = normAngle(mag - ROLL_ZONE_DEG)
    let distToMag = normAngle(mag - pa)
    let inRedZone = distToMag <= RED_SUN_ZONE_DEG
    if rollInStart > mag && pa >= rollInStart {
        let raw = (360 - pa) / ROLL_ZONE_DEG
        return (max(MIN_REVEAL, min(1, raw)), mag, true, inRedZone)
    }
    if rollInStart <= mag && pa >= rollInStart && pa <= mag {
        let raw = (mag - pa) / ROLL_ZONE_DEG
        return (max(MIN_REVEAL, min(1, raw)), mag, true, inRedZone)
    }
    return (1, 0, false, false)
}

private enum SunRenderStyle {
    case normal
    case sunrise
    case midday
    case maghrib
}

enum RingRenderVariant {
    case watch
    case phone
}

private struct SunMarkerStyle {
    let style: SunRenderStyle
    let color: Color
    let glowColor: Color
    let strongGlow: Bool
}

struct RingView: View {
    let snapshot: ComputedIslamicDay
    var now: Date = Date()
    var thicknessScale: CGFloat = 1
    var renderVariant: RingRenderVariant = .watch
    
    private var progressAngle: Double { snapshot.ringProgress * 360 }
    
    /// Mirrors web CurrentMarker styles: sunrise orange, maghrib red, otherwise yellow.
    private func sunMarkerState() -> SunMarkerStyle? {
        guard SUN_PHASES.contains(snapshot.currentPhase) else { return nil }
        let maghribAngle = snapshot.ringMarkers.first { $0.id == "maghrib" }?.angleDeg ?? 0
        let distToMag = normAngle(maghribAngle - progressAngle)
        
        // Web maghrib zone: red disk + red glow.
        if distToMag <= RED_SUN_ZONE_DEG {
            return SunMarkerStyle(style: .maghrib, color: SUN_RED, glowColor: SUN_RED, strongGlow: true)
        }
        // Web sunrise sub-period: orange disk + orange glow.
        if snapshot.currentPhase == .sunrise_to_dhuhr {
            let sub = getSunriseToDhuhrSubPeriod(now: now, sunrise: snapshot.timeline.sunrise, dhuhr: snapshot.timeline.dhuhr)
            if sub == .sunrise {
                return SunMarkerStyle(style: .sunrise, color: SUN_ORANGE, glowColor: SUN_ORANGE, strongGlow: true)
            }
            if sub == .midday, renderVariant == .phone {
                return SunMarkerStyle(
                    style: .midday,
                    color: Color(red: 0.83, green: 0.63, blue: 0.09),
                    glowColor: Color(red: 0.96, green: 0.69, blue: 0.14),
                    strongGlow: true
                )
            }
        }
        return SunMarkerStyle(style: .normal, color: SUN_NORMAL, glowColor: SUN_NORMAL, strongGlow: false)
    }

    var body: some View {
        GeometryReader { geo in
            let cs = min(geo.size.width, geo.size.height)
            let cStroke = cs * 0.081 * thicknessScale
            let cInner = cs * 0.25125
            let cr = cInner + cStroke / 2
            
            let displaySegments: [(id: IslamicPhaseId, startAngleDeg: Double, endAngleDeg: Double)] = snapshot.ringSegments.map {
                (id: $0.id, startAngleDeg: $0.startAngleDeg, endAngleDeg: $0.endAngleDeg)
            }
            let asrMarker = snapshot.ringMarkers.first { $0.id == "asr" }
            let ishaMarker = snapshot.ringMarkers.first { $0.id == "isha" }
            let fajrMarker = snapshot.ringMarkers.first { $0.id == "fajr" }
            let mirrorSegment: MirrorSegment? = {
                guard let asr = asrMarker, let isha = ishaMarker, let fajr = fajrMarker else { return nil }
                let asrToIshaSpanDeg = (360 - asr.angleDeg) + isha.angleDeg
                return MirrorSegment(startAngleDeg: fajr.angleDeg, spanDeg: asrToIshaSpanDeg)
            }()
            let gradientStops = buildAngularGradientStops(segments: displaySegments, mirrorSegment: mirrorSegment)
            
            ZStack(alignment: .center) {
                // Ring: single smooth AngularGradient (no sub-arc seams). SwiftUI 0°=right; web 0°=top → startAngle -90°
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: gradientStops),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: cStroke, lineCap: .butt, lineJoin: .miter)
                    )
                    .frame(width: cr * 2, height: cr * 2)
                
                Canvas { context, canvasSize in
                    let csCanvas = min(canvasSize.width, canvasSize.height)
                    let ccx = canvasSize.width / 2
                    let ccy = canvasSize.height / 2
                    let tickStrokeWidth: CGFloat = 1.2
                    let tickStyle = StrokeStyle(lineWidth: tickStrokeWidth, lineCap: .butt, lineJoin: .miter)
                    let tickLen = csCanvas * 0.0125
                    let cInnerCanvas = csCanvas * 0.25125
                    let tickStartR = cInnerCanvas - Double(tickStrokeWidth) / 2
                    let tickEndR = tickStartR - Double(tickLen)
                    for m in snapshot.ringMarkers {
                        guard PRIMARY_MARKER_IDS.contains(m.id) || SECONDARY_MARKER_IDS.contains(m.id) else { continue }
                        let innerPt = polarToXY(cx: ccx, cy: ccy, r: tickStartR, angleDeg: m.angleDeg)
                        let outerPt = polarToXY(cx: ccx, cy: ccy, r: tickEndR, angleDeg: m.angleDeg)
                        var linePath = Path()
                        linePath.move(to: innerPt)
                        linePath.addLine(to: outerPt)
                        context.stroke(linePath, with: .color(MARKER_STROKE), style: tickStyle)
                    }
                }
                .overlay {
                    CurrentMarkerOverlay(
                        snapshot: snapshot,
                        now: now,
                        progressAngle: progressAngle,
                        sunMarkerState: sunMarkerState(),
                        thicknessScale: thicknessScale,
                        size: cs
                    )
                }
            }
            .frame(width: cs, height: cs)
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }
}

// MARK: - Current Marker Overlay (sun clipping + moon crescent without black)
private struct CurrentMarkerOverlay: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let progressAngle: Double
    let sunMarkerState: SunMarkerStyle?
    let thicknessScale: CGFloat
    let size: CGFloat

    private var isNight: Bool { MOON_ONLY_PHASES.contains(snapshot.currentPhase) }
    private var markerR: CGFloat { size * 0.033 * thicknessScale }
    private var ccx: CGFloat { size / 2 }
    private var ccy: CGFloat { size / 2 }
    private var cr: CGFloat {
        let cInner = size * 0.25125
        let cStroke = size * 0.081 * thicknessScale
        return cInner + cStroke / 2
    }
    private var markerCenter: CGPoint {
        polarToXY(cx: Double(ccx), cy: Double(ccy), r: Double(cr), angleDeg: progressAngle)
    }

    private var sunriseAngle: Double {
        snapshot.ringMarkers.first { $0.id == "sunrise" }?.angleDeg ?? 0
    }
    private var maghribAngle: Double {
        snapshot.ringMarkers.first { $0.id == "maghrib" }?.angleDeg ?? 0
    }

    private var revealResult: (reveal: Double, boundaryAngle: Double, isRollIn: Bool, isInRedZone: Bool) {
        getBlackDiskReveal(
            progressAngle: progressAngle,
            sunriseAngleDeg: sunriseAngle,
            maghribAngleDeg: maghribAngle,
            isMoonOnlySector: isNight
        )
    }

    var body: some View {
        ZStack {
            Color.clear
            markerContent
                .position(x: markerCenter.x, y: markerCenter.y)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var markerContent: some View {
        if isNight {
            moonView
        } else if let state = sunMarkerState {
            sunView(state: state)
        }
    }

    private var boundaryPoint: CGPoint {
        polarToXY(cx: Double(ccx), cy: Double(ccy), r: Double(cr), angleDeg: revealResult.boundaryAngle)
    }

    @ViewBuilder
    private func sunView(state: SunMarkerStyle) -> some View {
        let (reveal, boundaryAngle, isRollIn, _) = revealResult
        if reveal > 0 {
            SunCanvasView(
                state: state,
                markerR: markerR,
                reveal: reveal,
                boundaryAngle: boundaryAngle,
                isRollIn: isRollIn,
                markerCenter: markerCenter,
                boundaryPoint: isRollIn ? boundaryPoint : nil,
                dialCenter: CGPoint(x: ccx, y: ccy)
            )
        }
    }

    @ViewBuilder
    private var moonView: some View {
        let moonPhase = getMoonPhaseByHijriDay(snapshot.hijriDate.day)
        let innerMoonR = markerR * MOON_INNER_R

        let moonContent = Circle()
            .fill(MOON_LUNAR)
            .frame(width: innerMoonR * 2, height: innerMoonR * 2)

        if moonPhase.shadowOffset == 0 {
            moonContent
        } else {
            // Crescent mask (port of web): white = visible, shadow area = transparent → ring shows through.
            // destinationOut cuts shadow circle from white → crescent-shaped mask.
            moonContent.mask(
                ZStack {
                    Circle().fill(.white)
                    Circle()
                        .fill(.white)
                        .frame(width: innerMoonR * 2, height: innerMoonR * 2)
                        .offset(x: innerMoonR * moonPhase.shadowOffset)
                        .blendMode(.destinationOut)
                }
                .frame(width: innerMoonR * 2, height: innerMoonR * 2)
            )
        }
    }
}

// MARK: - Sun marker mirroring web layering
private struct SunCanvasView: View {
    let state: SunMarkerStyle
    let markerR: CGFloat
    let reveal: Double
    let boundaryAngle: Double
    let isRollIn: Bool
    let markerCenter: CGPoint
    let boundaryPoint: CGPoint?
    let dialCenter: CGPoint

    private let contentSize: CGFloat

    init(state: SunMarkerStyle, markerR: CGFloat, reveal: Double, boundaryAngle: Double, isRollIn: Bool, markerCenter: CGPoint, boundaryPoint: CGPoint?, dialCenter: CGPoint) {
        self.state = state
        self.markerR = markerR
        self.reveal = reveal
        self.boundaryAngle = boundaryAngle
        self.isRollIn = isRollIn
        self.markerCenter = markerCenter
        self.boundaryPoint = boundaryPoint
        self.dialCenter = dialCenter
        self.contentSize = markerR * 5.6
    }

    var body: some View {
        ZStack {
            outerGlow
            maskedSun
        }
        .frame(width: contentSize, height: contentSize)
    }

    private var outerGlow: some View {
        let strokeWidth = state.strongGlow ? markerR * 1.7 : markerR * 1.15
        let blurRadius = state.strongGlow ? markerR * 0.65 : markerR * 0.4
        let opacity = state.strongGlow ? 0.9 : 0.35

        return Circle()
            .stroke(state.glowColor.opacity(opacity), lineWidth: strokeWidth)
            .frame(width: markerR * 2, height: markerR * 2)
            .blur(radius: blurRadius)
    }

    private var maskedSun: some View {
        ZStack {
            Circle()
                .stroke(glowStrokeGradient, lineWidth: state.strongGlow ? markerR * 1.45 : markerR * 1.0)
                .frame(width: markerR * 2, height: markerR * 2)
                .blur(radius: state.strongGlow ? markerR * 0.35 : markerR * 0.2)
                .opacity(state.strongGlow ? 0.35 : 0.22)

            Circle()
                .stroke(glowStrokeGradient, lineWidth: state.strongGlow ? markerR * 1.7 : markerR * 1.15)
                .frame(width: markerR * 2, height: markerR * 2)
                .blur(radius: state.strongGlow ? markerR * 0.5 : markerR * 0.28)
                .opacity(state.strongGlow ? 0.7 : 0.3)

            Circle()
                .fill(fillGradient)
                .frame(width: markerR * 2, height: markerR * 2)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 0.5)
                )
                .shadow(
                    color: state.glowColor.opacity(state.strongGlow ? 0.45 : 0.18),
                    radius: state.strongGlow ? markerR * 1.8 : markerR
                )
                .shadow(
                    color: state.glowColor.opacity(state.strongGlow ? 0.28 : 0.1),
                    radius: state.strongGlow ? markerR * 0.8 : markerR * 0.45,
                    x: state.strongGlow ? markerR * 0.35 : 0,
                    y: state.strongGlow ? markerR * 0.35 : 0
                )
        }
        .frame(width: contentSize, height: contentSize)
        .mask(
            Circle()
                .frame(width: markerR * 2, height: markerR * 2)
        )
        .modifier(
            SunClipModifier(
                reveal: reveal,
                boundaryAngle: boundaryAngle,
                isRollIn: isRollIn,
                r: markerR,
                markerCenter: markerCenter,
                boundaryPoint: boundaryPoint,
                dialCenter: dialCenter
            )
        )
    }

    private var fillGradient: RadialGradient {
        switch state.style {
        case .sunrise:
            return RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: Color(red: 1.0, green: 0.93, blue: 0.85), location: 0.15),
                    .init(color: Color(red: 1.0, green: 0.72, blue: 0.30), location: 0.45),
                    .init(color: SUN_ORANGE, location: 1),
                ]),
                center: .center,
                startRadius: 0,
                endRadius: markerR
            )
        case .midday:
            return RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: Color(red: 1.0, green: 0.96, blue: 0.84), location: 0.15),
                    .init(color: Color(red: 1.0, green: 0.84, blue: 0.31), location: 0.45),
                    .init(color: Color(red: 0.83, green: 0.63, blue: 0.09), location: 1),
                ]),
                center: .center,
                startRadius: 0,
                endRadius: markerR
            )
        case .maghrib:
            return RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: Color(red: 1.0, green: 0.84, blue: 0.84), location: 0.15),
                    .init(color: Color(red: 1.0, green: 0.42, blue: 0.42), location: 0.45),
                    .init(color: SUN_RED, location: 1),
                ]),
                center: .center,
                startRadius: 0,
                endRadius: markerR
            )
        case .normal:
            return RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: Color(red: 1.0, green: 0.99, blue: 0.91), location: 0.3),
                    .init(color: Color(red: 1.0, green: 0.96, blue: 0.62), location: 0.6),
                    .init(color: SUN_NORMAL, location: 1),
                ]),
                center: .center,
                startRadius: 0,
                endRadius: markerR
            )
        }
    }

    private var glowStrokeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.white.opacity(0.9), borderColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        switch state.style {
        case .sunrise:
            return SUN_ORANGE
        case .midday:
            return Color(red: 0.83, green: 0.63, blue: 0.09)
        case .maghrib:
            return SUN_RED
        case .normal:
            return Color(red: 1.0, green: 0.63, blue: 0.0)
        }
    }
}

// MARK: - Sun clip mask (roll-out Sunrise / roll-in Maghrib) — legacy, kept for reference
private struct SunClipModifier: ViewModifier {
    let reveal: Double
    let boundaryAngle: Double
    let isRollIn: Bool
    let r: CGFloat
    let markerCenter: CGPoint
    let boundaryPoint: CGPoint?  // For roll-in (Maghrib): point on ring at boundary
    let dialCenter: CGPoint     // For roll-out (Sunrise): cut through dial center

    func body(content: Content) -> some View {
        if reveal >= 1 {
            content
        } else {
            let contentSize = r * 5.6
            content.mask(SunClipMaskView(
                reveal: reveal,
                boundaryAngle: boundaryAngle,
                isRollIn: isRollIn,
                r: r,
                markerCenter: markerCenter,
                boundaryPoint: boundaryPoint,
                dialCenter: dialCenter,
                contentSize: contentSize
            ))
        }
    }
}

/// Separate view so it receives correct geometry in mask context
private struct SunClipMaskView: View {
    let reveal: Double
    let boundaryAngle: Double
    let isRollIn: Bool
    let r: CGFloat
    let markerCenter: CGPoint
    let boundaryPoint: CGPoint?
    let dialCenter: CGPoint
    let contentSize: CGFloat

    var body: some View {
        let cs = contentSize
        let tanRad = boundaryAngle * .pi / 180
        let tanX = cos(tanRad)
        let tanY = sin(tanRad)
        let lenSq = tanX * tanX + tanY * tanY
        let k = r * 2

        let (deltaX, deltaY): (CGFloat, CGFloat) = if isRollIn, let bound = boundaryPoint {
            (bound.x - markerCenter.x, bound.y - markerCenter.y)
        } else {
            (dialCenter.x - markerCenter.x, dialCenter.y - markerCenter.y)
        }

        let shift: CGFloat = if lenSq > 0.001 {
            if isRollIn, boundaryPoint != nil {
                CGFloat((Double(tanX) * Double(deltaX) + Double(tanY) * Double(deltaY) - Double(k) * (2 * reveal - 1)) / Double(lenSq))
            } else {
                CGFloat((Double(tanX) * Double(deltaX) + Double(tanY) * Double(deltaY)) / Double(lenSq) - Double(k) * (1 - 2 * reveal))
            }
        } else { 0 }

        let dx = shift * tanX
        let dy = shift * tanY
        let dxUnit = dx / cs
        let dyUnit = dy / cs

        let startX = 0.5 - 0.5 * tanX + dxUnit
        let startY = 0.5 - 0.5 * tanY + dyUnit
        let endX = 0.5 + 0.5 * tanX + dxUnit
        let endY = 0.5 + 0.5 * tanY + dyUnit

        let stops: [Gradient.Stop] = isRollIn
            ? [.init(color: .white, location: 0), .init(color: .white, location: reveal), .init(color: .black, location: reveal), .init(color: .black, location: 1)]
            : [.init(color: .black, location: 0), .init(color: .black, location: 1 - reveal), .init(color: .white, location: 1 - reveal), .init(color: .white, location: 1)]

        Rectangle()
            .fill(LinearGradient(gradient: Gradient(stops: stops), startPoint: UnitPoint(x: startX, y: startY), endPoint: UnitPoint(x: endX, y: endY)))
            .frame(width: contentSize, height: contentSize)
    }
}
