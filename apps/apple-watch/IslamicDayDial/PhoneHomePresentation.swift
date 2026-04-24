import Foundation

enum PhonePhaseBackgroundKey: String, Equatable {
    case fajr
    case sunrise
    case duha
    case midday
    case dhuhr
    case asr
    case maghrib
    case isha
    case lastThird

    var assetName: String {
        switch self {
        case .fajr: return "LoadingFajr"
        case .sunrise: return "LoadingSunrise"
        case .duha: return "LoadingDuha"
        case .midday: return "LoadingMidday"
        case .dhuhr: return "LoadingDhuhr"
        case .asr: return "LoadingAsr"
        case .maghrib: return "LoadingMaghrib"
        case .isha: return "LoadingIsha"
        case .lastThird: return "LoadingLastThird"
        }
    }
}

struct PhoneRingLegendItem: Equatable {
    let title: String
    let isActive: Bool
}

struct PhoneHomePresentation: Equatable {
    let backgroundKey: PhonePhaseBackgroundKey
    let rawSectorTitle: String
    let displayTitle: String
    let currentCueText: String
    let ringLegendItems: [PhoneRingLegendItem]
    let highlightedRingTitle: String?
    let isEidDay: Bool
}

let PHONE_CUE_FAJR = "If the sky is brightening, it is Fajr time."
let PHONE_CUE_SUNRISE = "Watch the horizon. Has the sun begun to rise?"
let PHONE_CUE_DUHA = "Look at the sun. Has the morning light clearly spread?"
let PHONE_CUE_MIDDAY = "The sun is at its highest point, and shadows are at their shortest. It is Midday."
let PHONE_CUE_DHUHR = "If the sun has passed the zenith and shadows have started to grow again, it is Dhuhr time."
let PHONE_CUE_ASR = "Asr starts when the shadow length equals the object's height plus its noon shadow."
let PHONE_CUE_MAGHRIB = "If the sun has gone down, Maghrib time has begun."
let PHONE_CUE_ISHA = "Isha starts when the last twilight has disappeared."
let PHONE_CUE_LAST_THIRD = "The last third of the night is here. Isha lasts from Maghrib to Fajr."
/// Same typographic slot as `OBSERVE` on other days (matches web `WEB_PHASE_GUIDANCE_JUMUAH_OVERLINE`).
let PHONE_PHASE_GUIDANCE_JUMUAH_OVERLINE = "Prepare for Jumu'ah"
let PHONE_CUE_JUMUAH = "Take a bath, use perfume, dress well, and remain silent during the khutbah."
/// Eid (incl. Friday): Duha, Midday, and Dhuhr sectors — replaces Jumu'ah prep / short Eid noon copy.
let PHONE_CUE_EID_DAYTIME_TAQABBAL = """
تَقَبَّلَ اللهُ مِنَّا وَمِنكُم
Taqabbalallahu minna wa minkum!
May Allah accept [this worship] from you and us!
"""
let PHONE_CUE_EID_AL_FITR = "Eid al-Fitr prayer time has started."
let PHONE_CUE_EID_AL_ADHA = "Eid al-Adha prayer time has started."

/// Quran 4:103 — below the dial on home (matches web `DialBelowRingAyah`).
let PHONE_DIAL_FOOTER_AYAH_4_103_AR = "إِنَّ ٱلصَّلَوٰةَ كَانَتْ عَلَى ٱلْمُؤْمِنِينَ كِتَـٰبًۭا مَّوْقُوتًۭا"
let PHONE_DIAL_FOOTER_AYAH_4_103_EN = "\"Indeed, performing prayers is a duty on the believers at the appointed times.\" [4:103]"

private let PHONE_BASE_RING_LEGEND_TITLES = [
    "Fajr",
    "Duha",
    "Dhuhr",
    "Asr",
    "Maghrib",
    "Isha",
    "Last 3rd",
]

private let PHONE_SUPPORTED_READING_TITLES: Set<String> = [
    "Fajr",
    "Sunrise",
    "Duha",
    "Midday",
    "Dhuhr",
    "Asr",
    "Maghrib",
    "Isha",
    "Last 3rd",
    "Jumu'ah",
]

func phoneObservationalCueText(for title: String) -> String {
    switch title {
    case "Fajr":
        return PHONE_CUE_FAJR
    case "Sunrise":
        return PHONE_CUE_SUNRISE
    case "Duha":
        return PHONE_CUE_DUHA
    case "Midday":
        return PHONE_CUE_MIDDAY
    case "Dhuhr":
        return PHONE_CUE_DHUHR
    case "Asr":
        return PHONE_CUE_ASR
    case "Maghrib":
        return PHONE_CUE_MAGHRIB
    case "Isha":
        return PHONE_CUE_ISHA
    case "Last 3rd":
        return PHONE_CUE_LAST_THIRD
    case "Jumu'ah":
        return PHONE_CUE_JUMUAH
    case "EID AL-FITR":
        return PHONE_CUE_EID_AL_FITR
    case "EID AL-ADHA":
        return PHONE_CUE_EID_AL_ADHA
    default:
        return title
    }
}

