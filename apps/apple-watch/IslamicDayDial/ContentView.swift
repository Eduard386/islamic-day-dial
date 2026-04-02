import SwiftUI
import CoreText
import UIKit

private let DIAL_VERTICAL_GAP: CGFloat = 18
private let DIAL_SECTION_HEIGHT: CGFloat = 436
private let MS_PER_HOUR: Int64 = 3_600_000
private let MS_PER_DAY: Int64 = 24 * MS_PER_HOUR
private let PHONE_PRIMARY_TRANSITION_DURATION = 0.6
private let PHONE_DATE_INFO_SCALE: CGFloat = 1.25
private let PHONE_TEXT_GLOW_PULSE_DURATION = 3.0
let PHONE_READING_TINT = Color(red: 0.84, green: 0.81, blue: 0.75)
private let PHONE_SACRED_WHITE = Color(red: 0.918, green: 0.898, blue: 0.84)
private let PHONE_SOFT_WHITE = Color(red: 0.83, green: 0.8, blue: 0.75)
private let PHONE_MUTED_META = Color(red: 0.62, green: 0.592, blue: 0.556)
private let PHONE_ANTIQUE_GOLD = Color(red: 0.705, green: 0.552, blue: 0.262)
private let PHONE_SCREEN_TITLE = PHONE_SACRED_WHITE
private let PHONE_PANEL_STROKE = Color(red: 0.82, green: 0.76, blue: 0.66).opacity(0.045)
private let PHONE_PANEL_HIGHLIGHT = Color(red: 0.9, green: 0.84, blue: 0.74).opacity(0.028)
private let PHONE_PANEL_SHADOW = Color(red: 0.02, green: 0.016, blue: 0.012).opacity(0.18)
private let PHONE_PANEL_RADIUS: CGFloat = 20
private let PHONE_PANEL_HORIZONTAL_PADDING: CGFloat = 24
private let PHONE_PANEL_VERTICAL_PADDING: CGFloat = 22
private let PHONE_SECTOR_LABEL_COLOR = Color(red: 0.78, green: 0.84, blue: 0.92)
private let PHONE_ATMOS_TOP_OPACITY = 0.38
private let PHONE_ATMOS_MID_OPACITY = 0.14
private let PHONE_ATMOS_BOTTOM_OPACITY = 0.30
private let PHONE_SECONDARY_SCREEN_OFFSET: CGFloat = 18
private let PHONE_DUST_TINT = Color(red: 0.23, green: 0.18, blue: 0.13)
private let PHONE_DRY_SHADE = Color(red: 0.06, green: 0.05, blue: 0.04)
private let PHONE_INSIGHT_AYAH_AR = "قال الله تعالى: إِنَّ عِدَّةَ الشُّهُورِ عِندَ اللَّهِ اثْنَا عَشَرَ شَهْرًا"
private let PHONE_INSIGHT_AYAH_EN = "Allah, the Exalted, said:\"Indeed, the number of months ordained by Allah is twelve\" [9:36]"
private let PHONE_LOADING_STILL_ZOOM_MIN: CGFloat = 1.012
private let PHONE_LOADING_STILL_ZOOM_MAX: CGFloat = 1.032
private let PHONE_LOADING_STILL_ZOOM_DURATION = 9.0
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
private let PHONE_JUMUAH_AYAH_AR = "قال الله تعالى: يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا نُودِىَ لِلصَّلَوٰةِ مِن يَوْمِ ٱلْجُمُعَةِ فَٱسْعَوْا۟ إِلَىٰ ذِكْرِ ٱللَّهِ وَذَرُوا۟ ٱلْبَيْعَ ۚ ذَٰلِكُمْ خَيْرٌۭ لَّكُمْ إِن كُنتُمْ تَعْلَمُونَ"
private let PHONE_JUMUAH_AYAH_EN = "Allah, the Exalted, said: \"O believers! When the call to prayer is made on Friday, then proceed (diligently) to the remembrance of Allah and leave off (your) business. That is best for you, if only you knew\" [62:9]"
private let PHONE_JUMUAH_HADITH_ONE_AR = "عَنِ النَّبِيِّ صلى الله عليه وسلم قَالَ ‏ \"الْجُمُعَةُ حَقٌّ وَاجِبٌ عَلَى كُلِّ مُسْلِمٍ فِي جَمَاعَةٍ إِلاَّ أَرْبَعَةً عَبْدٌ مَمْلُوكٌ أَوِ امْرَأَةٌ أَوْ صَبِيٌّ أَوْ مَرِيضٌ‏\""
private let PHONE_JUMUAH_HADITH_ONE_EN = "The Prophet (ﷺ) said: \"The Friday prayer in congregation is a necessary duty for every Muslim, with four exceptions; a slave, a woman, a boy, and a sick person.\""
private let PHONE_JUMUAH_HADITH_TWO_AR = "عَنِ النَّبِيِّ صلى الله عليه وسلم قَالَ ‏ \"مَنِ اغْتَسَلَ ثُمَّ أَتَى الْجُمُعَةَ فَصَلَّى مَا قُدِّرَ لَهُ ثُمَّ أَنْصَتَ حَتَّى يَفْرُغَ مِنْ خُطْبَتِهِ ثُمَّ يُصَلِّيَ مَعَهُ غُفِرَ لَهُ مَا بَيْنَهُ وَبَيْنَ الْجُمُعَةِ الأُخْرَى وَفَضْلَ ثَلاَثَةِ أَيَّامٍ‏\"‏‏"
private let PHONE_JUMUAH_HADITH_TWO_EN = "The Prophet (ﷺ) said: \"He who took a bath and then came for Jumu'ah prayer and then prayed what was fixed for him, then kept silence till the Imam finished the sermon, and then prayed along with him, his sins between that time and the next Friday would be forgiven, and even of three days more.\""
private let PHONE_JUMUAH_HADITH_THREE_AR = "حَدَّثَنَا عَبْدُ اللَّهِ بْنُ يُوسُفَ، قَالَ أَخْبَرَنَا مَالِكٌ، عَنْ نَافِعٍ، عَنْ عَبْدِ اللَّهِ بْنِ عُمَرَ، أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم كَانَ يُصَلِّي قَبْلَ الظُّهْرِ رَكْعَتَيْنِ، وَبَعْدَهَا رَكْعَتَيْنِ، وَبَعْدَ الْمَغْرِبِ رَكْعَتَيْنِ فِي بَيْتِهِ، وَبَعْدَ الْعِشَاءِ رَكْعَتَيْنِ وَكَانَ لاَ يُصَلِّي بَعْدَ الْجُمُعَةِ حَتَّى يَنْصَرِفَ فَيُصَلِّي رَكْعَتَيْنِ‏.‏"
private let PHONE_JUMUAH_HADITH_THREE_EN = "Narrated `Abdullah bin `Umar: Allah's Messenger (ﷺ) used to pray two rak`at before the Zuhr prayer and two rak`at after it. He also used to pray two rak`at after the Maghrib prayer in his house, and two rak`at after the `Isha' prayer. He never prayed after Jumu'ah prayer till he departed (from the Mosque), and then he would pray two rak`at at home."

private func phoneSelectionHaptic() {
    let generator = UISelectionFeedbackGenerator()
    generator.prepare()
    generator.selectionChanged()
}

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

private func normalizedDialAngle(_ angle: Double) -> Double {
    let remainder = angle.truncatingRemainder(dividingBy: 360)
    return remainder >= 0 ? remainder : remainder + 360
}

private func phoneHomeBackgroundScrimOpacity(for key: PhonePhaseBackgroundKey) -> Double {
    0
}

private func phoneOverlayScrimOpacity(isSecondaryScreenPresented: Bool) -> Double {
    isSecondaryScreenPresented ? 0.4 : 0
}

private func phoneDisplayFont(size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .system(size: size, weight: weight, design: .default)
}

private func phoneTextFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .default)
}

private func phoneArabicUIFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
    let preferredNames: [String] = [
        "Amiri-Regular",
        "Amiri",
        "NotoNaskhArabic-Medium",
        "NotoNaskhArabic-Regular",
        "Noto Naskh Arabic",
        "SFArabic-Regular"
    ]
    for name in preferredNames {
        if let font = UIFont(name: name, size: size) {
            return font
        }
    }
    return UIFont.systemFont(ofSize: size, weight: weight)
}

private func phoneArabicFont(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
    Font(phoneArabicUIFont(size: size, weight: weight))
}

private func phonePhaseTitleFont(containerSize: CGSize) -> Font {
    phoneDisplayFont(size: min(44, containerSize.width * 0.112), weight: .semibold)
}

private func phoneHijriDateFont(containerSize: CGSize) -> Font {
    phoneDisplayFont(size: min(26, containerSize.width * 0.069), weight: .medium)
}

private func phoneSectionTitleFont(containerSize: CGSize) -> Font {
    phoneDisplayFont(size: min(24, containerSize.width * 0.064), weight: .semibold)
}

private func phoneBodyFont(containerSize: CGSize) -> Font {
    phoneTextFont(size: min(19, containerSize.width * 0.051), weight: .regular)
}

private func phoneLabelFont(containerSize: CGSize) -> Font {
    phoneTextFont(size: min(18, containerSize.width * 0.048), weight: .semibold)
}

private func phoneTranslationFont(containerSize: CGSize) -> Font {
    phoneTextFont(size: min(20, containerSize.width * 0.054), weight: .regular)
}

private func phoneMetadataFont(containerSize: CGSize) -> Font {
    phoneTextFont(size: min(17, containerSize.width * 0.046), weight: .medium)
}

private enum PhoneSurfaceTone {
    case standard
    case reading

    var fillTop: Color {
        switch self {
        case .standard:
            return Color(red: 0.138, green: 0.108, blue: 0.087).opacity(0.94)
        case .reading:
            return Color(red: 0.126, green: 0.098, blue: 0.079).opacity(0.97)
        }
    }

    var fillBottom: Color {
        switch self {
        case .standard:
            return Color(red: 0.088, green: 0.071, blue: 0.058).opacity(0.97)
        case .reading:
            return Color(red: 0.068, green: 0.055, blue: 0.046).opacity(0.985)
        }
    }

    var edgeOpacity: Double {
        switch self {
        case .standard:
            return 0.045
        case .reading:
            return 0.035
        }
    }
}

private struct PhoneDebossedTextModifier: ViewModifier {
    let highlightOpacity: Double
    let shadowOpacity: Double
    let ambientOpacity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: Color.white.opacity(highlightOpacity), radius: 0, x: 0, y: -0.55)
            .shadow(color: PHONE_DRY_SHADE.opacity(shadowOpacity), radius: 0, x: 0, y: 0.85)
            .shadow(color: Color.black.opacity(ambientOpacity), radius: 2.4, x: 0, y: 1.45)
    }
}

private extension View {
    func phoneDebossedTitle() -> some View {
        modifier(PhoneDebossedTextModifier(
            highlightOpacity: 0.1,
            shadowOpacity: 0.22,
            ambientOpacity: 0.1
        ))
    }

    func phoneDebossedBody() -> some View {
        modifier(PhoneDebossedTextModifier(
            highlightOpacity: 0.06,
            shadowOpacity: 0.16,
            ambientOpacity: 0.07
        ))
    }
}

private enum PhoneReadingScreenMode {
    case dalil
    case technical
}

private enum PhoneSecondaryScreen: Equatable {
    case hijri
    case dalil(String)
    case technical(String)
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var notificationOverlay: PhoneNotificationOverlayStore
    @AppStorage("phone.lastLoadingStillKey") private var persistedLoadingStillKeyRaw = PhonePhaseBackgroundKey.fajr.rawValue
    @State private var automaticLocation: Location = .mecca
    @State private var snapshot: ComputedIslamicDay?
    @State private var now = Date()
    
