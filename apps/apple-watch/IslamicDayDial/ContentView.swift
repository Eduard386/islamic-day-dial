import SwiftUI

private let DIAL_VERTICAL_GAP: CGFloat = 18
private let DIAL_SECTION_HEIGHT: CGFloat = 436
private let MS_PER_HOUR: Int64 = 3_600_000
private let MS_PER_DAY: Int64 = 24 * MS_PER_HOUR
private let INFO_EXPANSION_DURATION = 1.0
private let PHONE_DATE_INFO_SCALE: CGFloat = 1.25
private let PHONE_TEXT_GLOW_PULSE_DURATION = 3.0
let PHONE_READING_TINT = Color(red: 0.9, green: 0.88, blue: 0.8)
let PHONE_READING_GLOW = Color(red: 0.99, green: 0.88, blue: 0.38)
private let PHONE_INSIGHT_AYAH_AR = "إِنَّ عِدَّةَ الشُّهُورِ عِندَ اللَّهِ اثْنَا عَشَرَ شَهْرًا"
private let PHONE_INSIGHT_AYAH_EN = "\"Indeed, the number of months ordained by Allah is twelve\" [9:36]"
private let PHONE_HIJRI_MONTH_NAMES = [
    "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
    "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Shaban",
    "Ramadan", "Shawwal", "Dhul Qadah", "Dhul Hijjah"
]
private let PHONE_JIBRIL_GROUP_ONE: Set<String> = ["Dhuhr", "Asr", "Maghrib", "Isha", "Fajr"]
private let PHONE_JIBRIL_GROUP_TWO: Set<String> = ["Sunrise", "Duha", "Midday"]
private let PHONE_JIBRIL_HADITH_AR = "قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم ‏ \"‏ أَمَّنِي جِبْرِيلُ عَلَيْهِ السَّلاَمُ عِنْدَ الْبَيْتِ مَرَّتَيْنِ فَصَلَّى بِيَ الظُّهْرَ حِينَ زَالَتِ الشَّمْسُ وَكَانَتْ قَدْرَ الشِّرَاكِ وَصَلَّى بِيَ الْعَصْرَ حِينَ كَانَ ظِلُّهُ مِثْلَهُ وَصَلَّى بِيَ - يَعْنِي الْمَغْرِبَ - حِينَ أَفْطَرَ الصَّائِمُ وَصَلَّى بِيَ الْعِشَاءَ حِينَ غَابَ الشَّفَقُ وَصَلَّى بِيَ الْفَجْرَ حِينَ حَرُمَ الطَّعَامُ وَالشَّرَابُ عَلَى الصَّائِمِ فَلَمَّا كَانَ الْغَدُ صَلَّى بِيَ الظُّهْرَ حِينَ كَانَ ظِلُّهُ مِثْلَهُ وَصَلَّى بِيَ الْعَصْرَ حِينَ كَانَ ظِلُّهُ مِثْلَيْهِ وَصَلَّى بِيَ الْمَغْرِبَ حِينَ أَفْطَرَ الصَّائِمُ وَصَلَّى بِيَ الْعِشَاءَ إِلَى ثُلُثِ اللَّيْلِ وَصَلَّى بِيَ الْفَجْرَ فَأَسْفَرَ ثُمَّ الْتَفَتَ إِلَىَّ فَقَالَ يَا مُحَمَّدُ هَذَا وَقْتُ الأَنْبِيَاءِ مِنْ قَبْلِكَ وَالْوَقْتُ مَا بَيْنَ هَذَيْنِ الْوَقْتَيْنِ ‏\"‏ ‏."
private let PHONE_JIBRIL_HADITH_EN = """
The Messenger of Allah (ﷺ) said: Gabriel (ﷺ) led me in prayer at the House (i.e. the Ka'bah). He prayed the noon prayer with me when the sun had passed the meridian to the extent of the thong of a sandal; he prayed the afternoon prayer with me when the shadow of everything was as long as itself; he prayed the sunset prayer with me when one who is fasting breaks the fast; he prayed the night prayer with me when the twilight had ended; and he prayed the dawn prayer with me when food and drink become forbidden to one who is keeping the fast.

On the following day he prayed the noon prayer with me when his shadow was as long as himself; he prayed the afternoon prayer with me when his shadow was twice as long as himself; he prayed the sunset prayer at the time when one who is fasting breaks the fast; he prayed the night prayer with me when about the third of the night had passed; and he prayed the dawn prayer with me when there was a fair amount of light.

Then turning to me he said: Muhammad, this is the time observed by the prophets before you, and the time is anywhere between two times.
"""
private let PHONE_DUHA_HADITH_ONE_AR = "حَدَّثَنَا أَبُو جَعْفَرٍ السِّمْنَانِيُّ، حَدَّثَنَا أَبُو مُسْهِرٍ، حَدَّثَنَا إِسْمَاعِيلُ بْنُ عَيَّاشٍ، عَنْ بَحِيرِ بْنِ سَعْدٍ، عَنْ خَالِدِ بْنِ مَعْدَانَ، عَنْ جُبَيْرِ بْنِ نُفَيْرٍ، عَنْ أَبِي الدَّرْدَاءِ، وَأَبِي، ذَرٍّ عَنْ رَسُولِ اللَّهِ صلى الله عليه وسلم ‏ \"‏ عَنِ اللَّهِ، عَزَّ وَجَلَّ أَنَّهُ قَالَ ابْنَ آدَمَ ارْكَعْ لِي مِنْ أَوَّلِ النَّهَارِ أَرْبَعَ رَكَعَاتٍ أَكْفِكَ آخِرَهُ ‏\"‏."
private let PHONE_DUHA_HADITH_ONE_EN = "Allah's Messenger narrated that Allah, Blessed and Most High said: \"Son of Adam: Perform four Rak'ah for Me in the beginning of the day it will suffice you for the latter part of it\"."
private let PHONE_DUHA_HADITH_TWO_AR = "حَدَّثَنَا عَبْدُ اللَّهِ بْنُ مُحَمَّدِ بْنِ أَسْمَاءَ الضُّبَعِيُّ، حَدَّثَنَا مَهْدِيٌّ، - وَهُوَ ابْنُ مَيْمُونٍ - حَدَّثَنَا وَاصِلٌ، مَوْلَى أَبِي عُيَيْنَةَ عَنْ يَحْيَى بْنِ عُقَيْلٍ، عَنْ يَحْيَى بْنِ يَعْمَرَ، عَنْ أَبِي الأَسْوَدِ الدُّؤَلِيِّ، عَنْ أَبِي ذَرٍّ، عَنِ النَّبِيِّ صلى الله عليه وسلم أَنَّهُ قَالَ ‏ \"‏ يُصْبِحُ عَلَى كُلِّ سُلاَمَى مِنْ أَحَدِكُمْ صَدَقَةٌ فَكُلُّ تَسْبِيحَةٍ صَدَقَةٌ وَكُلُّ تَحْمِيدَةٍ صَدَقَةٌ وَكُلُّ تَهْلِيلَةٍ صَدَقَةٌ وَكُلُّ تَكْبِيرَةٍ صَدَقَةٌ وَأَمْرٌ بِالْمَعْرُوفِ صَدَقَةٌ وَنَهْىٌ عَنِ الْمُنْكَرِ صَدَقَةٌ وَيُجْزِئُ مِنْ ذَلِكَ رَكْعَتَانِ يَرْكَعُهُمَا مِنَ الضُّحَى‏\"."
private let PHONE_DUHA_HADITH_TWO_EN = "Abu Dharr reported Allah's Apostle (ﷺ) as saying: \"In the morning charity is due from every bone in the body of every one of you. Every utterance of Allah's glorification is an act of charity. Every utterance of praise of Him is an act of charity, every utterance of profession of His Oneness is an act of charity, every utterance of profession of His Greatness is an act of charity, enjoining good is an act of charity, forbidding what is distreputable is an act of charity, and two rak'ahs which one prays in the forenoon will suffice\"."
private let PHONE_DUHA_HADITH_THREE_AR = "قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم ‏\"‏صَلِّ صَلاَةَ الصُّبْحِ ثُمَّ أَقْصِرْ عَنِ الصَّلاَةِ حَتَّى تَطْلُعَ الشَّمْسُ حَتَّى تَرْتَفِعَ فَإِنَّهَا تَطْلُعُ حِينَ تَطْلُعُ بَيْنَ قَرْنَىْ شَيْطَانٍ وَحِينَئِذٍ يَسْجُدُ لَهَا الْكُفَّارُ ثُمَّ صَلِّ فَإِنَّ الصَّلاَةَ مَشْهُودَةٌ مَحْضُورَةٌ حَتَّى يَسْتَقِلَّ الظِّلُّ بِالرُّمْحِ ثُمَّ أَقْصِرْ عَنِ الصَّلاَةِ فَإِنَّ حِينَئِذٍ تُسْجَرُ جَهَنَّمُ”"
private let PHONE_DUHA_HADITH_THREE_EN = "Messenger of Allah (ﷺ) said: “Observe the dawn prayer, then stop praying when the sun is rising till it is fully up, for when it rises it comes up between the horns of Satan, and the unbelievers prostrate themselves to it at that time. Then pray, for the prayer is witnessed and attended (by angels) till the shadow becomes about the length of a lance; then cease prayer, for at that time Hell is heated up.”"
private let PHONE_LAST_THIRD_HADITH_AR = "أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم قَالَ ‏ \"يَنْزِلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الآخِرُ فَيَقُولُ مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ وَمَنْ يَسْأَلُنِي فَأُعْطِيَهُ وَمَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ ‏\"‏.‏"
private let PHONE_LAST_THIRD_HADITH_EN = "Allah's Messenger (ﷺ) said, \"Our Lord, the Blessed and the Exalted, descends every night to the lowest heaven when one-third of the latter part of the night is left, and says: Who supplicates Me so that I may answer him? Who asks Me so that I may give to him? Who asks Me forgiveness so that I may forgive him?\""

