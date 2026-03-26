import SwiftUI

private let ROLL_ZONE_DEG: Double = 10
private let RED_SUN_ZONE_DEG: Double = 8
private let MIN_REVEAL: Double = 0.12
private let SUN_PHASES: Set<IslamicPhaseId> = [.sunrise_to_dhuhr, .dhuhr_to_asr, .asr_to_maghrib]
private let MOON_ONLY_PHASES: Set<IslamicPhaseId> = [.maghrib_to_isha, .isha_to_last_third, .last_third_to_fajr, .fajr_to_sunrise]
private let GAP_SEGMENT_IDS: Set<IslamicPhaseId> = [.last_third_to_fajr]
private let NIGHT_SECTORS_GROUP: Set<IslamicPhaseId> = [.isha_to_last_third, .last_third_to_fajr]
private let PRIMARY_MARKER_IDS: Set<String> = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
private let SECONDARY_MARKER_IDS: Set<String> = ["sunrise", "last_third_start", "duha_start", "duha_end"]
private let PHONE_HIDDEN_TICK_IDS: Set<String> = ["duha_start", "duha_end"]
private let MOON_INNER_R: Double = 0.82
private let GLOW_PULSE_DURATION: Double = 3.0  // Full cycle like web (base↔peak↔base)
private let PHONE_INFO_RADIUS_EXPANSION_RATIO: CGFloat = 10 / 420

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

enum PhoneRingArcKind: String {
    case maghribToIsha = "maghrib_to_isha"
    case ishaGroup = "isha_group"
    case fajrToSunrise = "fajr_to_sunrise"
    case sunrise = "sunrise"
    case duha = "duha"
    case midday = "midday"
    case dhuhrToAsr = "dhuhr_to_asr"
    case asrToMaghrib = "asr_to_maghrib"
}

struct PhoneRingArcSpec: Identifiable {
    let kind: PhoneRingArcKind
    let originalStartAngleDeg: CGFloat
    let originalEndAngleDeg: CGFloat
    let startAngleDeg: CGFloat
    let endAngleDeg: CGFloat

    var id: String { kind.rawValue }
}

private struct PhoneRingArcShape: Shape {
    var radius: CGFloat
    var startAngleDeg: CGFloat
    var endAngleDeg: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(radius, AnimatablePair(startAngleDeg, endAngleDeg)) }
        set {
            radius = newValue.first
            startAngleDeg = newValue.second.first
            endAngleDeg = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        arcPath(
            cx: Double(rect.midX),
            cy: Double(rect.midY),
            r: Double(radius),
            startDeg: Double(startAngleDeg),
            endDeg: Double(endAngleDeg)
        )
    }
}

private func angleSpan(startDeg: CGFloat, endDeg: CGFloat) -> CGFloat {
    let raw = endDeg - startDeg
    return raw >= 0 ? raw : raw + 360
}

func adjustedPhoneMarkerAngle(phoneArcSpecs: [PhoneRingArcSpec], originalAngle: Double) -> Double {
    let lookupAngle = CGFloat(originalAngle >= 360 ? 0 : originalAngle)

    for spec in phoneArcSpecs {
        let originalSpan = angleSpan(startDeg: spec.originalStartAngleDeg, endDeg: spec.originalEndAngleDeg)
        guard originalSpan > 0 else { continue }

        let traveled = angleSpan(startDeg: spec.originalStartAngleDeg, endDeg: lookupAngle)
        guard traveled <= originalSpan + 0.001 else { continue }

        let t = traveled / originalSpan
        let adjustedSpan = angleSpan(startDeg: spec.startAngleDeg, endDeg: spec.endAngleDeg)
        return Double(spec.startAngleDeg + adjustedSpan * t)
    }

    return originalAngle
}

private func adjustedArcBounds(startDeg: CGFloat, endDeg: CGFloat, radiusScale: CGFloat) -> (start: CGFloat, end: CGFloat) {
    let span = angleSpan(startDeg: startDeg, endDeg: endDeg)
    let midpoint = startDeg + span / 2
    let adjustedSpan = span * radiusScale
    return (midpoint - adjustedSpan / 2, midpoint + adjustedSpan / 2)
}

