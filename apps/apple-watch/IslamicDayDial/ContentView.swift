import SwiftUI
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
private let PHONE_SECONDARY_SCREEN_OFFSET: CGFloat = 18
private let PHONE_DUST_TINT = Color(red: 0.23, green: 0.18, blue: 0.13)
private let PHONE_DRY_SHADE = Color(red: 0.06, green: 0.05, blue: 0.04)
private let PHONE_INSIGHT_AYAH_AR = "قال الله تعالى: إِنَّ عِدَّةَ الشُّهُورِ عِندَ اللَّهِ اثْنَا عَشَرَ شَهْرًا"
private let PHONE_INSIGHT_AYAH_EN = "Allah, the Exalted, said:\"Indeed, the number of months ordained by Allah is twelve\" [9:36]"
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
    @AppStorage("phone.lastLoadingStillKey") private var persistedLoadingStillKeyRaw = PhonePhaseBackgroundKey.fajr.rawValue // legacy; home UI is image-free
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
                    Color.black
                        .ignoresSafeArea()

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
                    Spacer(minLength: 0)
                    Text(homePresentation.currentCueText)
                        .font(phoneTextFont(size: min(containerSize.width * 0.041, 17), weight: .medium))
                        .foregroundColor(PHONE_SOFT_WHITE.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineSpacing(containerSize.height * 0.004)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: min(containerSize.width - 48, 340))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    PhonePreStillsDialView(
                        snapshot: snapshot,
                        now: effectiveNow,
                        presentation: homePresentation,
                        interactionsEnabled: !isInteractionLocked,
                        onDateTap: beginInsightPresentation,
                        onCurrentSectorTap: beginCurrentSectorReading
                    )
                    .frame(height: DIAL_SECTION_HEIGHT)
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
        persistedLoadingStillKeyRaw = nextKey.rawValue
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

/// Shared wrapper so phone `RingView` options stay in the iOS target (pre–loading-stills layout, commit 83e97ab).
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

/// Dial layout from pre–loading-stills era: fixed diameter from section + width (same as old tap math), inner labels in the ring hole.
private struct PhonePreStillsDialView: View {
    let snapshot: ComputedIslamicDay
    let now: Date
    let presentation: PhoneHomePresentation
    let interactionsEnabled: Bool
    let onDateTap: () -> Void
    let onCurrentSectorTap: () -> Void

    private var sectorTitleColor: Color {
        presentation.displayTitle == "Jumu'ah"
            ? Color(red: 0.06, green: 0.73, blue: 0.51)
            : Colors.coolLabel
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Fixed diameter: matches legacy `min(dialFrameWidth, DIAL_SECTION_HEIGHT) * 1.28` (not `min(w,h)` so height doesn’t inflate the ring).
            let dialSize = min(max(w - 8, 0), DIAL_SECTION_HEIGHT) * 1.28
            let dialCenter = CGPoint(x: w / 2, y: h / 2)
            let titleFontSize: CGFloat = 20
            let innerLabelWidth = min(dialSize * 0.48, 220)
            // Same subtle nudge as pre-stills layout; stack is centered in the ring hole (not offset from frame top).
            let labelStackOffsetY = dialSize * (-10 / 420)

            ZStack {
                PhoneRingView(snapshot: snapshot, now: now, phoneInfoProgress: 0)
                    .frame(width: dialSize, height: dialSize)

                VStack(spacing: 10) {
                    Button {
                        onCurrentSectorTap()
                    } label: {
                        Text(presentation.displayTitle.uppercased())
                            .font(.system(size: titleFontSize, weight: .light))
                            .tracking(titleFontSize * 0.1)
                            .foregroundColor(sectorTitleColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: innerLabelWidth)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(interactionsEnabled)

                    HijriDateLabels(
                        hijriDate: snapshot.hijriDate,
                        infoProgress: 0,
                        isInteractive: interactionsEnabled,
                        onTap: onDateTap
                    )
                    .frame(width: innerLabelWidth)
                }
                .frame(width: dialSize, height: dialSize)
                .offset(y: labelStackOffsetY)
            }
            .frame(width: dialSize, height: dialSize)
            .position(dialCenter)
            .frame(width: w, height: h)
        }
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