private func phoneGlowPulsePhase(_ date: Date) -> (base: Double, phase: Double) {
    let seconds = date.timeIntervalSince1970.truncatingRemainder(dividingBy: PHONE_TEXT_GLOW_PULSE_DURATION)
    let normalized = seconds / PHONE_TEXT_GLOW_PULSE_DURATION
    let phase = (sin(normalized * 2 * .pi) + 1) / 2
    let base = 0.35 * (1 - phase)
    return (base, phase)
}

private func phoneSentenceCaseMonth(_ value: String) -> String {
    let lower = value.lowercased()
    guard let first = lower.first else { return value }
    return String(first).uppercased() + String(lower.dropFirst())
}

private enum PhoneSectorSpotlightSource {
    case main
    case separated
    case months
}

private func normalizedDialAngle(_ angle: Double) -> Double {
    let remainder = angle.truncatingRemainder(dividingBy: 360)
    return remainder >= 0 ? remainder : remainder + 360
}

private func phoneAngleContains(_ angle: Double, start: Double, end: Double) -> Bool {
    let normalizedAngle = normalizedDialAngle(angle)
    let normalizedStart = normalizedDialAngle(start)
    let normalizedEnd = normalizedDialAngle(end)

    if normalizedStart <= normalizedEnd {
        return normalizedAngle >= normalizedStart && normalizedAngle <= normalizedEnd
    }

    return normalizedAngle >= normalizedStart || normalizedAngle <= normalizedEnd
}

private func phoneAngle(for point: CGPoint, size: CGFloat) -> Double {
    let dx = point.x - size / 2
    let dy = point.y - size / 2
    let angle = atan2(dy, dx) * 180 / .pi + 90
    return normalizedDialAngle(angle)
}

private func adjustedTimelineAngle(
    timestamp: Date,
    snapshot: ComputedIslamicDay,
    phoneArcSpecs: [PhoneRingArcSpec]
) -> Double {
    let originalAngle = timestampToAngle(
        timestamp: timestamp,
        lastMaghrib: snapshot.timeline.lastMaghrib,
        nextMaghrib: snapshot.timeline.nextMaghrib
    )
    return adjustedPhoneMarkerAngle(phoneArcSpecs: phoneArcSpecs, originalAngle: originalAngle)
}