func expandedPhoneRingRadius(baseRadius: CGFloat, size: CGFloat, infoProgress: Double) -> CGFloat {
    baseRadius + size * PHONE_INFO_RADIUS_EXPANSION_RATIO * CGFloat(max(0, min(1, infoProgress)))
}

private func phoneQuakeMetrics(date: Date, progress: Double, size: CGFloat) -> (x: CGFloat, y: CGFloat, rotation: Double) {
    let clamped = max(0, min(1, progress))
    let envelope = pow(max(0, sin(clamped * .pi)), 0.42)
    guard envelope > 0.001 else { return (0, 0, 0) }

    let time = date.timeIntervalSinceReferenceDate
    let amplitude = size * (13.5 / 420) * CGFloat(envelope)
    let x = CGFloat(
        sin(time * 71) +
        sin(time * 123) * 0.92 +
        cos(time * 187) * 0.56 +
        sin(time * 251) * 0.22
    ) * amplitude
    let y = CGFloat(
        cos(time * 79) +
        sin(time * 141) * 0.88 +
        cos(time * 211) * 0.48 +
        sin(time * 269) * 0.2
    ) * amplitude * 1.06
    let rotation = Double(
        sin(time * 67) +
        cos(time * 129) * 0.78 +
        sin(time * 203) * 0.32
    ) * Double(envelope) * 1.25
    return (x, y, rotation)
}