    // Debug Time Travel (shake to reveal)
    @State private var showTimeTravel = false
    @State private var monthOffset = 0
    @State private var dayOffset = 0
    @State private var hourOffset: Double = 0
    @State private var timeOffsetMs: Int64 = 0
    @State private var secondaryScreen: PhoneSecondaryScreen?
    @State private var isInteractionLocked = false
    @State private var interactionLockTask: Task<Void, Never>?
    @State private var showsStartupLoadingStill = true
    @State private var currentLoadingStillKey = PhonePhaseBackgroundKey.fajr
    @State private var previousLoadingStillKey: PhonePhaseBackgroundKey?
    @State private var currentBackgroundOpacity = 1.0
    @State private var startupDialOpacity = 0.0

    private var effectiveNow: Date {
        if timeOffsetMs == 0 { return now }
        return now.addingTimeInterval(Double(timeOffsetMs) / 1000)
    }

    private var debugPushHandler: (() -> Void)? {
        #if DEBUG
        return sendNextDebugNotification
        #else
        return nil
        #endif
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    ZStack {
                        if let previousLoadingStillKey {
                            PhoneLoadingStillView(key: previousLoadingStillKey)
                                .ignoresSafeArea()
                        }

                        PhoneLoadingStillView(key: currentLoadingStillKey)
                            .opacity(currentBackgroundOpacity)
                            .ignoresSafeArea()

                        Color.black
                            .opacity((1 - currentBackgroundOpacity) * 0.24)
                            .ignoresSafeArea()
                    }
                    .allowsHitTesting(false)

                    PhoneAtmosphericOverlay(
                        baseDim: phoneHomeBackgroundScrimOpacity(for: currentLoadingStillKey),
                        modalDim: phoneOverlayScrimOpacity(
                            isSecondaryScreenPresented: secondaryScreen != nil
                        )
                    )
                    .allowsHitTesting(false)

                    homeSummarySection(containerSize: geo.size)
                    .opacity(secondaryScreen == nil ? 1 : 0.08)
                    .animation(
                        .easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION),
                        value: secondaryScreen != nil
                    )
                    .allowsHitTesting(
                        !showsStartupLoadingStill &&
                        !isInteractionLocked &&
                        secondaryScreen == nil
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .overlay {
                        ShakeDetectorView { showTimeTravel = true }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        if secondaryScreen != nil {
                            ZStack {
                                Color(red: 0.07, green: 0.055, blue: 0.042)
                                    .opacity(0.46)

                                LinearGradient(
                                    colors: [
                                        Color(red: 0.11, green: 0.085, blue: 0.062).opacity(0.34),
                                        Color.black.opacity(0.22),
                                        Color(red: 0.045, green: 0.036, blue: 0.028).opacity(0.44)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )

                                RadialGradient(
                                    colors: [
                                        Color(red: 0.23, green: 0.18, blue: 0.13).opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .top,
                                    startRadius: 0,
                                    endRadius: min(geo.size.width * 0.7, 320)
                                )

                                PHONE_DUST_TINT
                                    .opacity(0.12)
                                    .blendMode(.multiply)
                            }
                            .ignoresSafeArea()
                            .allowsHitTesting(!isInteractionLocked)
                            .onTapGesture {
                                dismissSecondaryScreen(triggerHaptic: false)
                            }
                        }
                    }
                    .overlay {
                        if let snapshot, let secondaryScreen {
                            PhoneSecondaryScreenContainer(
                                screen: secondaryScreen,
                                snapshot: snapshot,
                                containerSize: geo.size,
                                onShowDalil: presentDalilScreen,
                                onShowTechnical: presentTechnicalScreen,
                                onDismiss: { dismissSecondaryScreen(triggerHaptic: false) }
                            )
                            .allowsHitTesting(!isInteractionLocked)
                            .transition(
                                .asymmetric(
                                    insertion: .offset(y: PHONE_SECONDARY_SCREEN_OFFSET).combined(with: .opacity),
                                    removal: .opacity
                                )
                            )
                        }
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
        .onChange(of: timeOffsetMs) { _ in recalcSnapshot() }
        .onChange(of: snapshot != nil) { hasSnapshot in
            guard hasSnapshot, showsStartupLoadingStill else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(120))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION)) {
                        startupDialOpacity = 1
                    }
                }
                try? await Task.sleep(for: .seconds(PHONE_PRIMARY_TRANSITION_DURATION))
                await MainActor.run {
                    showsStartupLoadingStill = false
                    if notificationOverlay.currentMessage != nil {
                        notificationOverlay.resumePresentationIfNeeded()
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await refreshSnapshot(forceResolveLocation: true) }
            }
        }
        .sheet(isPresented: $showTimeTravel) {
            TimeTravelSheet(
                monthOffset: $monthOffset,
                dayOffset: $dayOffset,
                hourOffset: $hourOffset,
                timeOffsetMs: $timeOffsetMs,
                currentHijriDay: snapshot?.hijriDate.day ?? 1,
                onDebugPush: debugPushHandler
            )
        }
        .onDisappear {
            interactionLockTask?.cancel()
        }
        .onAppear {
            currentLoadingStillKey = PhonePhaseBackgroundKey(rawValue: persistedLoadingStillKeyRaw) ?? .fajr
            previousLoadingStillKey = nil
            currentBackgroundOpacity = 1
            startupDialOpacity = showsStartupLoadingStill ? 0 : 1
            if notificationOverlay.currentMessage != nil {
                if showsStartupLoadingStill {
                    notificationOverlay.suspendPresentation()
                }
                returnToMainScreenForNotification()
            }
        }
        .onChange(of: notificationOverlay.presentationID) { _ in
            guard notificationOverlay.currentMessage != nil else { return }
            if showsStartupLoadingStill {
                notificationOverlay.suspendPresentation()
            }
            returnToMainScreenForNotification()
        }
    }
    
    private func recalcSnapshot() {
        let updatedSnapshot = computeIslamicDaySnapshot(now: effectiveNow, location: automaticLocation)
        snapshot = updatedSnapshot
        if let updatedSnapshot {
            updateLoadingStillKey(with: updatedSnapshot, renderNow: effectiveNow)
            WatchMirrorSyncService.shared.push(
                snapshot: updatedSnapshot,
                location: automaticLocation,
                renderNow: effectiveNow
            )
        }
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
    
    private func homeSummarySection(containerSize: CGSize) -> some View {
        Group {
            if let snapshot {
                let homePresentation = makePhoneHomePresentation(snapshot: snapshot, now: effectiveNow)
                VStack(spacing: 0) {
                    PhoneHomeSummaryView(
                        snapshot: snapshot,
                        now: effectiveNow,
                        presentation: homePresentation,
                        containerSize: containerSize,
                        isInteractive: !isInteractionLocked,
                        onDateTap: beginInsightPresentation,
                        onCurrentSectorTap: beginCurrentSectorReading
                    )
                    Spacer(minLength: 0)
                }
                .opacity(startupDialOpacity)
            } else {
                Color.clear
            }
        }
    }

    private func beginInsightPresentation() {
        guard
            !isInteractionLocked,
            secondaryScreen == nil
        else { return }
        lockInteractions()
        notificationOverlay.dismissIfVisible()
        phoneSelectionHaptic()
        withAnimation(.easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION)) {
            secondaryScreen = .hijri
        }
    }

    private func dismissInsightPresentation(triggerHaptic: Bool) {
        guard case .hijri? = secondaryScreen else { return }
        dismissSecondaryScreen(triggerHaptic: triggerHaptic)
    }

    private func beginCurrentSectorReading() {
        guard
            let snapshot,
            let title = phoneReadingTitle(
                for: makePhoneHomePresentation(snapshot: snapshot, now: effectiveNow)
            )
        else { return }

        beginSectorSpotlight(title: title)
    }

    private func beginSectorSpotlight(title: String) {
        guard
            !isInteractionLocked,
            secondaryScreen == nil
        else { return }
        presentDalilScreen(title)
    }

    private func presentDalilScreen(_ title: String) {
        lockInteractions()
        notificationOverlay.dismissIfVisible()
        phoneSelectionHaptic()
        withAnimation(.easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION)) {
            secondaryScreen = .dalil(title)
        }
    }

    private func presentTechnicalScreen(_ title: String) {
        guard !isInteractionLocked else { return }
        lockInteractions()
        withAnimation(.easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION)) {
            secondaryScreen = .technical(title)
        }
    }

    private func dismissSecondaryScreen(triggerHaptic: Bool = true) {
        guard secondaryScreen != nil else { return }
        lockInteractions()
        if triggerHaptic {
            phoneSelectionHaptic()
        }
        withAnimation(.easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION)) {
            secondaryScreen = nil
        }
    }

    private func lockInteractions() {
        interactionLockTask?.cancel()
        isInteractionLocked = true
        interactionLockTask = Task {
            try? await Task.sleep(for: .seconds(PHONE_PRIMARY_TRANSITION_DURATION))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isInteractionLocked = false
            }
        }
    }

    private func returnToMainScreenForNotification() {
        interactionLockTask?.cancel()
        showTimeTravel = false
        let needsAnimatedReturn = secondaryScreen != nil

        guard needsAnimatedReturn else {
            isInteractionLocked = false
            secondaryScreen = nil
            return
        }

        isInteractionLocked = true
        withAnimation(.easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION)) {
            secondaryScreen = nil
        }

        interactionLockTask = Task {
            try? await Task.sleep(for: .seconds(PHONE_PRIMARY_TRANSITION_DURATION))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isInteractionLocked = false
            }
        }
    }
    
    private func refreshSnapshot(forceResolveLocation: Bool) async {
        if forceResolveLocation || snapshot == nil {
            let result = await resolveGeoResult()
            automaticLocation = result.location
            if forceResolveLocation {
                Task {
                    await PrayerNotificationScheduler.requestAndSchedule(location: automaticLocation)
                }
            }
        }
        
        let currentNow = Date()
        now = currentNow
        let displayNow = currentNow.addingTimeInterval(Double(timeOffsetMs) / 1000)
        let updatedSnapshot = computeIslamicDaySnapshot(now: displayNow, location: automaticLocation)
        snapshot = updatedSnapshot
        if let updatedSnapshot {
            updateLoadingStillKey(with: updatedSnapshot, renderNow: displayNow)
            WatchMirrorSyncService.shared.push(
                snapshot: updatedSnapshot,
                location: automaticLocation,
                renderNow: displayNow,
                generatedAt: currentNow
            )
        }
    }

    private func updateLoadingStillKey(with snapshot: ComputedIslamicDay, renderNow: Date) {
        let nextKey = makePhoneHomePresentation(snapshot: snapshot, now: renderNow).backgroundKey
        guard nextKey != currentLoadingStillKey else {
            persistedLoadingStillKeyRaw = nextKey.rawValue
            return
        }

        previousLoadingStillKey = currentLoadingStillKey
        currentLoadingStillKey = nextKey
        persistedLoadingStillKeyRaw = nextKey.rawValue
        currentBackgroundOpacity = 0

        withAnimation(.easeInOut(duration: PHONE_PRIMARY_TRANSITION_DURATION)) {
            currentBackgroundOpacity = 1
        }

        Task {
            try? await Task.sleep(for: .seconds(PHONE_PRIMARY_TRANSITION_DURATION))
            await MainActor.run {
                previousLoadingStillKey = nil
            }
        }
    }

    #if DEBUG
    private func sendNextDebugNotification() {
        Task {
            await PrayerNotificationScheduler.sendSequentialDebugNotification(
                date: effectiveNow,
                location: automaticLocation,
                surface: "ios"
            )
        }
    }
    #endif
}

private struct PhoneAtmosphericOverlay: View {
    let baseDim: Double
    let modalDim: Double