private func separatedSectorTitle(
    angle: Double,
    snapshot: ComputedIslamicDay,
    phoneArcSpecs: [PhoneRingArcSpec]
) -> String? {
    let specByKind = Dictionary(uniqueKeysWithValues: phoneArcSpecs.map { ($0.kind, $0) })

    if let maghrib = specByKind[.maghribToIsha],
       phoneAngleContains(angle, start: maghrib.startAngleDeg, end: maghrib.endAngleDeg) {
        return "Maghrib"
    }

    if let ishaGroup = specByKind[.ishaGroup] {
        let lastThirdStartAngle = adjustedTimelineAngle(
            timestamp: snapshot.timeline.lastThirdStart,
            snapshot: snapshot,
            phoneArcSpecs: phoneArcSpecs
        )
        if phoneAngleContains(angle, start: ishaGroup.startAngleDeg, end: lastThirdStartAngle) {
            return "Isha"
        }
        if phoneAngleContains(angle, start: lastThirdStartAngle, end: ishaGroup.endAngleDeg) {
            return "Last 3rd"
        }
    }

    if let fajr = specByKind[.fajrToSunrise],
       phoneAngleContains(angle, start: fajr.startAngleDeg, end: fajr.endAngleDeg) {
        return "Fajr"
    }

    if let sunrise = specByKind[.sunrise],
       phoneAngleContains(angle, start: sunrise.startAngleDeg, end: sunrise.endAngleDeg) {
        return "Sunrise"
    }

    if let duha = specByKind[.duha],
       phoneAngleContains(angle, start: duha.startAngleDeg, end: duha.endAngleDeg) {
        return "Duha"
    }

    if let midday = specByKind[.midday],
       phoneAngleContains(angle, start: midday.startAngleDeg, end: midday.endAngleDeg) {
        return "Midday"
    }

    if let dhuhr = specByKind[.dhuhrToAsr],
       phoneAngleContains(angle, start: dhuhr.startAngleDeg, end: dhuhr.endAngleDeg) {
        return "Dhuhr"
    }

    if let asr = specByKind[.asrToMaghrib],
       phoneAngleContains(angle, start: asr.startAngleDeg, end: asr.endAngleDeg) {
        return "Asr"
    }

    return nil
}

private func isPhoneMainRingTap(location: CGPoint, containerSize: CGSize) -> Bool {
    let dialFrameWidth = max(0, containerSize.width - 40)
    let dialFrameHeight = DIAL_SECTION_HEIGHT
    let dialSize = min(dialFrameWidth, dialFrameHeight) * 1.28
    let ringStroke = dialSize * 0.081
    let ringInnerRadius = dialSize * 0.25125
    let ringOuterRadius = ringInnerRadius + ringStroke
    let center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2 - DIAL_VERTICAL_GAP / 2)
    let dx = location.x - center.x
    let dy = location.y - center.y
    let distance = sqrt(dx * dx + dy * dy)
    return distance >= ringInnerRadius && distance <= ringOuterRadius
}

private func isPhoneCurrentSectorTitleTap(location: CGPoint, containerSize: CGSize) -> Bool {
    let dialFrameWidth = max(0, containerSize.width - 40)
    let dialFrameHeight = DIAL_SECTION_HEIGHT
    let dialSize = min(dialFrameWidth, dialFrameHeight) * 1.28
    let holeTop = dialSize * (0.5 - 0.25125)
    let holeHeight = dialSize * 0.5025
    let sectorTop = holeTop + 55 * (holeHeight / 212)
    let centerOffsetY = dialSize * (-10 / 420)
    let center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2 - DIAL_VERTICAL_GAP / 2)
    let titleWidth = min(dialSize * 0.54, 220)
    let titleRect = CGRect(
        x: center.x - titleWidth / 2,
        y: center.y - dialSize / 2 + centerOffsetY + sectorTop - 4,
        width: titleWidth,
        height: 48
    )
    return titleRect.contains(location)
}