func buildPhoneRingArcSpecs(
    snapshot: ComputedIslamicDay,
    baseRadius: CGFloat,
    ringRadius: CGFloat
) -> [PhoneRingArcSpec] {
    let byId = Dictionary(uniqueKeysWithValues: snapshot.ringSegments.map { ($0.id, $0) })
    guard
        let maghribToIsha = byId[.maghrib_to_isha],
        let ishaToLastThird = byId[.isha_to_last_third],
        let lastThirdToFajr = byId[.last_third_to_fajr],
        let fajrToSunrise = byId[.fajr_to_sunrise],
        let dhuhrToAsr = byId[.dhuhr_to_asr],
        let asrToMaghrib = byId[.asr_to_maghrib]
    else {
        return []
    }

    let radiusScale = baseRadius / max(ringRadius, baseRadius)
    let timeline = snapshot.timeline

    func angle(for timestamp: Date) -> Double {
        timestampToAngle(
            timestamp: timestamp,
            lastMaghrib: timeline.lastMaghrib,
            nextMaghrib: timeline.nextMaghrib
        )
    }

    func makeSpec(kind: PhoneRingArcKind, start: Double, end: Double) -> PhoneRingArcSpec {
        let adjusted = adjustedArcBounds(
            startDeg: CGFloat(start),
            endDeg: CGFloat(end),
            radiusScale: radiusScale
        )
        return PhoneRingArcSpec(
            kind: kind,
            originalStartAngleDeg: CGFloat(start),
            originalEndAngleDeg: CGFloat(end),
            startAngleDeg: adjusted.start,
            endAngleDeg: adjusted.end
        )
    }

    return [
        makeSpec(kind: .maghribToIsha, start: maghribToIsha.startAngleDeg, end: maghribToIsha.endAngleDeg),
        makeSpec(kind: .ishaGroup, start: ishaToLastThird.startAngleDeg, end: lastThirdToFajr.endAngleDeg),
        makeSpec(kind: .fajrToSunrise, start: fajrToSunrise.startAngleDeg, end: fajrToSunrise.endAngleDeg),
        makeSpec(kind: .sunrise, start: angle(for: timeline.sunrise), end: angle(for: timeline.duhaStart)),
        makeSpec(kind: .duha, start: angle(for: timeline.duhaStart), end: angle(for: timeline.duhaEnd)),
        makeSpec(kind: .midday, start: angle(for: timeline.duhaEnd), end: angle(for: timeline.dhuhr)),
        makeSpec(kind: .dhuhrToAsr, start: dhuhrToAsr.startAngleDeg, end: dhuhrToAsr.endAngleDeg),
        makeSpec(kind: .asrToMaghrib, start: asrToMaghrib.startAngleDeg, end: asrToMaghrib.endAngleDeg),
    ]
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
    var phoneInfoProgress: Double = 0
    
    private var currentPhase: IslamicPhaseId {
        getCurrentPhase(now: now, timeline: snapshot.timeline)
    }

    private var progressAngle: Double {
        getIslamicDayProgress(
            now: now,
            lastMaghrib: snapshot.timeline.lastMaghrib,
            nextMaghrib: snapshot.timeline.nextMaghrib
        ) * 360
    }
    
    /// Mirrors web CurrentMarker styles: sunrise orange, maghrib red, otherwise yellow.
    private func sunMarkerState() -> SunMarkerStyle? {
        guard SUN_PHASES.contains(currentPhase) else { return nil }
        let maghribAngle = snapshot.ringMarkers.first { $0.id == "maghrib" }?.angleDeg ?? 0
        let distToMag = normAngle(maghribAngle - progressAngle)
        
        // Web maghrib zone: red disk + red glow.
        if distToMag <= RED_SUN_ZONE_DEG {
            return SunMarkerStyle(style: .maghrib, color: SUN_RED, glowColor: SUN_RED, strongGlow: true)
        }
        // Web sunrise sub-period: orange disk + orange glow.
        if currentPhase == .sunrise_to_dhuhr {
            let sub = getSunriseToDhuhrSubPeriod(now: now, duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr)
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
            let baseRingRadius = cInner + cStroke / 2
            let ringRadius = renderVariant == .phone
                ? expandedPhoneRingRadius(baseRadius: baseRingRadius, size: cs, infoProgress: phoneInfoProgress)
                : baseRingRadius
            
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
            let ringGradient = AngularGradient(
                gradient: Gradient(stops: gradientStops),
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
            let phoneArcSpecs = renderVariant == .phone
                ? buildPhoneRingArcSpecs(snapshot: snapshot, baseRadius: baseRingRadius, ringRadius: ringRadius)
                : []
            let markerAngle = renderVariant == .phone
                ? adjustedPhoneMarkerAngle(phoneArcSpecs: phoneArcSpecs, originalAngle: progressAngle)
                : progressAngle
            let tickOpacity = renderVariant == .phone
                ? max(0, 1 - phoneInfoProgress)
                : 1.0
            
            ZStack(alignment: .center) {
                if renderVariant == .phone {
                    ZStack(alignment: .center) {
                        PhoneNightGlowOverlay(
                            snapshot: snapshot,
                            now: now,
                            currentPhase: currentPhase,
                            size: cs,
                            thicknessScale: thicknessScale,
                            ringRadius: ringRadius,
                            phoneInfoProgress: phoneInfoProgress,
                            phoneArcSpecs: phoneArcSpecs
                        )

                        if !phoneArcSpecs.isEmpty {
                            ForEach(phoneArcSpecs) { spec in
                                PhoneRingArcShape(
                                    radius: ringRadius,
                                    startAngleDeg: spec.startAngleDeg,
                                    endAngleDeg: spec.endAngleDeg
                                )
                                .stroke(
                                    ringGradient,
                                    style: StrokeStyle(lineWidth: cStroke, lineCap: .butt, lineJoin: .miter)
                                )
                            }
                        } else {
                            Circle()
                                .stroke(
                                    ringGradient,
                                    style: StrokeStyle(lineWidth: cStroke, lineCap: .butt, lineJoin: .miter)
                                )
                                .frame(width: ringRadius * 2, height: ringRadius * 2)
                        }
                    }
                } else {
                    // Ring: single smooth AngularGradient (no sub-arc seams). SwiftUI 0°=right; web 0°=top → startAngle -90°
                    Circle()
                        .stroke(
                            ringGradient,
                            style: StrokeStyle(lineWidth: cStroke, lineCap: .butt, lineJoin: .miter)
                        )
                        .frame(width: baseRingRadius * 2, height: baseRingRadius * 2)
                }
                
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
                        let isHiddenPhoneTick = renderVariant == .phone && PHONE_HIDDEN_TICK_IDS.contains(m.id)
                        if isHiddenPhoneTick { continue }
                        guard PRIMARY_MARKER_IDS.contains(m.id) || SECONDARY_MARKER_IDS.contains(m.id) else { continue }
                        let innerPt = polarToXY(cx: ccx, cy: ccy, r: tickStartR, angleDeg: m.angleDeg)
                        let outerPt = polarToXY(cx: ccx, cy: ccy, r: tickEndR, angleDeg: m.angleDeg)
                        var linePath = Path()
                        linePath.move(to: innerPt)
                        linePath.addLine(to: outerPt)
                        context.stroke(linePath, with: .color(MARKER_STROKE), style: tickStyle)
                    }
                }
                .opacity(tickOpacity)

                CurrentMarkerOverlay(
                    snapshot: snapshot,
                    now: now,
                    currentPhase: currentPhase,
                    progressAngle: progressAngle,
                    markerAngle: markerAngle,
                    sunMarkerState: sunMarkerState(),
                    thicknessScale: thicknessScale,
                    size: cs,
                    renderVariant: renderVariant,
                    ringRadius: ringRadius
                )
            }
            .frame(width: cs, height: cs)
        }
        .aspectRatio(1, contentMode: .fill)
        // No .clipped(): marker sun rotates with large blur; axis-aligned clip caused straight "cuts" through the glow.
    }
}