    var body: some View {
        ZStack {
            PHONE_DUST_TINT
                .opacity(0.05 + baseDim * 0.03)
                .blendMode(.multiply)

            Color.black.opacity(0.04 + baseDim * 0.04)

            LinearGradient(
                colors: [
                    Color.black.opacity(PHONE_ATMOS_TOP_OPACITY + baseDim * 0.12),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            Color.black.opacity(PHONE_ATMOS_MID_OPACITY + baseDim * 0.08)

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(PHONE_ATMOS_BOTTOM_OPACITY + baseDim * 0.12)
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    PHONE_DUST_TINT.opacity(0.08 + baseDim * 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)

            if modalDim > 0 {
                Color(red: 0.052, green: 0.041, blue: 0.032)
                    .opacity(min(0.36, modalDim * 0.7))

                PHONE_DUST_TINT
                    .opacity(min(0.12, modalDim * 0.22))
                    .blendMode(.multiply)
            }
        }
        .ignoresSafeArea()
    }
}

private struct PhoneObserveSceneStyle {
    let skyTop: Color
    let skyBottom: Color
    let skyOpacity: Double
    let horizonColor: Color
    let horizonOpacity: Double
    let lightColor: Color
    let lightOpacity: Double
    let lightCenter: UnitPoint
    let lightRadiusScale: CGFloat
    let dustOpacity: Double
    let poleFillTop: Color
    let poleFillBottom: Color
    let poleHighlightOpacity: Double
    let poleShadowOpacity: Double
    let shadowAngleDeg: Double
    let shadowLengthScale: CGFloat
    let shadowWidth: CGFloat
    let shadowOpacity: Double
    let shadowBlur: CGFloat
}

private func phoneObserveSceneStyle(for key: PhonePhaseBackgroundKey) -> PhoneObserveSceneStyle {
    switch key {
    case .fajr:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.12, green: 0.14, blue: 0.21),
            skyBottom: Color(red: 0.28, green: 0.22, blue: 0.18),
            skyOpacity: 0.34,
            horizonColor: Color(red: 0.76, green: 0.63, blue: 0.46),
            horizonOpacity: 0.22,
            lightColor: Color(red: 0.66, green: 0.62, blue: 0.54),
            lightOpacity: 0.12,
            lightCenter: UnitPoint(x: 0.18, y: 0.24),
            lightRadiusScale: 0.7,
            dustOpacity: 0.08,
            poleFillTop: Color(red: 0.29, green: 0.22, blue: 0.16),
            poleFillBottom: Color(red: 0.18, green: 0.13, blue: 0.09),
            poleHighlightOpacity: 0.05,
            poleShadowOpacity: 0.12,
            shadowAngleDeg: 132,
            shadowLengthScale: 0.34,
            shadowWidth: 26,
            shadowOpacity: 0.16,
            shadowBlur: 16
        )
    case .sunrise:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.31, green: 0.27, blue: 0.23),
            skyBottom: Color(red: 0.66, green: 0.45, blue: 0.28),
            skyOpacity: 0.3,
            horizonColor: Color(red: 0.85, green: 0.63, blue: 0.34),
            horizonOpacity: 0.28,
            lightColor: Color(red: 0.92, green: 0.76, blue: 0.46),
            lightOpacity: 0.24,
            lightCenter: UnitPoint(x: 0.18, y: 0.31),
            lightRadiusScale: 0.58,
            dustOpacity: 0.1,
            poleFillTop: Color(red: 0.34, green: 0.25, blue: 0.17),
            poleFillBottom: Color(red: 0.21, green: 0.15, blue: 0.1),
            poleHighlightOpacity: 0.07,
            poleShadowOpacity: 0.16,
            shadowAngleDeg: 128,
            shadowLengthScale: 0.4,
            shadowWidth: 28,
            shadowOpacity: 0.2,
            shadowBlur: 16
        )
    case .duha:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.46, green: 0.49, blue: 0.48),
            skyBottom: Color(red: 0.74, green: 0.66, blue: 0.54),
            skyOpacity: 0.18,
            horizonColor: Color(red: 0.83, green: 0.74, blue: 0.56),
            horizonOpacity: 0.16,
            lightColor: Color(red: 0.93, green: 0.86, blue: 0.64),
            lightOpacity: 0.16,
            lightCenter: UnitPoint(x: 0.22, y: 0.19),
            lightRadiusScale: 0.54,
            dustOpacity: 0.08,
            poleFillTop: Color(red: 0.35, green: 0.27, blue: 0.18),
            poleFillBottom: Color(red: 0.22, green: 0.16, blue: 0.11),
            poleHighlightOpacity: 0.06,
            poleShadowOpacity: 0.14,
            shadowAngleDeg: 120,
            shadowLengthScale: 0.26,
            shadowWidth: 24,
            shadowOpacity: 0.16,
            shadowBlur: 14
        )
    case .midday:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.53, green: 0.56, blue: 0.56),
            skyBottom: Color(red: 0.73, green: 0.67, blue: 0.58),
            skyOpacity: 0.14,
            horizonColor: Color(red: 0.86, green: 0.8, blue: 0.68),
            horizonOpacity: 0.1,
            lightColor: Color(red: 0.96, green: 0.9, blue: 0.7),
            lightOpacity: 0.12,
            lightCenter: UnitPoint(x: 0.5, y: 0.1),
            lightRadiusScale: 0.5,
            dustOpacity: 0.06,
            poleFillTop: Color(red: 0.33, green: 0.25, blue: 0.17),
            poleFillBottom: Color(red: 0.21, green: 0.16, blue: 0.11),
            poleHighlightOpacity: 0.05,
            poleShadowOpacity: 0.12,
            shadowAngleDeg: 98,
            shadowLengthScale: 0.11,
            shadowWidth: 18,
            shadowOpacity: 0.12,
            shadowBlur: 10
        )
    case .dhuhr:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.52, green: 0.55, blue: 0.55),
            skyBottom: Color(red: 0.74, green: 0.67, blue: 0.58),
            skyOpacity: 0.15,
            horizonColor: Color(red: 0.84, green: 0.77, blue: 0.64),
            horizonOpacity: 0.12,
            lightColor: Color(red: 0.95, green: 0.88, blue: 0.68),
            lightOpacity: 0.12,
            lightCenter: UnitPoint(x: 0.54, y: 0.12),
            lightRadiusScale: 0.52,
            dustOpacity: 0.06,
            poleFillTop: Color(red: 0.33, green: 0.25, blue: 0.17),
            poleFillBottom: Color(red: 0.2, green: 0.15, blue: 0.11),
            poleHighlightOpacity: 0.05,
            poleShadowOpacity: 0.12,
            shadowAngleDeg: 104,
            shadowLengthScale: 0.16,
            shadowWidth: 20,
            shadowOpacity: 0.13,
            shadowBlur: 11
        )
    case .asr:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.44, green: 0.43, blue: 0.39),
            skyBottom: Color(red: 0.71, green: 0.59, blue: 0.46),
            skyOpacity: 0.22,
            horizonColor: Color(red: 0.86, green: 0.69, blue: 0.43),
            horizonOpacity: 0.17,
            lightColor: Color(red: 0.89, green: 0.73, blue: 0.44),
            lightOpacity: 0.2,
            lightCenter: UnitPoint(x: 0.78, y: 0.2),
            lightRadiusScale: 0.56,
            dustOpacity: 0.09,
            poleFillTop: Color(red: 0.34, green: 0.25, blue: 0.18),
            poleFillBottom: Color(red: 0.2, green: 0.15, blue: 0.1),
            poleHighlightOpacity: 0.06,
            poleShadowOpacity: 0.16,
            shadowAngleDeg: 58,
            shadowLengthScale: 0.31,
            shadowWidth: 24,
            shadowOpacity: 0.18,
            shadowBlur: 13
        )
    case .maghrib:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.27, green: 0.2, blue: 0.18),
            skyBottom: Color(red: 0.62, green: 0.36, blue: 0.23),
            skyOpacity: 0.28,
            horizonColor: Color(red: 0.88, green: 0.57, blue: 0.3),
            horizonOpacity: 0.24,
            lightColor: Color(red: 0.92, green: 0.6, blue: 0.33),
            lightOpacity: 0.18,
            lightCenter: UnitPoint(x: 0.83, y: 0.33),
            lightRadiusScale: 0.5,
            dustOpacity: 0.11,
            poleFillTop: Color(red: 0.31, green: 0.23, blue: 0.17),
            poleFillBottom: Color(red: 0.17, green: 0.12, blue: 0.09),
            poleHighlightOpacity: 0.05,
            poleShadowOpacity: 0.18,
            shadowAngleDeg: 48,
            shadowLengthScale: 0.4,
            shadowWidth: 28,
            shadowOpacity: 0.2,
            shadowBlur: 15
        )
    case .isha:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.08, green: 0.09, blue: 0.14),
            skyBottom: Color(red: 0.15, green: 0.13, blue: 0.12),
            skyOpacity: 0.34,
            horizonColor: Color(red: 0.36, green: 0.31, blue: 0.26),
            horizonOpacity: 0.12,
            lightColor: Color(red: 0.56, green: 0.59, blue: 0.68),
            lightOpacity: 0.08,
            lightCenter: UnitPoint(x: 0.76, y: 0.18),
            lightRadiusScale: 0.4,
            dustOpacity: 0.04,
            poleFillTop: Color(red: 0.21, green: 0.17, blue: 0.14),
            poleFillBottom: Color(red: 0.12, green: 0.1, blue: 0.08),
            poleHighlightOpacity: 0.03,
            poleShadowOpacity: 0.1,
            shadowAngleDeg: 90,
            shadowLengthScale: 0.04,
            shadowWidth: 14,
            shadowOpacity: 0.06,
            shadowBlur: 10
        )
    case .lastThird:
        return PhoneObserveSceneStyle(
            skyTop: Color(red: 0.06, green: 0.08, blue: 0.12),
            skyBottom: Color(red: 0.12, green: 0.11, blue: 0.11),
            skyOpacity: 0.36,
            horizonColor: Color(red: 0.24, green: 0.24, blue: 0.23),
            horizonOpacity: 0.08,
            lightColor: Color(red: 0.56, green: 0.62, blue: 0.74),
            lightOpacity: 0.1,
            lightCenter: UnitPoint(x: 0.72, y: 0.16),
            lightRadiusScale: 0.36,
            dustOpacity: 0.03,
            poleFillTop: Color(red: 0.2, green: 0.17, blue: 0.14),
            poleFillBottom: Color(red: 0.11, green: 0.09, blue: 0.08),
            poleHighlightOpacity: 0.03,
            poleShadowOpacity: 0.08,
            shadowAngleDeg: 90,
            shadowLengthScale: 0.03,
            shadowWidth: 14,
            shadowOpacity: 0.05,
            shadowBlur: 10
        )
    }
}

private struct PhoneObserveSceneOverlay: View {
    let key: PhonePhaseBackgroundKey
    let containerSize: CGSize

    private var style: PhoneObserveSceneStyle {
        phoneObserveSceneStyle(for: key)
    }