private func isPhoneHijriDateTap(location: CGPoint, containerSize: CGSize) -> Bool {
    let dialFrameWidth = max(0, containerSize.width - 40)
    let dialFrameHeight = DIAL_SECTION_HEIGHT
    let dialSize = min(dialFrameWidth, dialFrameHeight) * 1.28
    let holeTop = dialSize * (0.5 - 0.25125)
    let holeHeight = dialSize * 0.5025
    let dateTop = holeTop + 100 * (holeHeight / 212)
    let centerOffsetY = dialSize * (-10 / 420)
    let center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2 - DIAL_VERTICAL_GAP / 2)
    let dateWidth = min(dialSize * 0.58, 240)
    let dateRect = CGRect(
        x: center.x - dateWidth / 2,
        y: center.y - dialSize / 2 + centerOffsetY + dateTop - 6,
        width: dateWidth,
        height: 64
    )
    return dateRect.contains(location)
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var automaticLocation: Location = .mecca
    @State private var snapshot: ComputedIslamicDay?
    @State private var now = Date()
    
    // Debug Time Travel (shake to reveal)
    @State private var showTimeTravel = false
    @State private var monthOffset = 0
    @State private var dayOffset = 0
    @State private var hourOffset: Double = 0
    @State private var timeOffsetMs: Int64 = 0
    @State private var showFootnotes = false
    @State private var infoPresentationProgress = 0.0
    @State private var footnoteOpacity = 0.0
    @State private var baseScreenOpacity = 1.0
    @State private var insightOpacity = 0.0
    @State private var sectorSpotlightTitle = ""
    @State private var sectorSpotlightOpacity = 0.0
    @State private var sectorSpotlightSource: PhoneSectorSpotlightSource = .main
    @State private var isInteractionLocked = false
    @State private var interactionLockTask: Task<Void, Never>?

    private var effectiveNow: Date {
        if timeOffsetMs == 0 { return now }
        return now.addingTimeInterval(Double(timeOffsetMs) / 1000)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    dialSection
                    Spacer(minLength: 0)
                }
                .opacity(baseScreenOpacity)
                .allowsHitTesting(
                    !isInteractionLocked &&
                    insightOpacity < 0.001 &&
                    sectorSpotlightOpacity < 0.001
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .background(Color.black.ignoresSafeArea())
                .overlay {
                    ShakeDetectorView { showTimeTravel = true }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }
                .overlay {
                    if let snapshot {
                        PhoneDialInsightView(
                            snapshot: snapshot,
                            containerSize: geo.size
                        )
                        .opacity(insightOpacity)
                        .allowsHitTesting(false)
                    }
                }
                .overlay {
                    Color.clear
                        .contentShape(Rectangle())
                        .allowsHitTesting(
                            !isInteractionLocked &&
                            (insightOpacity > 0.001 || sectorSpotlightOpacity > 0.001)
                        )
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    if sectorSpotlightOpacity > 0.001 {
                                        dismissSectorSpotlight()
                                    } else if insightOpacity > 0.001 {
                                        if let snapshot,
                                           isPhoneCurrentSectorTitleTap(location: value.location, containerSize: geo.size) {
                                            beginSectorSpotlight(
                                                title: getSectorDisplayName(
                                                    now: effectiveNow,
                                                    currentPhase: getCurrentPhase(now: effectiveNow, timeline: snapshot.timeline),
                                                    timeline: (duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr)
                                                ),
                                                source: .months
                                            )
                                        } else if isPhoneHijriDateTap(location: value.location, containerSize: geo.size) {
                                            dismissInsightPresentation()
                                        } else if isPhoneMainRingTap(location: value.location, containerSize: geo.size) {
                                            beginInfoModeFromInsight()
                                        } else {
                                            dismissInsightPresentation()
                                        }
                                    }
                                }
                        )
                }
                .overlay {
                    if !sectorSpotlightTitle.isEmpty {
                        PhoneSectorTitleSpotlightView(
                            title: sectorSpotlightTitle,
                            source: sectorSpotlightSource,
                            containerSize: geo.size,
                            onTap: dismissSectorSpotlight
                        )
                        .opacity(sectorSpotlightOpacity)
                        .allowsHitTesting(true)
                    }
                }
            }
        }
        .task {
            await refreshSnapshot(forceResolveLocation: true)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = Date()
            }
        }
        .task {
            while !Task.isCancelled {
                await refreshSnapshot(forceResolveLocation: false)
                let currentSnapshot = snapshot
                let currentNow = effectiveNow
                try? await Task.sleep(for: .seconds(secondsUntilNextRefresh(from: currentNow, snapshot: currentSnapshot)))
            }
        }
        .onChange(of: timeOffsetMs) { _, _ in recalcSnapshot() }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .background && newPhase == .active {
                Task { await refreshSnapshot(forceResolveLocation: true) }
            }
        }
        .sheet(isPresented: $showTimeTravel) {
            TimeTravelSheet(
                monthOffset: $monthOffset,
                dayOffset: $dayOffset,
                hourOffset: $hourOffset,
                timeOffsetMs: $timeOffsetMs,
                currentHijriDay: snapshot?.hijriDate.day ?? 1
            )
        }
        .onDisappear {
            interactionLockTask?.cancel()
        }
    }
    
    private func recalcSnapshot() {
        snapshot = computeIslamicDaySnapshot(now: effectiveNow, location: automaticLocation)
    }

    private func secondsUntilNextRefresh(from date: Date, snapshot: ComputedIslamicDay?) -> Double {
        let calendar = Calendar.current
        let nextMinute = calendar.nextDate(
            after: date,
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(60)
        let nextTransition = snapshot.map { getNextTransition(now: date, timeline: $0.timeline).at } ?? nextMinute
        let refreshAt = min(nextMinute, nextTransition)
        return max(1, refreshAt.timeIntervalSince(date) + 0.25)
    }
    
    private var dialSection: some View {
        Group {
            if let snapshot {
                PhoneDialView(
                    snapshot: snapshot,
                    now: effectiveNow,
                    infoProgress: infoPresentationProgress,
                    footnoteOpacity: footnoteOpacity,
                    showsInsightOverlay: insightOpacity > 0.001,
                    interactionsEnabled: !isInteractionLocked,
                    onDateTap: beginInsightPresentation,
                    onSectorTap: openInfoMode,
                    onSeparatedSectorTap: { _ in closeInfoMode() },
                    onCurrentSectorTap: { title, source in beginSectorSpotlight(title: title, source: source) },
                    onFootnoteTap: { title in beginSectorSpotlight(title: title, source: .separated) },
                    onBackgroundTap: closeInfoMode
                )
                    .frame(height: DIAL_SECTION_HEIGHT)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 320)
            }
        }
        .padding(.bottom, DIAL_VERTICAL_GAP)
    }

    private func openInfoMode() {
        lockInteractions()
        showFootnotes = true
        insightOpacity = 0
        baseScreenOpacity = 1
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            infoPresentationProgress = 1
            footnoteOpacity = 1
        }
    }

    private func closeInfoMode() {
        lockInteractions()
        showFootnotes = false
        baseScreenOpacity = 1
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            insightOpacity = 0
            infoPresentationProgress = 0
            footnoteOpacity = 0
        }
    }

    private func beginInsightPresentation() {
        guard
            !isInteractionLocked,
            insightOpacity < 0.001,
            sectorSpotlightOpacity < 0.001
        else { return }
        lockInteractions()
        if showFootnotes {
            showFootnotes = false
            withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
                infoPresentationProgress = 0
                footnoteOpacity = 0
                insightOpacity = 1
            }
        } else {
            withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
                insightOpacity = 1
            }
        }
    }

    private func beginInfoModeFromInsight() {
        guard
            !isInteractionLocked,
            insightOpacity > 0.001,
            sectorSpotlightOpacity < 0.001
        else { return }
        lockInteractions()
        showFootnotes = true
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            insightOpacity = 0
            infoPresentationProgress = 1
            footnoteOpacity = 1
        }
    }

    private func dismissInsightPresentation() {
        guard insightOpacity > 0.001 else { return }
        lockInteractions()
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            insightOpacity = 0
        }
    }

    private func beginSectorSpotlight(title: String, source: PhoneSectorSpotlightSource) {
        guard
            !isInteractionLocked,
            sectorSpotlightOpacity < 0.001,
            (insightOpacity < 0.001 || source == .months)
        else { return }
        lockInteractions()
        sectorSpotlightTitle = title
        sectorSpotlightSource = source
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            baseScreenOpacity = 0
            if source == .months {
                insightOpacity = 0
            }
            sectorSpotlightOpacity = 1
        }
    }

    private func dismissSectorSpotlight() {
        guard sectorSpotlightOpacity > 0.001 else { return }
        lockInteractions()
        withAnimation(.easeInOut(duration: INFO_EXPANSION_DURATION)) {
            baseScreenOpacity = 1
            insightOpacity = sectorSpotlightSource == .months ? 1 : 0
            sectorSpotlightOpacity = 0
        }
    }

    private func lockInteractions() {
        interactionLockTask?.cancel()
        isInteractionLocked = true
        interactionLockTask = Task {
            try? await Task.sleep(for: .seconds(INFO_EXPANSION_DURATION))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isInteractionLocked = false
                if sectorSpotlightOpacity < 0.001 {
                    sectorSpotlightTitle = ""
                }
            }
        }
    }
    
    private func refreshSnapshot(forceResolveLocation: Bool) async {
        if forceResolveLocation || snapshot == nil {
            let result = await resolveGeoResult()
            automaticLocation = result.location
            if forceResolveLocation {
                await trackVisit(geo: result)
                await PrayerNotificationScheduler.requestAndSchedule(location: automaticLocation)
            }
        }
        
        let currentNow = Date()
        now = currentNow
        let displayNow = currentNow.addingTimeInterval(Double(timeOffsetMs) / 1000)
        snapshot = computeIslamicDaySnapshot(now: displayNow, location: automaticLocation)
    }
}