/// Phase 0→1→0 over GLOW_PULSE_DURATION; sine-wave for smooth circular fade (no sharp corners)
private func glowPulsePhase(_ t: Date) -> (base: Double, phase: Double) {
    let sec = t.timeIntervalSince1970.truncatingRemainder(dividingBy: GLOW_PULSE_DURATION)
    let tNorm = sec / GLOW_PULSE_DURATION
    let phase = (sin(tNorm * 2 * .pi) + 1) / 2  // 0→1→0 smooth sine
    let base = 0.35 * (1 - phase)
    return (base, phase)
}

private struct PhoneNightGlowOverlay: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let currentPhase: IslamicPhaseId
    let size: CGFloat
    let thicknessScale: CGFloat
    let ringRadius: CGFloat
    let phoneInfoProgress: Double
    let phoneArcSpecs: [PhoneRingArcSpec]

    private var cStroke: CGFloat { size * 0.081 * thicknessScale }

    var body: some View {
        TimelineView(.animation) { timeline in
            let (base, phase) = glowPulsePhase(timeline.date)
            let jumuBase = base
            let jumuPeak = phase * 1.0
            let lastThirdBase = base
            let lastThirdPeak = phase * 0.92  // Slightly brighter and stronger

            let nightSegments = snapshot.ringSegments.filter { NIGHT_SECTORS_GROUP.contains($0.id) }
            let isInIsha = currentPhase == .isha_to_last_third
            let isInLastThird = currentPhase == .last_third_to_fajr
            let showJumuahGlow = phoneInfoProgress <= 0.001
                && isJumuahGlowWindow(now: now, timeline: snapshot.timeline, currentPhase: currentPhase)
            let duhaStartMarker = snapshot.ringMarkers.first { $0.id == "duha_start" }
            let dhuhrMarker = snapshot.ringMarkers.first { $0.id == "dhuhr" }
            let asrMarker = snapshot.ringMarkers.first { $0.id == "asr" }
            let showExpandedNightGroupGlow = phoneInfoProgress > 0.001
            let expandedNightGlowOpacity = 0.35 * CGFloat(phoneInfoProgress)
            let ishaGroupArc = phoneArcSpecs.first { $0.kind == .ishaGroup }

            ZStack {
                if showJumuahGlow,
                   let duhaStartMarker,
                   let dhuhrMarker,
                   let asrMarker {
                    let pathDuhaToDhuhr = arcPath(
                        cx: Double(size / 2),
                        cy: Double(size / 2),
                        r: Double(ringRadius),
                        startDeg: duhaStartMarker.angleDeg,
                        endDeg: dhuhrMarker.angleDeg
                    )
                    let pathDhuhrToAsr = arcPath(
                        cx: Double(size / 2),
                        cy: Double(size / 2),
                        r: Double(ringRadius),
                        startDeg: dhuhrMarker.angleDeg,
                        endDeg: asrMarker.angleDeg
                    )
                    let jumuColor = Color(red: 0.486, green: 0.722, blue: 0.910)
                    ZStack {
                        pathDuhaToDhuhr
                        .stroke(
                            jumuColor.opacity(jumuBase),
                            style: StrokeStyle(lineWidth: cStroke + size * (6 / 420), lineCap: .butt, lineJoin: .miter)
                        )
                        .blur(radius: size * (3 / 420))
                        pathDhuhrToAsr
                        .stroke(
                            jumuColor.opacity(jumuBase),
                            style: StrokeStyle(lineWidth: cStroke + size * (6 / 420), lineCap: .butt, lineJoin: .miter)
                        )
                        .blur(radius: size * (3 / 420))
                        pathDuhaToDhuhr
                        .stroke(
                            jumuColor.opacity(jumuPeak),
                            style: StrokeStyle(lineWidth: cStroke + size * (7 / 420), lineCap: .butt, lineJoin: .miter)
                        )
                        .blur(radius: size * (5 / 420))
                        pathDhuhrToAsr
                        .stroke(
                            jumuColor.opacity(jumuPeak),
                            style: StrokeStyle(lineWidth: cStroke + size * (7 / 420), lineCap: .butt, lineJoin: .miter)
                        )
                            .blur(radius: size * (5 / 420))
                    }
                }
                if showExpandedNightGroupGlow, let ishaGroupArc {
                    PhoneRingArcShape(
                        radius: ringRadius,
                        startAngleDeg: ishaGroupArc.startAngleDeg,
                        endAngleDeg: ishaGroupArc.endAngleDeg
                    )
                    .stroke(
                        Color(red: 0.231, green: 0.51, blue: 0.965).opacity(expandedNightGlowOpacity),
                        style: StrokeStyle(lineWidth: cStroke + size * (6 / 420), lineCap: .butt, lineJoin: .miter)
                    )
                    .blur(radius: size * (4 / 420))
                } else if isInIsha || isInLastThird {
                    ForEach(nightSegments.filter { isInIsha || $0.id == .isha_to_last_third || $0.id == .last_third_to_fajr }, id: \.id) { seg in
                        let path = arcPath(cx: Double(size / 2), cy: Double(size / 2), r: Double(ringRadius), startDeg: seg.startAngleDeg, endDeg: seg.endAngleDeg)
                        if seg.id == .last_third_to_fajr && isInLastThird {
                            let lastThirdColor = Color(red: 0.231, green: 0.51, blue: 0.965)
                            ZStack {
                                path
                                    .stroke(
                                        lastThirdColor.opacity(lastThirdBase),
                                        style: StrokeStyle(lineWidth: cStroke + size * (7 / 420), lineCap: .butt, lineJoin: .miter)
                                    )
                                    .blur(radius: size * (4 / 420))
                                path
                                    .stroke(
                                        lastThirdColor.opacity(lastThirdPeak),
                                        style: StrokeStyle(lineWidth: cStroke + size * (8 / 420), lineCap: .butt, lineJoin: .miter)
                                    )
                                    .blur(radius: size * (6 / 420))
                            }
                        } else {
                            path
                                .stroke(
                                    Color(red: 0.231, green: 0.51, blue: 0.965).opacity(0.35),
                                    style: StrokeStyle(lineWidth: cStroke + size * (6 / 420), lineCap: .butt, lineJoin: .miter)
                                )
                                .blur(radius: size * (4 / 420))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Current Marker Overlay (sun clipping + moon crescent without black)
private struct CurrentMarkerOverlay: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let currentPhase: IslamicPhaseId
    let progressAngle: Double
    let markerAngle: Double
    let sunMarkerState: SunMarkerStyle?
    let thicknessScale: CGFloat
    let size: CGFloat
    let renderVariant: RingRenderVariant
    let ringRadius: CGFloat

    private var isNight: Bool { MOON_ONLY_PHASES.contains(currentPhase) }
    private var markerR: CGFloat { size * 0.033 * thicknessScale }
    private var ccx: CGFloat { size / 2 }
    private var ccy: CGFloat { size / 2 }
    private var markerCenter: CGPoint {
        polarToXY(cx: Double(ccx), cy: Double(ccy), r: Double(ringRadius), angleDeg: markerAngle)
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
        polarToXY(cx: Double(ccx), cy: Double(ccy), r: Double(ringRadius), angleDeg: revealResult.boundaryAngle)
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
                dialCenter: CGPoint(x: ccx, y: ccy),
                renderVariant: renderVariant
            )
        }
    }

    @ViewBuilder
    private var moonView: some View {
        let moonPhase = getMoonPhaseByHijriDay(snapshot.hijriDate.day)
        let innerMoonR = markerR * MOON_INNER_R

        let moonColor = renderVariant == .phone
            ? Color(red: 0.89, green: 0.85, blue: 0.78)
            : MOON_LUNAR

        let moonContent = Circle()
            .fill(moonColor)
            .frame(width: innerMoonR * 2, height: innerMoonR * 2)
            .shadow(color: moonColor.opacity(renderVariant == .phone ? 0.65 : 0.25), radius: renderVariant == .phone ? innerMoonR * 0.45 : 0)

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

// MARK: - Sun outer halo (no TimelineView — avoids ~24Hz body refresh and memory pressure on device)
private struct SunAnimatedOuterLayers: View {
    let markerR: CGFloat
    let state: SunMarkerStyle

    @State private var pulse = false

    var body: some View {
        let s: CGFloat = state.strongGlow ? 1.0 : 0.72
        ZStack {
            Circle()
                .stroke(state.glowColor.opacity((pulse ? 0.30 : 0.14) * s), lineWidth: markerR * 2.5)
                .frame(width: markerR * (pulse ? 3.15 : 2.95), height: markerR * (pulse ? 3.15 : 2.95))
                .blur(radius: markerR * (pulse ? 1.02 : 0.88))
            Circle()
                .stroke(Color.white.opacity((pulse ? 0.22 : 0.10) * s), lineWidth: markerR * 1.08)
                .frame(width: markerR * (pulse ? 2.52 : 2.38), height: markerR * (pulse ? 2.52 : 2.38))
                .blur(radius: markerR * (pulse ? 0.58 : 0.48))
            Circle()
                .stroke(state.glowColor.opacity((pulse ? 0.98 : 0.78) * (state.strongGlow ? 1.0 : 0.55)), lineWidth: state.strongGlow ? markerR * 2.05 : markerR * 1.42)
                .frame(width: markerR * (pulse ? 2.06 : 2.0), height: markerR * (pulse ? 2.06 : 2.0))
                .blur(radius: state.strongGlow ? markerR * (pulse ? 0.78 : 0.68) : markerR * (pulse ? 0.52 : 0.44))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.85).repeatForever(autoreverses: true)) {
                pulse = true
            }
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
    let renderVariant: RingRenderVariant

    private let contentSize: CGFloat

    init(state: SunMarkerStyle, markerR: CGFloat, reveal: Double, boundaryAngle: Double, isRollIn: Bool, markerCenter: CGPoint, boundaryPoint: CGPoint?, dialCenter: CGPoint, renderVariant: RingRenderVariant) {
        self.state = state
        self.markerR = markerR
        self.reveal = reveal
        self.boundaryAngle = boundaryAngle
        self.isRollIn = isRollIn
        self.markerCenter = markerCenter
        self.boundaryPoint = boundaryPoint
        self.dialCenter = dialCenter
        self.renderVariant = renderVariant
        // Large enough to keep the original halo visible while still staying below the earlier 10r memory-heavy surface.
        self.contentSize = markerR * 8.2
    }

    /// ~6 Hz while sun is visible — full rotation in `spinPeriodSeconds` (lower rate saves memory vs 10+ Hz).
    private static let spinPeriodSeconds: Double = 10

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 6.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let p = Self.spinPeriodSeconds
            let angle = (t.truncatingRemainder(dividingBy: p) / p) * 360.0
            let content = rotatingSun(rotationAngle: angle)
                .frame(width: contentSize, height: contentSize)

            if renderVariant == .phone {
                content
            } else {
                content.modifier(
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
        }
    }

    private func rotatingSun(rotationAngle: Double) -> some View {
        ZStack {
            // Whole sun rotates underneath a dial-fixed clip.
            SunAnimatedOuterLayers(markerR: markerR, state: state)
            ZStack {
                Circle()
                    .stroke(glowStrokeGradient, lineWidth: state.strongGlow ? markerR * 1.55 : markerR * 1.08)
                    .frame(width: markerR * 2, height: markerR * 2)
                    .blur(radius: state.strongGlow ? markerR * 0.38 : markerR * 0.24)
                    .opacity(state.strongGlow ? 0.4 : 0.26)

                Circle()
                    .stroke(glowStrokeGradient, lineWidth: state.strongGlow ? markerR * 1.85 : markerR * 1.28)
                    .frame(width: markerR * 2, height: markerR * 2)
                    .blur(radius: state.strongGlow ? markerR * 0.55 : markerR * 0.32)
                    .opacity(state.strongGlow ? 0.75 : 0.36)

                Circle()
                    .fill(fillGradient)
                    .frame(width: markerR * 2, height: markerR * 2)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 0.5)
                    )
                    .shadow(
                        color: state.glowColor.opacity(state.strongGlow ? 0.52 : 0.22),
                        radius: state.strongGlow ? markerR * 2.05 : markerR * 1.05
                    )
                    .shadow(
                        color: Color.white.opacity(state.strongGlow ? 0.35 : 0.12),
                        radius: state.strongGlow ? markerR * 0.55 : markerR * 0.32
                    )
                    .shadow(
                        color: state.glowColor.opacity(state.strongGlow ? 0.32 : 0.14),
                        radius: state.strongGlow ? markerR * 0.95 : markerR * 0.5,
                        x: state.strongGlow ? markerR * 0.38 : 0,
                        y: state.strongGlow ? markerR * 0.38 : 0
                    )
            }
        }
        .rotationEffect(.degrees(rotationAngle))
        .frame(width: contentSize, height: contentSize)
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
                    .init(color: Color(red: 1.0, green: 0.998, blue: 0.96), location: 0.12),
                    .init(color: Color(red: 1.0, green: 0.96, blue: 0.62), location: 0.35),
                    .init(color: Color(red: 1.0, green: 0.87, blue: 0.2), location: 0.62),
                    .init(color: Color(red: 1.0, green: 0.72, blue: 0.08), location: 0.85),
                    .init(color: SUN_NORMAL, location: 1),
                ]),
                center: UnitPoint(x: 0.46, y: 0.42),
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
            content.mask(SunClipMaskView(
                reveal: reveal,
                boundaryAngle: boundaryAngle,
                isRollIn: isRollIn,
                r: r,
                markerCenter: markerCenter,
                boundaryPoint: boundaryPoint,
                dialCenter: dialCenter,
                contentSize: r * 8.2
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
        // Match web `CurrentMarker` mask: extent `k = 2r` in marker-local px, then map into this view's square.
        let lx1 = -tanX * k + dx
        let ly1 = -tanY * k + dy
        let lx2 = tanX * k + dx
        let ly2 = tanY * k + dy
        let startX = 0.5 + lx1 / cs
        let startY = 0.5 + ly1 / cs
        let endX = 0.5 + lx2 / cs
        let endY = 0.5 + ly2 / cs

        let stops: [Gradient.Stop] = isRollIn
            ? [.init(color: .white, location: 0), .init(color: .white, location: reveal), .init(color: .black, location: reveal), .init(color: .black, location: 1)]
            : [.init(color: .black, location: 0), .init(color: .black, location: 1 - reveal), .init(color: .white, location: 1 - reveal), .init(color: .white, location: 1)]

        Rectangle()
            .fill(LinearGradient(gradient: Gradient(stops: stops), startPoint: UnitPoint(x: startX, y: startY), endPoint: UnitPoint(x: endX, y: endY)))
            .frame(width: contentSize, height: contentSize)
    }
}