    var body: some View {
        let width = containerSize.width
        let height = containerSize.height

        ZStack {
            LinearGradient(
                colors: [
                    style.skyTop.opacity(style.skyOpacity),
                    Color.clear,
                    style.skyBottom.opacity(style.skyOpacity * 0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    style.lightColor.opacity(style.lightOpacity),
                    Color.clear
                ],
                center: style.lightCenter,
                startRadius: 0,
                endRadius: max(width, height) * style.lightRadiusScale
            )
            .blendMode(.screen)

            Ellipse()
                .fill(style.horizonColor.opacity(style.horizonOpacity))
                .frame(width: width * 0.92, height: height * 0.17)
                .blur(radius: 22)
                .offset(y: height * 0.01)
                .blendMode(.screen)

            LinearGradient(
                colors: [
                    Color.clear,
                    PHONE_DUST_TINT.opacity(style.dustOpacity),
                    PHONE_DUST_TINT.opacity(style.dustOpacity * 0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.4)
            .offset(y: height * 0.08)
            .blendMode(.multiply)
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

private struct PhonePanelBackground: View {
    let cornerRadius: CGFloat
    let tone: PhoneSurfaceTone

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        tone.fillTop,
                        tone.fillBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                PHONE_PANEL_HIGHLIGHT,
                                Color(red: 0.22, green: 0.17, blue: 0.13).opacity(0.05),
                                Color.black.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.14, blue: 0.11).opacity(0.08),
                                Color.clear,
                                Color(red: 0.04, green: 0.03, blue: 0.024).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.multiply)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        PHONE_PANEL_STROKE.opacity(tone.edgeOpacity / 0.045),
                        lineWidth: 0.7
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                PHONE_PANEL_HIGHLIGHT,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.45
                    )
                    .padding(0.75)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.34, green: 0.27, blue: 0.21).opacity(0.03),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 260
                        )
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.03, green: 0.025, blue: 0.02).opacity(0.16))
                    .blur(radius: 24)
                    .offset(y: 3)
            )
            .shadow(color: PHONE_PANEL_SHADOW, radius: 24, x: 0, y: 4)
    }
}

private struct PhonePanel<Content: View>: View {
    let cornerRadius: CGFloat
    let tone: PhoneSurfaceTone
    private let content: Content

    init(
        cornerRadius: CGFloat = PHONE_PANEL_RADIUS,
        tone: PhoneSurfaceTone = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, PHONE_PANEL_HORIZONTAL_PADDING)
            .padding(.vertical, PHONE_PANEL_VERTICAL_PADDING)
            .background(PhonePanelBackground(cornerRadius: cornerRadius, tone: tone))
    }
}

private struct PhoneLoadingStillView: View {
    let key: PhonePhaseBackgroundKey
    @State private var driftsIn = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(key.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(driftsIn ? PHONE_LOADING_STILL_ZOOM_MAX : PHONE_LOADING_STILL_ZOOM_MIN)
                    .saturation(0.78)
                    .brightness(-0.06)
                    .contrast(0.97)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.14),
                        Color.clear,
                        Color.black.opacity(0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                PHONE_DUST_TINT
                    .opacity(0.08)
                    .blendMode(.multiply)
                    .ignoresSafeArea()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: PHONE_LOADING_STILL_ZOOM_DURATION).repeatForever(autoreverses: true)) {
                driftsIn = true
            }
        }
    }
}

private struct PhoneLegendSectorSpec: Identifiable {
    let id: String
    let title: String?
    let readingTitle: String
    let startAngleDeg: Double
    let endAngleDeg: Double
    let centerAngleDeg: Double
    let isActive: Bool
    let isUnlabeled: Bool
}

private let PHONE_LEGEND_ARC_SCALE = 0.925
private let PHONE_LEGEND_DUHA_CLUSTER_GAP_FACTOR = 0.24

private enum PhoneLegendArcId: String {
    case maghrib
    case isha
    case lastThird
    case fajr
    case sunrise
    case duha
    case midday
    case dhuhr
    case asr
}

private struct PhoneLegendArcSpec {
    let id: PhoneLegendArcId
    let originalStartAngleDeg: Double
    let originalEndAngleDeg: Double
    let startAngleDeg: Double
    let endAngleDeg: Double

    var centerAngleDeg: Double {
        startAngleDeg + phoneLegendAngleSpan(startDeg: startAngleDeg, endDeg: endAngleDeg) / 2
    }
}

private func phoneLegendAngleSpan(startDeg: Double, endDeg: Double) -> Double {
    let raw = endDeg - startDeg
    return raw >= 0 ? raw : raw + 360
}

private func phoneLegendAdjustedArcBounds(
    startDeg: Double,
    endDeg: Double,
    scale: Double
) -> (start: Double, end: Double) {
    let span = phoneLegendAngleSpan(startDeg: startDeg, endDeg: endDeg)
    let midpoint = startDeg + span / 2
    let adjustedSpan = span * scale
    return (
        start: midpoint - adjustedSpan / 2,
        end: midpoint + adjustedSpan / 2
    )
}

private func phoneLegendMakeArcSpec(
    id: PhoneLegendArcId,
    start: Double,
    end: Double
) -> PhoneLegendArcSpec {
    let adjusted = phoneLegendAdjustedArcBounds(
        startDeg: start,
        endDeg: end,
        scale: PHONE_LEGEND_ARC_SCALE
    )
    return PhoneLegendArcSpec(
        id: id,
        originalStartAngleDeg: start,
        originalEndAngleDeg: end,
        startAngleDeg: adjusted.start,
        endAngleDeg: adjusted.end
    )
}

private func tightenedPhoneLegendDuhaCluster(specs: [PhoneLegendArcSpec]) -> [PhoneLegendArcSpec] {
    var adjusted = specs
    let indices = Dictionary(uniqueKeysWithValues: adjusted.enumerated().map { ($0.element.id, $0.offset) })

    func tightenGap(left: PhoneLegendArcId, right: PhoneLegendArcId) {
        guard
            let leftIndex = indices[left],
            let rightIndex = indices[right]
        else { return }

        let currentGap = phoneLegendAngleSpan(
            startDeg: adjusted[leftIndex].endAngleDeg,
            endDeg: adjusted[rightIndex].startAngleDeg
        )
        guard currentGap > 0.01, currentGap < 40 else { return }

        let desiredGap = currentGap * PHONE_LEGEND_DUHA_CLUSTER_GAP_FACTOR
        let delta = (currentGap - desiredGap) / 2

        adjusted[leftIndex] = PhoneLegendArcSpec(
            id: adjusted[leftIndex].id,
            originalStartAngleDeg: adjusted[leftIndex].originalStartAngleDeg,
            originalEndAngleDeg: adjusted[leftIndex].originalEndAngleDeg,
            startAngleDeg: adjusted[leftIndex].startAngleDeg,
            endAngleDeg: adjusted[leftIndex].endAngleDeg + delta
        )

        adjusted[rightIndex] = PhoneLegendArcSpec(
            id: adjusted[rightIndex].id,
            originalStartAngleDeg: adjusted[rightIndex].originalStartAngleDeg,
            originalEndAngleDeg: adjusted[rightIndex].originalEndAngleDeg,
            startAngleDeg: adjusted[rightIndex].startAngleDeg - delta,
            endAngleDeg: adjusted[rightIndex].endAngleDeg
        )
    }

    tightenGap(left: .sunrise, right: .duha)
    tightenGap(left: .duha, right: .midday)

    return adjusted
}

private func buildPhoneLegendArcSpecs(snapshot: ComputedIslamicDay) -> [PhoneLegendArcSpec] {
    let timeline = snapshot.timeline
    let phoneArcSpecs = buildPhoneRingArcSpecs(
        snapshot: snapshot,
        baseRadius: 100,
        ringRadius: 100
    )

    func rawAngle(for timestamp: Date) -> Double {
        timestampToAngle(
            timestamp: timestamp,
            lastMaghrib: timeline.lastMaghrib,
            nextMaghrib: timeline.nextMaghrib
        )
    }

    func mappedAngle(_ rawAngle: Double) -> Double {
        adjustedPhoneMarkerAngle(phoneArcSpecs: phoneArcSpecs, originalAngle: rawAngle)
    }

    func mappedSpec(id: PhoneLegendArcId, start: Double, end: Double) -> PhoneLegendArcSpec {
        PhoneLegendArcSpec(
            id: id,
            originalStartAngleDeg: start,
            originalEndAngleDeg: end,
            startAngleDeg: mappedAngle(start),
            endAngleDeg: mappedAngle(end)
        )
    }

    return [
        mappedSpec(id: .maghrib, start: rawAngle(for: timeline.lastMaghrib), end: rawAngle(for: timeline.isha)),
        mappedSpec(id: .isha, start: rawAngle(for: timeline.isha), end: rawAngle(for: timeline.lastThirdStart)),
        mappedSpec(id: .lastThird, start: rawAngle(for: timeline.lastThirdStart), end: rawAngle(for: timeline.fajr)),
        mappedSpec(id: .fajr, start: rawAngle(for: timeline.fajr), end: rawAngle(for: timeline.sunrise)),
        mappedSpec(id: .sunrise, start: rawAngle(for: timeline.sunrise), end: rawAngle(for: timeline.duhaStart)),
        mappedSpec(id: .duha, start: rawAngle(for: timeline.duhaStart), end: rawAngle(for: timeline.duhaEnd)),
        mappedSpec(id: .midday, start: rawAngle(for: timeline.duhaEnd), end: rawAngle(for: timeline.dhuhr)),
        mappedSpec(id: .dhuhr, start: rawAngle(for: timeline.dhuhr), end: rawAngle(for: timeline.asr)),
        mappedSpec(id: .asr, start: rawAngle(for: timeline.asr), end: rawAngle(for: timeline.nextMaghrib)),
    ]
}

private func phoneLegendSectorSpecs(
    snapshot: ComputedIslamicDay,
    now: Date,
    presentation: PhoneHomePresentation
) -> [PhoneLegendSectorSpec] {
    let isFridayJumuah = Calendar.current.component(.weekday, from: now) == 6 && !presentation.isEidDay
    let arcSpecsById = Dictionary(
        uniqueKeysWithValues: buildPhoneLegendArcSpecs(snapshot: snapshot).map { ($0.id, $0) }
    )

    let rawSpecs: [(PhoneLegendArcId, String?, String)] = [
        (.maghrib, "Maghrib", "Maghrib"),
        (.isha, "Isha", "Isha"),
        (.lastThird, "Last 3rd", "Last 3rd"),
        (.fajr, "Fajr", "Fajr"),
        (.sunrise, nil, "Sunrise"),
        (.duha, "Duha", "Duha"),
        (.midday, nil, "Midday"),
        (.dhuhr, isFridayJumuah ? "Jumu'ah" : "Dhuhr", isFridayJumuah ? "Jumu'ah" : "Dhuhr"),
        (.asr, "Asr", "Asr"),
    ]

    return rawSpecs.compactMap { id, title, readingTitle in
        guard let arc = arcSpecsById[id] else { return nil }
        let isActive = title != nil
            ? presentation.highlightedRingTitle == title
            : presentation.rawSectorTitle == readingTitle

        return PhoneLegendSectorSpec(
            id: id.rawValue,
            title: title,
            readingTitle: readingTitle,
            startAngleDeg: arc.startAngleDeg,
            endAngleDeg: arc.endAngleDeg,
            centerAngleDeg: arc.centerAngleDeg,
            isActive: isActive,
            isUnlabeled: title == nil
        )
    }
}

private func phoneLegendDisplaySpecs(
    from sectorSpecs: [PhoneLegendSectorSpec]
) -> [PhoneLegendSectorSpec] {
    let desiredOrder = [
        PhoneLegendArcId.maghrib,
        .isha,
        .lastThird,
        .fajr,
        .duha,
        .dhuhr,
        .asr
    ]
    let specsById = Dictionary(uniqueKeysWithValues: sectorSpecs.map { ($0.id, $0) })
    let step = 360.0 / Double(desiredOrder.count)
    let slotSpan = step * 0.68
    let topCenterAngle = 0.0

    return desiredOrder.enumerated().compactMap { index, arcId in
        guard let spec = specsById[arcId.rawValue] else { return nil }
        let center = normalizedDialAngle(topCenterAngle + Double(index) * step)

        return PhoneLegendSectorSpec(
            id: spec.id,
            title: spec.title,
            readingTitle: spec.readingTitle,
            startAngleDeg: center - slotSpan / 2,
            endAngleDeg: center + slotSpan / 2,
            centerAngleDeg: center,
            isActive: spec.isActive,
            isUnlabeled: spec.isUnlabeled
        )
    }
}