private struct PhoneDialView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let infoProgress: Double
    let footnoteOpacity: Double
    let showsInsightOverlay: Bool
    let interactionsEnabled: Bool
    let onDateTap: () -> Void
    let onSectorTap: () -> Void
    let onSeparatedSectorTap: (String) -> Void
    let onCurrentSectorTap: (String, PhoneSectorSpotlightSource) -> Void
    let onFootnoteTap: (String) -> Void
    let onBackgroundTap: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let dialSize = min(w, h) * 1.28
            let dialCenter = CGPoint(x: w / 2, y: h / 2)
            let holeTop = dialSize * (0.5 - 0.25125)
            let holeHeight = dialSize * 0.5025
            let sectorTop = holeTop + 55 * (holeHeight / 212)
            let dateTop = holeTop + 100 * (holeHeight / 212)
            let centerOffsetY = dialSize * (-10 / 420)
            let currentSectorTitle = periodLabel(snapshot: snapshot, now: now)
            let canEnterInsight = interactionsEnabled
                && !showsInsightOverlay
                && (infoProgress < 0.01 || (infoProgress > 0.99 && footnoteOpacity > 0.99))
            let canTapSectors = interactionsEnabled && infoProgress < 0.01 && !showsInsightOverlay
            let canTapCurrentSector = interactionsEnabled
                && !showsInsightOverlay
                && (infoProgress < 0.01 || (infoProgress > 0.99 && footnoteOpacity > 0.99))
            let canTapFootnotes = interactionsEnabled && infoProgress > 0.99 && footnoteOpacity > 0.99 && !showsInsightOverlay
            let canTapSeparatedBackground = interactionsEnabled && infoProgress > 0.99 && footnoteOpacity > 0.99 && !showsInsightOverlay
            let ringStroke = dialSize * 0.081
            let baseRingInnerRadius = dialSize * 0.25125
            let baseRingRadius = baseRingInnerRadius + ringStroke / 2
            let expandedRingRadius = expandedPhoneRingRadius(baseRadius: baseRingRadius, size: dialSize, infoProgress: infoProgress)
            let ringOuterRadius = baseRingInnerRadius + ringStroke
            let ringInnerRadius = baseRingInnerRadius
            let separatedRingInnerRadius = max(0, expandedRingRadius - ringStroke / 2)
            let separatedRingOuterRadius = expandedRingRadius + ringStroke / 2
            let phoneArcSpecs = buildPhoneRingArcSpecs(
                snapshot: snapshot,
                baseRadius: baseRingRadius,
                ringRadius: expandedRingRadius
            )
            let canTapSeparatedSectors = canTapSeparatedBackground && !phoneArcSpecs.isEmpty

            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(canTapSeparatedBackground)
                    .onTapGesture {
                        onBackgroundTap()
                    }

                PhoneDialFootnotesView(
                    snapshot: snapshot,
                    dialSize: dialSize,
                    dialCenter: dialCenter,
                    bounds: geo.size,
                    isInteractive: canTapFootnotes,
                    onLabelTap: onFootnoteTap
                )
                .opacity(footnoteOpacity)
                .zIndex(3)
                ZStack {
                    PhoneRingView(snapshot: snapshot, now: now, phoneInfoProgress: infoProgress)
                        .frame(width: dialSize, height: dialSize)
                    Color.clear
                        .frame(width: dialSize, height: dialSize)
                        .contentShape(
                            PhoneRingTapShape(
                                innerRadius: separatedRingInnerRadius,
                                outerRadius: separatedRingOuterRadius
                            ),
                            eoFill: true
                        )
                        .allowsHitTesting(canTapSeparatedSectors)
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    guard canTapSeparatedSectors else { return }
                                    let title = separatedSectorTitle(
                                        angle: phoneAngle(for: value.location, size: dialSize),
                                        snapshot: snapshot,
                                        phoneArcSpecs: phoneArcSpecs
                                    )
                                    guard let title else { return }
                                    onSeparatedSectorTap(title)
                                }
                        )
                    Color.clear
                        .frame(width: dialSize, height: dialSize)
                        .contentShape(Rectangle())
                        .allowsHitTesting(canTapSectors)
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    guard canTapSectors else { return }
                                    let dx = value.location.x - dialSize / 2
                                    let dy = value.location.y - dialSize / 2
                                    let distance = sqrt(dx * dx + dy * dy)
                                    guard distance >= ringInnerRadius && distance <= ringOuterRadius else { return }
                                    onSectorTap()
                                }
                        )
                    ZStack(alignment: .top) {
                        Color.clear
                        Button {
                            onCurrentSectorTap(
                                currentSectorTitle,
                                infoProgress > 0.99 && footnoteOpacity > 0.99 ? .separated : .main
                            )
                        } label: {
                            currentPeriodView(snapshot: snapshot, now: now)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                        .offset(y: sectorTop)
                        .allowsHitTesting(canTapCurrentSector)
                        .zIndex(2)
                        HijriDateLabels(
                            hijriDate: snapshot.hijriDate,
                            infoProgress: 0,
                            isInteractive: canEnterInsight,
                            onTap: onDateTap
                        )
                            .frame(maxWidth: .infinity)
                            .offset(y: dateTop)
                    }
                    .frame(width: dialSize, height: dialSize)
                    .offset(y: centerOffsetY)
                }
                .frame(width: dialSize, height: dialSize)
                .position(dialCenter)
                .zIndex(1)
            }
            .frame(width: w, height: h)
        }
    }
    
    @ViewBuilder
    private func currentPeriodView(snapshot snap: ComputedIslamicDay, now: Date) -> some View {
        let phase = currentPhase(snapshot: snap, now: now)
        Text(periodLabel(snapshot: snap, now: now).uppercased())
            .font(.system(size: 20, weight: .light))
            .foregroundColor(periodColor(snapshot: snap, now: now))
            .modifier(IshaShadowModifier(phase: phase))
    }
    
    private func periodLabel(snapshot snap: ComputedIslamicDay, now: Date) -> String {
        getSectorDisplayName(
            now: now,
            currentPhase: currentPhase(snapshot: snap, now: now),
            timeline: (duhaStart: snap.timeline.duhaStart, dhuhr: snap.timeline.dhuhr)
        )
    }
    
    private func periodColor(snapshot snap: ComputedIslamicDay, now: Date) -> Color {
        periodLabel(snapshot: snap, now: now) == "Jumu'ah"
            ? Color(red: 0.06, green: 0.73, blue: 0.51)
            : Colors.coolLabel
    }

    private func currentPhase(snapshot snap: ComputedIslamicDay, now: Date) -> IslamicPhaseId {
        getCurrentPhase(now: now, timeline: snap.timeline)
    }
}