/// Overline above phase guidance: `Prepare for Jumu'ah` on Friday noon window; empty for Eid Taqabbal; else `OBSERVE`.
func phonePhaseGuidanceModeLabel(displayTitle: String, cueText: String) -> String {
    if displayTitle == "Jumu'ah" { return PHONE_PHASE_GUIDANCE_JUMUAH_OVERLINE }
    if cueText == PHONE_CUE_EID_DAYTIME_TAQABBAL { return "" }
    return "OBSERVE"
}

func phoneReadingTitle(for presentation: PhoneHomePresentation) -> String? {
    if PHONE_SUPPORTED_READING_TITLES.contains(presentation.displayTitle) {
        return presentation.displayTitle
    }
    if PHONE_SUPPORTED_READING_TITLES.contains(presentation.rawSectorTitle) {
        return presentation.rawSectorTitle
    }
    return nil
}

private func phoneEidHeadingTitle(hijriDate: HijriDate) -> String {
    if hijriDate.monthNumber == 10 && hijriDate.day == 1 {
        return "EID AL-FITR"
    }
    if hijriDate.monthNumber == 12 && hijriDate.day == 10 {
        return "EID AL-ADHA"
    }
    return ""
}

/// Cue under the main title: Eid prayer copy during the noon window when the title shows the Eid heading; otherwise sector cue.
private func phoneHomeCurrentCueText(
    snapshot: ComputedIslamicDay,
    now: Date,
    rawSectorTitle: String,
    displayTitle: String,
    hijriParts: (dayMonth: String, year: String, isEid: Bool)
) -> String {
    guard hijriParts.isEid else {
        return phoneObservationalCueText(for: displayTitle)
    }
    switch snapshot.currentPhase {
    case .sunrise_to_dhuhr:
        let sub = getSunriseToDhuhrSubPeriod(
            now: now,
            duhaStart: snapshot.timeline.duhaStart,
            dhuhr: snapshot.timeline.dhuhr
        )
        if sub == .duha || sub == .midday {
            return PHONE_CUE_EID_DAYTIME_TAQABBAL
        }
    case .dhuhr_to_asr:
        return PHONE_CUE_EID_DAYTIME_TAQABBAL
    default:
        break
    }
    return phoneObservationalCueText(for: rawSectorTitle)
}

func makePhoneHomePresentation(snapshot: ComputedIslamicDay, now: Date) -> PhoneHomePresentation {
    let rawSectorTitle = getSectorDisplayName(
        now: now,
        currentPhase: snapshot.currentPhase,
        timeline: (duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr)
    )
    let hijriParts = formatHijriDateParts(snapshot.hijriDate)
    let displayTitle = phoneDisplayTitle(
        snapshot: snapshot,
        now: now,
        rawSectorTitle: rawSectorTitle,
        hijriParts: hijriParts
    )
    let ringLegendTitles = phoneRingLegendTitles(now: now, isEidDay: hijriParts.isEid)
    let highlightedRingTitle = ringLegendTitles.contains(displayTitle)
        ? displayTitle
        : (ringLegendTitles.contains(rawSectorTitle) ? rawSectorTitle : nil)

    return PhoneHomePresentation(
        backgroundKey: phoneBackgroundKey(snapshot: snapshot, now: now),
        rawSectorTitle: rawSectorTitle,
        displayTitle: displayTitle,
        currentCueText: phoneHomeCurrentCueText(
            snapshot: snapshot,
            now: now,
            rawSectorTitle: rawSectorTitle,
            displayTitle: displayTitle,
            hijriParts: hijriParts
        ),
        ringLegendItems: ringLegendTitles.map {
            PhoneRingLegendItem(title: $0, isActive: $0 == highlightedRingTitle)
        },
        highlightedRingTitle: highlightedRingTitle,
        isEidDay: hijriParts.isEid
    )
}

private func phoneBackgroundKey(snapshot: ComputedIslamicDay, now: Date) -> PhonePhaseBackgroundKey {
    switch snapshot.currentPhase {
    case .maghrib_to_isha:
        return .maghrib
    case .isha_to_last_third:
        return .isha
    case .last_third_to_fajr:
        return .lastThird
    case .fajr_to_sunrise:
        return .fajr
    case .sunrise_to_dhuhr:
        switch getSunriseToDhuhrSubPeriod(
            now: now,
            duhaStart: snapshot.timeline.duhaStart,
            dhuhr: snapshot.timeline.dhuhr
        ) {
        case .sunrise:
            return .sunrise
        case .duha:
            return .duha
        case .midday:
            return .midday
        }
    case .dhuhr_to_asr:
        return .dhuhr
    case .asr_to_maghrib:
        return .asr
    }
}

private func phoneDisplayTitle(
    snapshot: ComputedIslamicDay,
    now: Date,
    rawSectorTitle: String,
    hijriParts: (dayMonth: String, year: String, isEid: Bool)
) -> String {
    guard hijriParts.isEid else { return rawSectorTitle }
    let eid = phoneEidHeadingTitle(hijriDate: snapshot.hijriDate)
    return eid.isEmpty ? rawSectorTitle : eid
}

private func phoneRingLegendTitles(now: Date, isEidDay: Bool) -> [String] {
    guard Calendar.current.component(.weekday, from: now) == 6, !isEidDay else {
        return PHONE_BASE_RING_LEGEND_TITLES
    }

    return PHONE_BASE_RING_LEGEND_TITLES.map { title in
        title == "Dhuhr" ? "Jumu'ah" : title
    }
}