private struct PhoneArcBaselineLabel: View {
    let text: String
    let radius: CGFloat
    let centerAngleDeg: Double
    let fontSize: CGFloat
    let color: Color
    let isActive: Bool
    let tracking: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let normalizedCenterAngle = normalizedDialAngle(centerAngleDeg)
            let isLowerHalf = normalizedCenterAngle > 90 && normalizedCenterAngle < 270
            let direction: CGFloat = isLowerHalf ? -1 : 1
            let uiFont = UIFont.systemFont(
                ofSize: fontSize,
                weight: isActive ? .semibold : .regular
            )
            let ctFont = CTFontCreateWithFontDescriptor(
                uiFont.fontDescriptor,
                uiFont.pointSize,
                nil
            )
            let attributed = NSAttributedString(
                string: text.uppercased(),
                attributes: [
                    .font: uiFont,
                    .kern: tracking
                ]
            )
            let line = CTLineCreateWithAttributedString(attributed)
            let lineWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            let runs = CTLineGetGlyphRuns(line) as NSArray as? [CTRun] ?? []

            context.withCGContext { cg in
                cg.saveGState()
                cg.setShouldAntialias(true)
                cg.setAllowsAntialiasing(true)
                cg.setFillColor(UIColor(color).cgColor)
                if isActive {
                    cg.setShadow(
                        offset: .zero,
                        blur: fontSize * 0.75,
                        color: UIColor(PHONE_ANTIQUE_GOLD.opacity(0.34)).cgColor
                    )
                }

                for run in runs {
                    let glyphCount = CTRunGetGlyphCount(run)
                    guard glyphCount > 0 else { continue }

                    var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
                    var positions = [CGPoint](repeating: .zero, count: glyphCount)
                    var advances = [CGSize](repeating: .zero, count: glyphCount)
                    CTRunGetGlyphs(run, CFRangeMake(0, 0), &glyphs)
                    CTRunGetPositions(run, CFRangeMake(0, 0), &positions)
                    CTRunGetAdvances(run, CFRangeMake(0, 0), &advances)

                    for index in 0..<glyphCount {
                        guard let glyphPath = CTFontCreatePathForGlyph(ctFont, glyphs[index], nil) else { continue }

                        let glyphCenterX = (-lineWidth / 2) + positions[index].x + advances[index].width / 2
                        let angleDeg = centerAngleDeg + Double(direction * (glyphCenterX / max(radius, 1)) * 180 / .pi)
                        let baselinePoint = polarToXY(
                            cx: Double(canvasSize.width / 2),
                            cy: Double(canvasSize.height / 2),
                            r: Double(radius),
                            angleDeg: angleDeg
                        )
                        let rotationDeg = angleDeg + (isLowerHalf ? 180 : 0)
                        let glyphOriginShift = -advances[index].width / 2

                        cg.saveGState()
                        cg.translateBy(x: baselinePoint.x, y: baselinePoint.y)
                        cg.rotate(by: CGFloat(rotationDeg) * .pi / 180)
                        cg.translateBy(x: glyphOriginShift, y: 0)
                        cg.scaleBy(x: 1, y: -1)
                        cg.addPath(glyphPath)
                        cg.fillPath()
                        cg.restoreGState()
                    }
                }

                cg.restoreGState()
            }
        }
        .allowsHitTesting(false)
    }
}

private func phoneLegendTextWidth(
    text: String,
    fontSize: CGFloat,
    tracking: CGFloat
) -> CGFloat {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
        .kern: tracking
    ]
    return max(
        0.001,
        (text.uppercased() as NSString).size(withAttributes: attrs).width
    )
}

private func phoneLegendNaturalArcSpanDeg(
    text: String,
    fontSize: CGFloat,
    radius: CGFloat,
    tracking: CGFloat
) -> Double {
    let totalAdvance = phoneLegendTextWidth(
        text: text,
        fontSize: fontSize,
        tracking: tracking
    )
    let anglePerPoint = 180 / (.pi * max(Double(radius), 1))
    return Double(totalAdvance) * anglePerPoint
}

private func phoneLegendFontFitScale(
    specs: [PhoneLegendSectorSpec],
    baseFontSize: CGFloat,
    radius: CGFloat,
    tracking: CGFloat
) -> CGFloat {
    let visibleSpecs = specs.filter { $0.title != nil }
    guard !visibleSpecs.isEmpty else { return 1 }

    let minRatio = visibleSpecs.reduce(1.0) { currentMin, spec in
        let naturalSpan = phoneLegendNaturalArcSpanDeg(
            text: spec.title ?? "",
            fontSize: baseFontSize,
            radius: radius,
            tracking: tracking
        )
        let allowedSpan = max(8.0, phoneLegendAngleSpan(startDeg: spec.startAngleDeg, endDeg: spec.endAngleDeg) - 6.0)
        return min(currentMin, allowedSpan / max(naturalSpan, 0.001))
    }

    return max(0.8, min(1.0, CGFloat(minRatio)))
}

private struct PhoneLegendTapShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngleDeg: Double
    let endAngleDeg: Double

    func path(in rect: CGRect) -> Path {
        let startOuter = polarToXY(
            cx: Double(rect.midX),
            cy: Double(rect.midY),
            r: Double(outerRadius),
            angleDeg: startAngleDeg
        )
        let endInner = polarToXY(
            cx: Double(rect.midX),
            cy: Double(rect.midY),
            r: Double(innerRadius),
            angleDeg: endAngleDeg
        )

        var path = Path()
        path.move(to: startOuter)
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: outerRadius,
            startAngle: .degrees(startAngleDeg - 90),
            endAngle: .degrees(endAngleDeg - 90),
            clockwise: false
        )
        path.addLine(to: endInner)
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: innerRadius,
            startAngle: .degrees(endAngleDeg - 90),
            endAngle: .degrees(startAngleDeg - 90),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