/// App-only entry point for the dial renderer.
/// Keep phone-specific visual changes here so watch rendering stays untouched.
private struct PhoneRingView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    var thicknessScale: CGFloat = 1
    var phoneInfoProgress: Double = 0

    var body: some View {
        RingView(
            snapshot: snapshot,
            now: now,
            thicknessScale: thicknessScale,
            renderVariant: .phone,
            phoneInfoProgress: phoneInfoProgress
        )
    }
}

private struct IshaShadowModifier: ViewModifier {
    let phase: IslamicPhaseId
    
    func body(content: Content) -> some View {
        content
    }
}

private let COMPACT_MONTH_NAMES: Set<String> = [
    "rabi al-awwal", "rabi al-thani", "jumada al-ula", "jumada al-thani"
]

private struct HijriEngravedLabelsModifier: ViewModifier {
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

private struct HijriDateLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)
    private let useCompactDayMonth: Bool
    private let infoProgress: Double
    private let isInteractive: Bool
    private let onTap: (() -> Void)?

    init(hijriDate: HijriDate, infoProgress: Double = 0, isInteractive: Bool = false, onTap: (() -> Void)? = nil) {
        self.parts = formatHijriDateParts(hijriDate)
        self.useCompactDayMonth = COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
        self.infoProgress = max(0, min(1, infoProgress))
        self.isInteractive = isInteractive
        self.onTap = onTap
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = 0.25 + phoneGlowPulsePhase(timeline.date).phase * 0.75
            let glowStrength = CGFloat(infoProgress)
            let phaseValue = CGFloat(phase)
            let scale = 1 + glowStrength * (PHONE_DATE_INFO_SCALE - 1)
            let goldOpacity = (0.14 + phase * 0.32) * Double(glowStrength)
            let whiteOpacity = (0.05 + phase * 0.14) * Double(glowStrength)
            let goldRadius = CGFloat(7) + glowStrength * CGFloat(4) + phaseValue * CGFloat(10)
            let whiteRadius = CGFloat(3) + glowStrength * CGFloat(2) + phaseValue * CGFloat(6)

            VStack(spacing: 2) {
                Text(parts.dayMonth.uppercased())
                    .font(.system(size: useCompactDayMonth ? 15 : 18, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.primaryGold)
                    .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
                Text(parts.year)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : Colors.secondaryGold)
                    .modifier(HijriEngravedLabelsModifier(isEid: parts.isEid))
            }
            .scaleEffect(scale)
            .brightness(-0.01 + phase * 0.04)
            .shadow(color: Colors.primaryGold.opacity(goldOpacity), radius: goldRadius)
            .shadow(color: Colors.secondaryGold.opacity(goldOpacity * 0.82), radius: goldRadius + CGFloat(5))
            .shadow(color: Color.white.opacity(whiteOpacity), radius: whiteRadius)
        }
        .contentShape(Rectangle())
        .allowsHitTesting(isInteractive)
        .onTapGesture {
            onTap?()
        }
    }
}

private struct PhoneDialInsightView: View {
    let snapshot: ComputedIslamicDay
    let containerSize: CGSize

    private var translationFontSize: CGFloat {
        min(containerSize.width * 0.04, 17)
    }

    private var translationFont: Font {
        .system(size: translationFontSize, weight: .regular, design: .serif)
    }

    private var dialSize: CGFloat {
        min(max(0, containerSize.width - 40), DIAL_SECTION_HEIGHT) * 1.28
    }

    private var ringTop: CGFloat { containerSize.height / 2 - dialSize / 2 }
    private var ringBottom: CGFloat { containerSize.height / 2 + dialSize / 2 }
    private var ayahTop: CGFloat { containerSize.height * 0.05 }
    private var monthsTop: CGFloat { ringBottom - containerSize.height * 0.07 }
    private var columnWidth: CGFloat { min((containerSize.width - 44) / 2, 170) }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: containerSize.height * 0.012) {
                Text(PHONE_INSIGHT_AYAH_AR)
                    .font(.system(size: min(containerSize.width * 0.052, 22), weight: .medium, design: .serif))
                    .foregroundColor(PHONE_READING_TINT)
                    .multilineTextAlignment(.center)
                    .lineSpacing(containerSize.height * 0.006)
                    .frame(maxWidth: min(containerSize.width - 36, 420))

                Text(PHONE_INSIGHT_AYAH_EN)
                    .font(translationFont)
                    .foregroundColor(PHONE_READING_TINT)
                    .multilineTextAlignment(.center)
                    .lineSpacing(containerSize.height * 0.003)
                    .frame(maxWidth: min(containerSize.width - 56, 360))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, ayahTop)
            .padding(.horizontal, 18)

            HStack(alignment: .top, spacing: 12) {
                monthColumn(indices: 0..<6)
                monthColumn(indices: 6..<12)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, monthsTop)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func monthColumn(indices: Range<Int>) -> some View {
        VStack(alignment: .leading, spacing: containerSize.height * 0.005) {
            ForEach(indices, id: \.self) { index in
                let monthName = PHONE_HIJRI_MONTH_NAMES[index]
                let isCurrentMonth = snapshot.hijriDate.monthNumber == index + 1

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1).")
                        .font(translationFont)
                        .lineLimit(1)
                        .frame(width: 34, alignment: .trailing)
                    Text(phoneSentenceCaseMonth(monthName))
                        .font(translationFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(isCurrentMonth ? Colors.primaryGold : PHONE_READING_TINT)
                .modifier(HijriEngravedLabelsModifier(isEid: false))
            }
        }
        .frame(width: columnWidth, alignment: .leading)
    }
}

private struct PhoneSectorTitleSpotlightView: View {
    let title: String
    let source: PhoneSectorSpotlightSource
    let containerSize: CGSize
    let onTap: () -> Void

    private var isPrayerTimingGroup: Bool {
        PHONE_JIBRIL_GROUP_ONE.contains(title)
    }

    private var isSunDayGroup: Bool {
        PHONE_JIBRIL_GROUP_TWO.contains(title)
    }

    private var isLastThird: Bool {
        title == "Last 3rd"
    }

    private var sectorCollectionTitle: String {
        if isPrayerTimingGroup {
            return "Dhuhr, Asr, Maghrib, Isha, Fajr"
        }
        if isSunDayGroup {
            return "Sunrise, Duha, Midday"
        }
        return title.uppercased()
    }

    private func calculationHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .serif))
            .foregroundColor(PHONE_READING_TINT)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func calculationLine(label: String, detail: String) -> some View {
        (
            Text("\(label): ")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(PHONE_READING_TINT)
            +
            Text(detail)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(PHONE_READING_TINT.opacity(0.85))
        )
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hadithArabic(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .regular, design: .serif))
            .foregroundColor(PHONE_READING_TINT)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func hadithEnglish(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .serif))
            .foregroundColor(PHONE_READING_TINT)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hadithSource(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .italic()
            .foregroundColor(PHONE_READING_TINT.opacity(0.85))
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                Text(sectorCollectionTitle)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(PHONE_READING_TINT)
                    .tracking(1.0)
                    .shadow(color: PHONE_READING_GLOW.opacity(0.42), radius: 6)
                    .shadow(color: PHONE_READING_GLOW.opacity(0.24), radius: 12)
                Text("")
                if isPrayerTimingGroup {
                    VStack(spacing: 4) {
                        hadithArabic(PHONE_JIBRIL_HADITH_AR)
                        Text("")
                        hadithEnglish(PHONE_JIBRIL_HADITH_EN)
                        hadithSource("Sunan Abi Dawud, Hadith 393")
                        Text("")
                        calculationHeading("Dhuhr calculation")
                        calculationLine(
                            label: "Start",
                            detail: "calculated according to Umm al-Qura, 18.5° (at the user’s coordinates)."
                        )
                        calculationLine(label: "End", detail: "at the start of Asr.")
                        Text("")
                        calculationHeading("Asr calculation")
                        calculationLine(
                            label: "Start",
                            detail: "when shadow length = object height + noon shadow (at the user’s coordinates)."
                        )
                        calculationLine(label: "End", detail: "at the start of Maghrib.")
                        Text("")
                        calculationHeading("Maghrib calculation")
                        calculationLine(
                            label: "Start",
                            detail: "at sunset, when the sun disappears below the horizon (at the user’s coordinates)."
                        )
                        calculationLine(label: "End", detail: "at the start of Isha.")
                        Text("")
                        calculationHeading("Isha calculation")
                        calculationLine(
                            label: "Start",
                            detail: "when the evening twilight disappears, using the Adhan model with Shafaq Ahmer and a 15° sun angle (at the user’s coordinates)."
                        )
                        calculationLine(label: "End", detail: "at the start of Fajr.")
                        Text("")
                        calculationHeading("Fajr calculation")
                        calculationLine(
                            label: "Start",
                            detail: "calculated according to Umm al-Qura, 18.5° (at the user’s coordinates)."
                        )
                        calculationLine(label: "End", detail: "at the start of Sunrise.")
                    }
                    .frame(maxWidth: min(containerSize.width - 36, 420))
                } else if isSunDayGroup {
                    VStack(spacing: 4) {
                        hadithArabic(PHONE_DUHA_HADITH_ONE_AR)
                        Text("")
                        hadithEnglish(PHONE_DUHA_HADITH_ONE_EN)
                        hadithSource("Jami` at-Tirmidhi, Hadith 475")
                        Text("")
                        hadithArabic(PHONE_DUHA_HADITH_TWO_AR)
                        Text("")
                        hadithEnglish(PHONE_DUHA_HADITH_TWO_EN)
                        hadithSource("Sahih Muslim, Hadith 720")
                        Text("")
                        hadithArabic(PHONE_DUHA_HADITH_THREE_AR)
                        Text("")
                        hadithEnglish(PHONE_DUHA_HADITH_THREE_EN)
                        hadithSource("Sahih Muslim, Hadith 832")
                        Text("")
                        calculationHeading("Sunrise calculation")
                        calculationLine(
                            label: "Start",
                            detail: "calculated with the Adhan library (at the user’s coordinates), using the standard apparent solar altitude of −50 arcminutes (≈ −0.83°)."
                        )
                        calculationLine(label: "End", detail: "at the start of Duha.")
                        Text("")
                        calculationHeading("Duha calculation")
                        calculationLine(
                            label: "Start",
                            detail: "when the sun reaches 4° altitude above the horizon (at the user’s coordinates); if needed, fallback = 20 minutes after Sunrise."
                        )
                        calculationLine(label: "End", detail: "at the start of Midday.")
                        Text("")
                        calculationHeading("Midday calculation")
                        calculationLine(label: "Start", detail: "5 minutes before Dhuhr.")
                        calculationLine(label: "End", detail: "at Dhuhr.")
                    }
                    .frame(maxWidth: min(containerSize.width - 36, 420))
                } else if isLastThird {
                    VStack(spacing: 4) {
                        hadithArabic(PHONE_LAST_THIRD_HADITH_AR)
                        Text("")
                        hadithEnglish(PHONE_LAST_THIRD_HADITH_EN)
                        hadithSource("Sahih Muslim, Hadith 758a")
                        Text("")
                        calculationHeading("Last 3rd calculation")
                        calculationLine(
                            label: "Start",
                            detail: "time between last Maghrib and Fajr divided by 3."
                        )
                        calculationLine(label: "End", detail: "at the start of Fajr.")
                    }
                    .frame(maxWidth: min(containerSize.width - 36, 420))
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, max(12, containerSize.height * 0.025))
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onTapGesture {
            onTap()
        }
    }
}