private struct PhoneDialView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let interactionsEnabled: Bool
    let presentation: PhoneHomePresentation
    let onDateTap: () -> Void
    let onCurrentSectorTap: () -> Void
    let onLegendTap: (String) -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let dialSize = min(w, h) * 1.02
            let dialCenter = CGPoint(x: w / 2, y: h / 2)
            let sectorSpecs = phoneLegendSectorSpecs(
                snapshot: snapshot,
                now: now,
                presentation: presentation
            )
            let legendSpecs = phoneLegendDisplaySpecs(from: sectorSpecs)
            let baseLabelFontSize = min(dialSize * 0.038, 14.5)
            let labelTracking = baseLabelFontSize * 0.14
            let visibleLegendSpecs = legendSpecs.filter { $0.title != nil }
            let labelRadius = dialSize * 0.382
            let labelFontSize = baseLabelFontSize * phoneLegendFontFitScale(
                specs: legendSpecs,
                baseFontSize: baseLabelFontSize,
                radius: labelRadius,
                tracking: labelTracking
            )
            let baselineLineWidth = max(0.72, dialSize * 0.0018)
            let centerInfoWidth = min(dialSize * 0.5, 208)
            let currentTitleFontSize = min(dialSize * 0.055, 21.5)
            let currentTitleTracking = currentTitleFontSize * 0.1

            ZStack {
                ZStack {
                    Circle()
                        .stroke(PHONE_SOFT_WHITE.opacity(0.28), lineWidth: baselineLineWidth)
                        .frame(width: labelRadius * 2, height: labelRadius * 2)

                    ForEach(visibleLegendSpecs) { spec in
                    let labelText = spec.title ?? ""
                    Button {
                        onLegendTap(spec.readingTitle)
                    } label: {
                        PhoneArcBaselineLabel(
                            text: labelText,
                            radius: labelRadius,
                            centerAngleDeg: spec.centerAngleDeg,
                            fontSize: spec.isActive ? labelFontSize * 1.04 : labelFontSize,
                            color: spec.isActive ? PHONE_SECTOR_LABEL_COLOR : PHONE_SECTOR_LABEL_COLOR.opacity(0.66),
                            isActive: spec.isActive,
                            tracking: labelTracking
                        )
                            .frame(width: dialSize, height: dialSize)
                            .contentShape(
                                PhoneLegendTapShape(
                                    innerRadius: labelRadius - labelFontSize * 1.9,
                                    outerRadius: labelRadius + labelFontSize * 1.9,
                                    startAngleDeg: spec.startAngleDeg - 2.6,
                                    endAngleDeg: spec.endAngleDeg + 2.6
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .allowsHitTesting(interactionsEnabled)
                    }

                    Button {
                        onCurrentSectorTap()
                    } label: {
                        Text(presentation.displayTitle.uppercased())
                            .font(phoneDisplayFont(size: currentTitleFontSize, weight: .semibold))
                            .foregroundColor(Colors.coolLabel)
                            .tracking(currentTitleTracking)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .frame(width: centerInfoWidth)
                            .shadow(color: Color.black.opacity(0.16), radius: 1.2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(interactionsEnabled)
                    .offset(y: dialSize * (-0.115))

                    PhoneCenteredHijriDateLabels(
                        hijriDate: snapshot.hijriDate,
                        frameWidth: centerInfoWidth,
                        isInteractive: interactionsEnabled,
                        onTap: onDateTap
                    )
                }
                .frame(width: dialSize, height: dialSize)
                .position(dialCenter)
            }
            .frame(width: w, height: h)
        }
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

private struct PhoneHijriDimensionalGoldModifier: ViewModifier {
    let isEid: Bool
    let secondary: Bool

    func body(content: Content) -> some View {
        if isEid {
            content
                .foregroundStyle(Color(red: 0.06, green: 0.73, blue: 0.51))
                .modifier(HijriEngravedLabelsModifier(isEid: true))
        } else {
            let top = secondary
                ? Color(red: 0.9, green: 0.8, blue: 0.55)
                : Color(red: 0.95, green: 0.84, blue: 0.58)
            let mid = secondary
                ? Color(red: 0.77, green: 0.61, blue: 0.24)
                : Color(red: 0.83, green: 0.66, blue: 0.24)
            let bottom = secondary
                ? Color(red: 0.49, green: 0.36, blue: 0.12)
                : Color(red: 0.57, green: 0.41, blue: 0.1)
            let topLight = Color.white.opacity(0.12)
            let warmLift = Color(red: 1, green: 0.95, blue: 0.78).opacity(0.06)
            let innerGlow = (secondary ? Colors.secondaryGold : Colors.primaryGold).opacity(0.07)
            let shade = Color.black.opacity(0.42)

            content
                .foregroundStyle(
                    LinearGradient(
                        colors: [top, mid, bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: topLight, radius: 0, x: 0, y: -0.7)
                .shadow(color: warmLift, radius: 1.0, x: 0, y: -0.2)
                .shadow(color: innerGlow, radius: 2.8)
                .shadow(color: shade, radius: 0, x: 0, y: 1.0)
                .shadow(color: shade.opacity(0.5), radius: 1.6, x: 0, y: 1.4)
        }
    }
}

private struct HijriDateLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)
    private let showYear: Bool
    private let useCompactDayMonth: Bool
    private let infoProgress: Double
    private let isInteractive: Bool
    private let onTap: (() -> Void)?

    init(
        hijriDate: HijriDate,
        showYear: Bool = true,
        infoProgress: Double = 0,
        isInteractive: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.parts = formatHijriDateParts(hijriDate)
        self.showYear = showYear
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
                    .modifier(PhoneHijriDimensionalGoldModifier(isEid: parts.isEid, secondary: false))
                if showYear {
                    Text(parts.year)
                        .font(.system(size: 14, weight: .semibold))
                        .modifier(PhoneHijriDimensionalGoldModifier(isEid: parts.isEid, secondary: true))
                }
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

private struct PhoneCenteredHijriDateLabels: View {
    private let parts: (dayMonth: String, year: String, isEid: Bool)
    private let useCompactDayMonth: Bool
    private let frameWidth: CGFloat
    private let isInteractive: Bool
    private let onTap: (() -> Void)?

    init(
        hijriDate: HijriDate,
        frameWidth: CGFloat = 220,
        isInteractive: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.parts = formatHijriDateParts(hijriDate)
        self.useCompactDayMonth = COMPACT_MONTH_NAMES.contains(hijriDate.monthNameEn.lowercased())
        self.frameWidth = frameWidth
        self.isInteractive = isInteractive
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            Text(parts.dayMonth.uppercased())
                .font(.system(size: useCompactDayMonth ? 15 : 17.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .modifier(PhoneCenterHijriLabelModifier(isEid: parts.isEid, secondary: false))
                .offset(y: -7)

            Text(parts.year)
                .font(.system(size: 14.5, weight: .semibold))
                .modifier(PhoneCenterHijriLabelModifier(isEid: parts.isEid, secondary: true))
                .offset(y: 15)
        }
        .frame(width: frameWidth, height: 60)
        .contentShape(Rectangle())
        .allowsHitTesting(isInteractive)
        .onTapGesture {
            onTap?()
        }
    }
}

private struct PhoneBoundaryEvent {
    let title: String
    let cueText: String
    let at: Date
}

private struct PhoneBoundaryWindow {
    let start: PhoneBoundaryEvent
    let end: PhoneBoundaryEvent
}

private func phoneBoundaryEvent(title: String, at: Date) -> PhoneBoundaryEvent {
    PhoneBoundaryEvent(
        title: title,
        cueText: phoneObservationalCueText(for: title),
        at: at
    )
}

private func phoneBoundaryEvent(title: String, cueText: String, at: Date) -> PhoneBoundaryEvent {
    PhoneBoundaryEvent(
        title: title,
        cueText: cueText,
        at: at
    )
}

private func phoneRegularBoundaryWindow(snapshot: ComputedIslamicDay, now: Date) -> PhoneBoundaryWindow {
    let timeline = snapshot.timeline

    switch snapshot.currentPhase {
    case .maghrib_to_isha:
        return PhoneBoundaryWindow(
            start: phoneBoundaryEvent(title: "Maghrib", at: timeline.lastMaghrib),
            end: phoneBoundaryEvent(title: "Isha", at: timeline.isha)
        )
    case .isha_to_last_third:
        return PhoneBoundaryWindow(
            start: phoneBoundaryEvent(title: "Isha", at: timeline.isha),
            end: phoneBoundaryEvent(title: "Fajr", cueText: PHONE_CUE_FAJR, at: timeline.fajr)
        )
    case .last_third_to_fajr:
        return PhoneBoundaryWindow(
            start: phoneBoundaryEvent(title: "Last 3rd", cueText: PHONE_SUMMARY_LAST_THIRD_START, at: timeline.lastThirdStart),
            end: phoneBoundaryEvent(title: "Fajr", cueText: PHONE_SUMMARY_LAST_THIRD_END, at: timeline.fajr)
        )
    case .fajr_to_sunrise:
        return PhoneBoundaryWindow(
            start: phoneBoundaryEvent(title: "Fajr", at: timeline.fajr),
            end: phoneBoundaryEvent(title: "Sunrise", at: timeline.sunrise)
        )
    case .sunrise_to_dhuhr:
        switch getSunriseToDhuhrSubPeriod(
            now: now,
            duhaStart: timeline.duhaStart,
            dhuhr: timeline.dhuhr
        ) {
        case .sunrise:
            return PhoneBoundaryWindow(
                start: phoneBoundaryEvent(title: "Sunrise", at: timeline.sunrise),
                end: phoneBoundaryEvent(title: "Duha", at: timeline.duhaStart)
            )
        case .duha:
            return PhoneBoundaryWindow(
                start: phoneBoundaryEvent(title: "Duha", at: timeline.duhaStart),
                end: phoneBoundaryEvent(title: "Midday", at: timeline.duhaEnd)
            )
        case .midday:
            return PhoneBoundaryWindow(
                start: phoneBoundaryEvent(title: "Midday", at: timeline.duhaEnd),
                end: phoneBoundaryEvent(title: "Dhuhr", at: timeline.dhuhr)
            )
        }
    case .dhuhr_to_asr:
        return PhoneBoundaryWindow(
            start: phoneBoundaryEvent(title: "Dhuhr", at: timeline.dhuhr),
            end: phoneBoundaryEvent(title: "Asr", at: timeline.asr)
        )
    case .asr_to_maghrib:
        return PhoneBoundaryWindow(
            start: phoneBoundaryEvent(title: "Asr", at: timeline.asr),
            end: phoneBoundaryEvent(title: "Maghrib", at: timeline.nextMaghrib)
        )
    }
}

private func phoneBoundaryWindow(snapshot: ComputedIslamicDay, now: Date) -> PhoneBoundaryWindow {
    let timeline = snapshot.timeline
    let hijriParts = formatHijriDateParts(snapshot.hijriDate)

    if hijriParts.isEid {
        switch snapshot.currentPhase {
        case .sunrise_to_dhuhr:
            if getSunriseToDhuhrSubPeriod(
                now: now,
                duhaStart: timeline.duhaStart,
                dhuhr: timeline.dhuhr
            ) == .sunrise {
                return PhoneBoundaryWindow(
                    start: phoneBoundaryEvent(title: "Sunrise", at: timeline.sunrise),
                    end: phoneBoundaryEvent(title: hijriParts.dayMonth, at: timeline.duhaStart)
                )
            }
            return PhoneBoundaryWindow(
                start: phoneBoundaryEvent(title: hijriParts.dayMonth, at: timeline.duhaStart),
                end: phoneBoundaryEvent(title: "Asr", at: timeline.asr)
            )
        case .dhuhr_to_asr:
            return PhoneBoundaryWindow(
                start: phoneBoundaryEvent(title: hijriParts.dayMonth, at: timeline.duhaStart),
                end: phoneBoundaryEvent(title: "Asr", at: timeline.asr)
            )
        default:
            return phoneRegularBoundaryWindow(snapshot: snapshot, now: now)
        }
    }

    if Calendar.current.component(.weekday, from: now) == 6 {
        switch snapshot.currentPhase {
        case .sunrise_to_dhuhr:
            if getSunriseToDhuhrSubPeriod(
                now: now,
                duhaStart: timeline.duhaStart,
                dhuhr: timeline.dhuhr
            ) == .sunrise {
                return PhoneBoundaryWindow(
                    start: phoneBoundaryEvent(title: "Sunrise", at: timeline.sunrise),
                    end: phoneBoundaryEvent(title: "Jumu'ah", at: timeline.duhaStart)
                )
            }
            return PhoneBoundaryWindow(
                start: phoneBoundaryEvent(title: "Jumu'ah", at: timeline.duhaStart),
                end: phoneBoundaryEvent(title: "Asr", at: timeline.asr)
            )
        case .dhuhr_to_asr:
            return PhoneBoundaryWindow(
                start: phoneBoundaryEvent(title: "Jumu'ah", at: timeline.duhaStart),
                end: phoneBoundaryEvent(title: "Asr", at: timeline.asr)
            )
        default:
            return phoneRegularBoundaryWindow(snapshot: snapshot, now: now)
        }
    }

    return phoneRegularBoundaryWindow(snapshot: snapshot, now: now)
}

private func phoneSummaryDateLine(hijriDate: HijriDate) -> String {
    let parts = formatHijriDateParts(hijriDate)
    return "\(parts.dayMonth.uppercased()) \(parts.year)"
}

private struct PhoneSummaryCardContent: Identifiable {
    let id: String
    let text: String
}

private let PHONE_EID_TAQABBAL_BETWEEN =
    "Taqabbal Allahu minna wa minkum!\nMay Allah accept from us and from you!"

private func phoneSummaryShowsEidTaqabbalInBetween(
    snapshot: ComputedIslamicDay,
    now: Date,
    isEidDay: Bool
) -> Bool {
    guard isEidDay else { return false }
    switch snapshot.currentPhase {
    case .sunrise_to_dhuhr:
        let sub = getSunriseToDhuhrSubPeriod(
            now: now,
            duhaStart: snapshot.timeline.duhaStart,
            dhuhr: snapshot.timeline.dhuhr
        )
        return sub == .duha || sub == .midday
    case .dhuhr_to_asr:
        return true
    default:
        return false
    }
}

private func phoneBaseSummaryCardContents(for rawSectorTitle: String) -> [PhoneSummaryCardContent] {
    switch rawSectorTitle {
    case "Fajr":
        return [
            PhoneSummaryCardContent(
                id: "fajr",
                text: "Between true dawn and sunrise."
            )
        ]
    case "Sunrise":
        return [
            PhoneSummaryCardContent(
                id: "sunrise",
                text: "Between sunrise and when the morning light has clearly spread."
            )
        ]
    case "Duha":
        return [
            PhoneSummaryCardContent(
                id: "duha",
                text: "Between when the morning light has clearly spread and when the shadow is shortest."
            )
        ]
    case "Midday":
        return [
            PhoneSummaryCardContent(
                id: "midday",
                text: "Between when the shadow is shortest and when it begins to lengthen again."
            )
        ]
    case "Dhuhr":
        return [
            PhoneSummaryCardContent(
                id: "dhuhr",
                text: "Between when the shadow begins to lengthen again and when the shadow equals the object's height plus the noon shadow."
            )
        ]
    case "Asr":
        return [
            PhoneSummaryCardContent(
                id: "asr",
                text: "Between when the shadow equals the object's height plus the noon shadow and sunset, when the sun disappears below the horizon."
            )
        ]
    case "Maghrib":
        return [
            PhoneSummaryCardContent(
                id: "maghrib",
                text: "Between sunset, when the sun disappears below the horizon, and when the evening twilight disappears."
            )
        ]
    case "Isha":
        return [
            PhoneSummaryCardContent(
                id: "isha",
                text: "Between when the evening twilight disappears and when true dawn begins."
            )
        ]
    case "Last 3rd":
        return [
            PhoneSummaryCardContent(
                id: "last_third",
                text: "Between the start of the last third of the night, measured from Maghrib to true dawn, and true dawn."
            )
        ]
    case "Jumu'ah":
        return [
            PhoneSummaryCardContent(
                id: "jumuah",
                text: "Prepare for Jumu'ah: take a bath, use perfume, dress well, and remain silent during the khutbah."
            )
        ]
    case "EID AL-FITR", "EID AL-ADHA":
        return []
    default:
        return []
    }
}

private func phoneSummaryCardContents(
    presentation: PhoneHomePresentation,
    snapshot: ComputedIslamicDay,
    now: Date
) -> [PhoneSummaryCardContent] {
    let taqabbalWindow = phoneSummaryShowsEidTaqabbalInBetween(
        snapshot: snapshot,
        now: now,
        isEidDay: presentation.isEidDay
    )
    var cards: [PhoneSummaryCardContent]
    if presentation.isEidDay,
       presentation.rawSectorTitle == "Jumu'ah",
       taqabbalWindow {
        cards = []
    } else {
        cards = phoneBaseSummaryCardContents(for: presentation.rawSectorTitle)
    }
    if taqabbalWindow {
        cards.append(
            PhoneSummaryCardContent(id: "eid_taqabbal_between", text: PHONE_EID_TAQABBAL_BETWEEN)
        )
    }
    return cards
}

private struct PhoneBoundaryCard: View {
    let text: String
    let containerSize: CGSize

    private var bodyFont: Font {
        phoneTextFont(size: min(18, containerSize.width * 0.048), weight: .regular)
    }

    var body: some View {
        Text(text)
            .font(bodyFont)
            .foregroundColor(PHONE_SOFT_WHITE.opacity(0.84))
            .lineSpacing(min(containerSize.width * 0.019, 7))
            .multilineTextAlignment(.center)
            .phoneDebossedBody()
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct PhoneHomeSummaryView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let presentation: PhoneHomePresentation
    let containerSize: CGSize
    let isInteractive: Bool
    let onDateTap: () -> Void
    let onCurrentSectorTap: () -> Void

    private var summaryCardContents: [PhoneSummaryCardContent] {
        phoneSummaryCardContents(presentation: presentation, snapshot: snapshot, now: now)
    }

    private var sectorFont: Font {
        phonePhaseTitleFont(containerSize: containerSize)
    }

    private var headerFont: Font {
        phoneDisplayFont(size: min(containerSize.width * 0.054, 20), weight: .regular)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Button(action: onCurrentSectorTap) {
                    Text(presentation.displayTitle.uppercased())
                        .font(sectorFont)
                        .foregroundColor(PHONE_SCREEN_TITLE.opacity(0.92))
                        .tracking(min(containerSize.width * 0.007, 2.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .phoneDebossedTitle()
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isInteractive)

                if !summaryCardContents.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(summaryCardContents) { item in
                            PhoneBoundaryCard(
                                text: item.text,
                                containerSize: containerSize
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: min(containerSize.width - 32, 430))
            .background {
                RadialGradient(
                    colors: [
                        Color.black.opacity(0.12),
                        Color.black.opacity(0.06),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: min(containerSize.width * 0.55, 240)
                )
                .frame(width: min(containerSize.width - 28, 400), height: 184)
                .blur(radius: 26)
                .offset(y: 14)
            }
            .padding(.top, max(containerSize.height * 0.018, 14))

            Spacer(minLength: 0)

            Button(action: onDateTap) {
                Text(phoneSummaryDateLine(hijriDate: snapshot.hijriDate))
                    .font(headerFont)
                    .foregroundColor(PHONE_SCREEN_TITLE.opacity(0.88))
                    .tracking(0.45)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(isInteractive)
            .background {
                Ellipse()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: min(containerSize.width - 70, 240), height: 30)
                    .blur(radius: 14)
            }
            .padding(.bottom, max(containerSize.height * 0.044, 30))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
    }
}

private struct PhoneCenterHijriLabelModifier: ViewModifier {
    let isEid: Bool
    let secondary: Bool

    func body(content: Content) -> some View {
        let baseColor = isEid
            ? Color(red: 0.06, green: 0.73, blue: 0.51)
            : (secondary ? Colors.secondaryGold : Colors.primaryGold)
        let highlight = isEid ? Color.white.opacity(0.28) : Color.white.opacity(0.2)
        let shade = isEid ? Color.black.opacity(0.38) : Color.black.opacity(0.42)
        let blur = isEid ? Color.black.opacity(0.22) : Color.black.opacity(0.28)

        content
            .foregroundColor(baseColor)
            .shadow(color: highlight, radius: 0, x: 0, y: -0.6)
            .shadow(color: shade, radius: 0, x: 0, y: 0.8)
            .shadow(color: blur, radius: 2, x: 0, y: 1.5)
    }
}

private enum PhoneOverlaySheetStyle {
    case panel
    case fullScreen
}

private struct PhoneOverlaySheet<Content: View>: View {
    let containerSize: CGSize
    let maxHeightRatio: CGFloat
    let isCentered: Bool
    let tone: PhoneSurfaceTone
    let style: PhoneOverlaySheetStyle
    let onTapDismiss: (() -> Void)?
    private let content: Content

    init(
        containerSize: CGSize,
        maxHeightRatio: CGFloat,
        isCentered: Bool = false,
        tone: PhoneSurfaceTone = .standard,
        style: PhoneOverlaySheetStyle = .panel,
        onTapDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.containerSize = containerSize
        self.maxHeightRatio = maxHeightRatio
        self.isCentered = isCentered
        self.tone = tone
        self.style = style
        self.onTapDismiss = onTapDismiss
        self.content = content()
    }

    var body: some View {
        Group {
            switch style {
            case .panel:
                content
                    .frame(
                        maxWidth: min(containerSize.width - 20, 460),
                        maxHeight: min(containerSize.height * maxHeightRatio, isCentered ? 680 : 720),
                        alignment: .top
                    )
                    .background(PhonePanelBackground(cornerRadius: PHONE_PANEL_RADIUS, tone: tone))
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: isCentered ? .center : .bottom
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, isCentered ? 18 : max(12, containerSize.height * 0.022))

            case .fullScreen:
                ZStack {
                    LinearGradient(
                        colors: [
                            tone.fillTop.opacity(0.99),
                            tone.fillBottom.opacity(1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.16),
                            Color.clear,
                            PHONE_DUST_TINT.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blendMode(.multiply)
                    .ignoresSafeArea()

                    content
                        .frame(
                            maxWidth: min(containerSize.width - 36, 420),
                            maxHeight: .infinity,
                            alignment: .top
                        )
                        .padding(.horizontal, 18)
                        .padding(.top, max(28, containerSize.height * 0.058))
                        .padding(.bottom, max(26, containerSize.height * 0.05))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        onTapDismiss?()
                    }
                )
            }
        }
    }
}

private struct PhoneHijriMonthsSheetView: View {
    let snapshot: ComputedIslamicDay
    let containerSize: CGSize
    let onDismiss: () -> Void

    private let columns = [
        GridItem(.flexible(minimum: 136, maximum: 154), spacing: 14, alignment: .leading),
        GridItem(.flexible(minimum: 136, maximum: 154), spacing: 14, alignment: .leading)
    ]

    private var translationFontSize: CGFloat {
        min(containerSize.width * 0.046, 17)
    }

    private var translationFont: Font {
        phoneTranslationFont(containerSize: containerSize)
    }

    private var ayahFont: Font {
        phoneArabicFont(size: min(containerSize.width * 0.062, 23.5), weight: .medium)
    }

    var body: some View {
        PhoneOverlaySheet(
            containerSize: containerSize,
            maxHeightRatio: 1,
            isCentered: true,
            tone: .reading,
            style: .fullScreen,
            onTapDismiss: onDismiss
        ) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    VStack(spacing: 18) {
                        Text(PHONE_INSIGHT_AYAH_AR)
                            .font(ayahFont)
                            .foregroundColor(PHONE_SACRED_WHITE.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineSpacing(min(containerSize.width * 0.037, 14.5))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: min(containerSize.width - 54, 352))

                        Text(PHONE_INSIGHT_AYAH_EN)
                            .font(translationFont)
                            .foregroundColor(PHONE_SOFT_WHITE.opacity(0.93))
                            .multilineTextAlignment(.center)
                            .lineSpacing(min(containerSize.width * 0.022, 8))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: min(containerSize.width - 66, 336))
                    }

                    Rectangle()
                        .fill(PHONE_PANEL_STROKE.opacity(0.4))
                        .frame(height: 1)
                        .frame(maxWidth: min(containerSize.width - 112, 222))

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 15) {
                        ForEach(PHONE_HIJRI_MONTH_NAMES.indices, id: \.self) { index in
                            monthRow(index: index)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, PHONE_PANEL_HORIZONTAL_PADDING)
                .padding(.vertical, PHONE_PANEL_VERTICAL_PADDING)
            }
        }
    }

    @ViewBuilder
    private func monthRow(index: Int) -> some View {
        let monthName = PHONE_HIJRI_MONTH_NAMES[index]
        let isCurrentMonth = snapshot.hijriDate.monthNumber == index + 1

        HStack(alignment: .top, spacing: 10) {
            Text("\(index + 1)")
                .font(phoneTextFont(size: min(containerSize.width * 0.034, 13), weight: .medium))
                .foregroundColor(PHONE_MUTED_META.opacity(0.62))
                .frame(width: 18, alignment: .trailing)

            Text(phoneSentenceCaseMonth(monthName))
                .font(phoneTextFont(size: min(containerSize.width * 0.041, 15), weight: .regular))
                .foregroundColor(isCurrentMonth ? PHONE_ANTIQUE_GOLD : PHONE_SOFT_WHITE.opacity(0.94))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PhoneNotificationOverlayView: View {
    let text: String
    let containerSize: CGSize

    private var messageFontSize: CGFloat {
        min(containerSize.width * 0.043, 18)
    }

    private var messageFont: Font {
        phoneTextFont(size: messageFontSize, weight: .medium)
    }

    private var translationTop: CGFloat {
        let ayahTop = containerSize.height * 0.019
        let ayahFontSize = min(containerSize.width * 0.058, 24)
        return ayahTop + ayahFontSize * 2.45 + containerSize.height * 0.02
    }

    var body: some View {
        Text(text)
            .font(messageFont)
            .foregroundColor(PHONE_SOFT_WHITE.opacity(0.98))
            .multilineTextAlignment(.center)
            .lineSpacing(containerSize.height * 0.0045)
            .tracking(messageFontSize * 0.01)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: min(containerSize.width - 76, 328))
            .shadow(color: Color.black.opacity(0.22), radius: 2, x: 0, y: 1)
            .padding(.top, translationTop)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct PhoneCurrentCueView: View {
    let text: String
    let containerSize: CGSize
    let isEmphasized: Bool

    private var messageFontSize: CGFloat {
        min(containerSize.width * 0.041, 17)
    }

    private var messageFont: Font {
        phoneTextFont(size: messageFontSize, weight: .medium)
    }

    private var translationTop: CGFloat {
        let ayahTop = containerSize.height * 0.019
        let ayahFontSize = min(containerSize.width * 0.058, 24)
        return ayahTop + ayahFontSize * 2.45 + containerSize.height * 0.02
    }

    var body: some View {
        Text(text)
            .font(messageFont)
            .foregroundColor(PHONE_SOFT_WHITE.opacity(isEmphasized ? 0.96 : 0.78))
            .multilineTextAlignment(.center)
            .lineSpacing(containerSize.height * 0.004)
            .tracking(messageFontSize * 0.008)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: min(containerSize.width - 84, 336))
            .shadow(color: Color.black.opacity(isEmphasized ? 0.3 : 0.18), radius: isEmphasized ? 3 : 1.5, x: 0, y: 1)
            .shadow(
                color: PHONE_ANTIQUE_GOLD.opacity(isEmphasized ? 0.12 : 0),
                radius: isEmphasized ? 10 : 0
            )
            .scaleEffect(isEmphasized ? 1.015 : 1)
            .padding(.top, translationTop)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct PhoneSecondaryScreenContainer: View {
    let screen: PhoneSecondaryScreen
    let snapshot: ComputedIslamicDay
    let containerSize: CGSize
    let onShowDalil: (String) -> Void
    let onShowTechnical: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        switch screen {
        case .hijri:
            PhoneHijriMonthsSheetView(
                snapshot: snapshot,
                containerSize: containerSize,
                onDismiss: onDismiss
            )
        case .dalil(let title):
            PhoneSectorTitleSpotlightView(
                title: title,
                containerSize: containerSize,
                mode: .dalil,
                onDismiss: onDismiss,
                onShowTechnical: { onShowTechnical(title) },
                onReturnToDalil: {}
            )
        case .technical(let title):
            PhoneSectorTitleSpotlightView(
                title: title,
                containerSize: containerSize,
                mode: .technical,
                onDismiss: onDismiss,
                onShowTechnical: {},
                onReturnToDalil: { onShowDalil(title) }
            )
        }
    }
}

private struct PhoneSectorTitleSpotlightView: View {
    let title: String
    let containerSize: CGSize
    let mode: PhoneReadingScreenMode
    let onDismiss: () -> Void
    let onShowTechnical: () -> Void
    let onReturnToDalil: () -> Void

    private struct ReadingPassage: Identifiable {
        let id: String
        let arabic: String
        let english: String
        let source: String?
    }

    private struct TechnicalLine: Identifiable {
        let id: String
        let label: String
        let detail: String
    }

    private struct TechnicalSectionEntry: Identifiable {
        let id: String
        let heading: String
        let lines: [TechnicalLine]
    }

    private var isPrayerTimingGroup: Bool {
        PHONE_JIBRIL_GROUP_ONE.contains(title)
    }

    private var isJumuah: Bool {
        title == "Jumu'ah"
    }

    private var isSunDayGroup: Bool {
        PHONE_JIBRIL_GROUP_TWO.contains(title)
    }

    private var isLastThird: Bool {
        title == "Last 3rd"
    }

    private var readingPassages: [ReadingPassage] {
        if isJumuah {
            return [
                ReadingPassage(
                    id: "jumuah_ayah",
                    arabic: PHONE_JUMUAH_AYAH_AR,
                    english: PHONE_JUMUAH_AYAH_EN,
                    source: nil
                ),
                ReadingPassage(
                    id: "jumuah_one",
                    arabic: PHONE_JUMUAH_HADITH_ONE_AR,
                    english: PHONE_JUMUAH_HADITH_ONE_EN,
                    source: "Sunan Abi Dawud 1067"
                ),
                ReadingPassage(
                    id: "jumuah_two",
                    arabic: PHONE_JUMUAH_HADITH_TWO_AR,
                    english: PHONE_JUMUAH_HADITH_TWO_EN,
                    source: "Sahih Muslim 857"
                ),
                ReadingPassage(
                    id: "jumuah_three",
                    arabic: PHONE_JUMUAH_HADITH_THREE_AR,
                    english: PHONE_JUMUAH_HADITH_THREE_EN,
                    source: "Sahih al-Bukhari 937"
                )
            ]
        }

        if isPrayerTimingGroup {
            return [
                ReadingPassage(
                    id: "jibril",
                    arabic: PHONE_JIBRIL_HADITH_AR,
                    english: PHONE_JIBRIL_HADITH_EN,
                    source: "Sunan Abi Dawud 393"
                )
            ]
        }

        if isSunDayGroup {
            return [
                ReadingPassage(
                    id: "duha_one",
                    arabic: PHONE_DUHA_HADITH_ONE_AR,
                    english: PHONE_DUHA_HADITH_ONE_EN,
                    source: "Jami` at-Tirmidhi 475"
                ),
                ReadingPassage(
                    id: "duha_two",
                    arabic: PHONE_DUHA_HADITH_TWO_AR,
                    english: PHONE_DUHA_HADITH_TWO_EN,
                    source: "Sahih Muslim 720"
                ),
                ReadingPassage(
                    id: "duha_three",
                    arabic: PHONE_DUHA_HADITH_THREE_AR,
                    english: PHONE_DUHA_HADITH_THREE_EN,
                    source: "Sahih Muslim 832"
                )
            ]
        }

        if isLastThird {
            return [
                ReadingPassage(
                    id: "last_third",
                    arabic: PHONE_LAST_THIRD_HADITH_AR,
                    english: PHONE_LAST_THIRD_HADITH_EN,
                    source: "Sahih Muslim 758"
                )
            ]
        }

        return []
    }

    private var technicalSections: [TechnicalSectionEntry] {
        if isPrayerTimingGroup {
            return [
                TechnicalSectionEntry(
                    id: "dhuhr",
                    heading: "Dhuhr",
                    lines: [
                        TechnicalLine(
                            id: "dhuhr_start",
                            label: "Start",
                            detail: "calculated according to Umm al-Qura, 18.5° (at the user’s coordinates)."
                        ),
                        TechnicalLine(
                            id: "dhuhr_end",
                            label: "End",
                            detail: "at the start of Asr."
                        )
                    ]
                ),
                TechnicalSectionEntry(
                    id: "asr",
                    heading: "Asr",
                    lines: [
                        TechnicalLine(
                            id: "asr_start",
                            label: "Start",
                            detail: "when shadow length = object height + noon shadow (at the user’s coordinates)."
                        ),
                        TechnicalLine(
                            id: "asr_end",
                            label: "End",
                            detail: "at the start of Maghrib."
                        )
                    ]
                ),
                TechnicalSectionEntry(
                    id: "maghrib",
                    heading: "Maghrib",
                    lines: [
                        TechnicalLine(
                            id: "maghrib_start",
                            label: "Start",
                            detail: "at sunset, when the sun disappears below the horizon (at the user’s coordinates)."
                        ),
                        TechnicalLine(
                            id: "maghrib_end",
                            label: "End",
                            detail: "at the start of Isha."
                        )
                    ]
                ),
                TechnicalSectionEntry(
                    id: "isha",
                    heading: "Isha",
                    lines: [
                        TechnicalLine(
                            id: "isha_start",
                            label: "Start",
                            detail: "when the evening twilight disappears, using the Adhan model with Shafaq Ahmer and a 15° sun angle (at the user’s coordinates)."
                        ),
                        TechnicalLine(
                            id: "isha_end",
                            label: "End",
                            detail: "at the start of Fajr."
                        )
                    ]
                ),
                TechnicalSectionEntry(
                    id: "fajr",
                    heading: "Fajr",
                    lines: [
                        TechnicalLine(
                            id: "fajr_start",
                            label: "Start",
                            detail: "calculated according to Umm al-Qura, 18.5° (at the user’s coordinates)."
                        ),
                        TechnicalLine(
                            id: "fajr_end",
                            label: "End",
                            detail: "at the start of Sunrise."
                        )
                    ]
                )
            ]
        }

        if isSunDayGroup {
            return [
                TechnicalSectionEntry(
                    id: "sunrise",
                    heading: "Sunrise",
                    lines: [
                        TechnicalLine(
                            id: "sunrise_start",
                            label: "Start",
                            detail: "calculated with the Adhan library (at the user’s coordinates), using the standard apparent solar altitude of −50 arcminutes (≈ −0.83°)."
                        ),
                        TechnicalLine(
                            id: "sunrise_end",
                            label: "End",
                            detail: "at the start of Duha."
                        )
                    ]
                ),
                TechnicalSectionEntry(
                    id: "duha",
                    heading: "Duha",
                    lines: [
                        TechnicalLine(
                            id: "duha_start",
                            label: "Start",
                            detail: "when the sun reaches 4° altitude above the horizon (at the user’s coordinates); if needed, fallback = 20 minutes after Sunrise."
                        ),
                        TechnicalLine(
                            id: "duha_end",
                            label: "End",
                            detail: "at the start of Midday."
                        )
                    ]
                ),
                TechnicalSectionEntry(
                    id: "midday",
                    heading: "Midday",
                    lines: [
                        TechnicalLine(
                            id: "midday_start",
                            label: "Start",
                            detail: "5 minutes before Dhuhr."
                        ),
                        TechnicalLine(
                            id: "midday_end",
                            label: "End",
                            detail: "at Dhuhr."
                        )
                    ]
                )
            ]
        }

        if isLastThird {
            return [
                TechnicalSectionEntry(
                    id: "last_third",
                    heading: "Last 3rd",
                    lines: [
                        TechnicalLine(
                            id: "last_third_start",
                            label: "Start",
                            detail: "time between last Maghrib and Fajr divided by 3."
                        ),
                        TechnicalLine(
                            id: "last_third_end",
                            label: "End",
                            detail: "at the start of Fajr."
                        )
                    ]
                )
            ]
        }

        return []
    }

    private func sectionLink(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(phoneMetadataFont(containerSize: containerSize))
                .foregroundColor(PHONE_MUTED_META.opacity(0.94))
                .tracking(0.15)
                .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func technicalLine(label: String, detail: String) -> some View {
        (
            Text("\(label): ")
                .font(phoneTextFont(size: min(containerSize.width * 0.041, 15.5), weight: .semibold))
                .foregroundColor(PHONE_SACRED_WHITE.opacity(0.92))
            +
            Text(detail)
                .font(phoneTextFont(size: min(containerSize.width * 0.043, 16), weight: .regular))
                .foregroundColor(PHONE_SOFT_WHITE.opacity(0.92))
        )
        .lineSpacing(min(containerSize.width * 0.015, 5.5))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func readingPassageGroup(_ passage: ReadingPassage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(passage.arabic)
                .font(phoneArabicFont(size: min(containerSize.width * 0.06, 22.5), weight: .medium))
                .foregroundColor(PHONE_SACRED_WHITE.opacity(0.95))
                .multilineTextAlignment(.trailing)
                .lineSpacing(min(containerSize.width * 0.037, 14.5))
                .frame(maxWidth: min(containerSize.width - 44, 352), alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 22)

            Text(passage.english)
                .font(phoneTextFont(size: min(containerSize.width * 0.044, 16.5), weight: .regular))
                .foregroundColor(PHONE_SOFT_WHITE.opacity(0.93))
                .multilineTextAlignment(.leading)
                .lineSpacing(min(containerSize.width * 0.022, 8))
                .frame(maxWidth: min(containerSize.width - 58, 336), alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            if let source = passage.source {
                Text(source)
                    .font(phoneTextFont(size: min(containerSize.width * 0.037, 13.5), weight: .medium))
                    .foregroundColor(PHONE_MUTED_META.opacity(0.86))
                    .tracking(0.12)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: min(containerSize.width - 58, 336), alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func technicalDetailsLink() -> some View {
        sectionLink("Technical details") {
            phoneSelectionHaptic()
            onShowTechnical()
        }
    }

    private func meaningLink() -> some View {
        sectionLink("← Meaning") {
            phoneSelectionHaptic()
            onReturnToDalil()
        }
    }

    @ViewBuilder
    private func dalilContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(readingPassages.enumerated()), id: \.element.id) { index, passage in
                readingPassageGroup(passage)

                if index < readingPassages.count - 1 {
                    Rectangle()
                        .fill(PHONE_PANEL_STROKE.opacity(0.4))
                        .frame(height: 1)
                        .frame(maxWidth: min(containerSize.width - 112, 222))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 30)
                        .padding(.bottom, 34)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.horizontal, PHONE_PANEL_HORIZONTAL_PADDING)
        .padding(.vertical, PHONE_PANEL_VERTICAL_PADDING)
    }

    @ViewBuilder
    private func technicalDetailsContent() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                meaningLink()
                Spacer()
            }

            Text("Technical details")
                .font(phoneMetadataFont(containerSize: containerSize))
                .foregroundColor(PHONE_MUTED_META.opacity(0.94))
                .tracking(0.2)
                .multilineTextAlignment(.leading)

            ForEach(technicalSections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.heading)
                        .font(phoneDisplayFont(size: min(containerSize.width * 0.053, 20), weight: .semibold))
                        .foregroundColor(PHONE_SACRED_WHITE.opacity(0.95))
                        .multilineTextAlignment(.leading)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(section.lines) { line in
                            technicalLine(label: line.label, detail: line.detail)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, section.id == technicalSections.last?.id ? 0 : 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, PHONE_PANEL_HORIZONTAL_PADDING)
        .padding(.vertical, 18)
    }

    var body: some View {
        PhoneOverlaySheet(
            containerSize: containerSize,
            maxHeightRatio: mode == .technical ? 0.94 : 0.88,
            isCentered: true,
            tone: .reading,
            style: mode == .dalil ? .fullScreen : .panel,
            onTapDismiss: mode == .dalil ? onDismiss : nil
        ) {
            ScrollView(showsIndicators: false) {
                if mode == .dalil {
                    dalilContent()
                } else {
                    technicalDetailsContent()
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
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
    let onDebugPush: (() -> Void)?
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
                        if let onDebugPush {
                            Button("Push") {
                                onDebugPush()
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(Colors.neutralHeadingWhite)
                        }
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