private struct RingTapShape: Shape {
    func path(in rect: CGRect) -> Path {
        let innerRatio = 0.25125 / (0.25125 + 0.081)
        let inset = rect.width * (1 - innerRatio) / 2
        var path = Path()
        path.addEllipse(in: rect)
        path.addEllipse(in: rect.insetBy(dx: inset, dy: inset))
        return path
    }
}

private struct PhoneRingTapShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let outerDiameter = outerRadius * 2
        let innerDiameter = innerRadius * 2
        let outerRect = CGRect(
            x: rect.midX - outerRadius,
            y: rect.midY - outerRadius,
            width: outerDiameter,
            height: outerDiameter
        )
        let innerRect = CGRect(
            x: rect.midX - innerRadius,
            y: rect.midY - innerRadius,
            width: innerDiameter,
            height: innerDiameter
        )

        var path = Path()
        path.addEllipse(in: outerRect)
        path.addEllipse(in: innerRect)
        return path
    }
}

// MARK: - Shake detector (debug Time Travel)

private struct ShakeDetectorView: UIViewRepresentable {
    var onShake: () -> Void
    
    func makeUIView(context: Context) -> ShakeDetectingUIView {
        let v = ShakeDetectingUIView()
        v.onShake = onShake
        return v
    }
    
    func updateUIView(_ uiView: ShakeDetectingUIView, context: Context) {
        uiView.onShake = onShake
    }
}

private class ShakeDetectingUIView: UIView {
    var onShake: (() -> Void)?
    
    override var canBecomeFirstResponder: Bool { true }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            _ = self?.becomeFirstResponder()
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
        super.motionEnded(motion, with: event)
    }
}

// MARK: - Time Travel sheet (debug)

private struct TimeTravelSheet: View {
    @Binding var monthOffset: Int
    @Binding var dayOffset: Int
    @Binding var hourOffset: Double
    @Binding var timeOffsetMs: Int64
    let currentHijriDay: Int
    @Environment(\.dismiss) private var dismiss
    
    private func applyOffset() {
        let totalDays = Int64(monthOffset) * 30 + Int64(dayOffset)
        timeOffsetMs = totalDays * MS_PER_DAY + Int64(hourOffset * Double(MS_PER_HOUR))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Shake to open • Debug Time Travel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Months") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(monthOffset) },
                            set: { monthOffset = Int($0); applyOffset() }
                        ), in: -6...6, step: 1)
                        Text(monthOffset == 0 ? "0" : "\(monthOffset > 0 ? "+" : "")\(monthOffset)m")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                Section("Days") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(dayOffset) },
                            set: { dayOffset = Int($0); applyOffset() }
                        ), in: -15...15, step: 1)
                        Text(dayOffset == 0 ? "0" : "\(dayOffset > 0 ? "+" : "")\(dayOffset)d")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                Section("Hours") {
                    HStack {
                        Slider(value: Binding(
                            get: { hourOffset },
                            set: { hourOffset = $0; applyOffset() }
                        ), in: -12...12, step: 0.5)
                        Text(hourOffset == 0 ? "0" : "\(hourOffset > 0 ? "+" : "")\(hourOffset, specifier: "%.1f")h")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                Section {
                    HStack {
                        Text("Day \(currentHijriDay)")
                            .fontWeight(.medium)
                        Spacer()
                        Button("Now") {
                            monthOffset = 0
                            dayOffset = 0
                            hourOffset = 0
                            timeOffsetMs = 0
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Colors.primaryGold)
                    }
                }
            }
            .navigationTitle("Time Travel")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black)
        }
    }
}

#Preview {
    ContentView()
}
