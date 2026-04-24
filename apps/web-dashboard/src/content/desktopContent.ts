import type { ComputedIslamicDay } from '@islamic-day-dial/core';
import {
  formatHijriDateParts,
  getSectorDisplayName,
  getSunriseToDhuhrSubPeriod,
} from '@islamic-day-dial/core';

export type ReadingKey = 'prayerTimings' | 'sunDay' | 'lastThird' | 'jumuah';

export type ReadingBlock =
  | { kind: 'arabic'; text: string }
  | { kind: 'english'; text: string }
  | { kind: 'source'; text: string };

export type ReadingPanelContent = {
  title: string;
  blocks: ReadingBlock[];
  technicalSections?: TechnicalSection[];
};

export type TechnicalLine = {
  label: string;
  detail: string;
};

export type TechnicalSection = {
  heading: string;
  lines: TechnicalLine[];
};

export const WEB_INSIGHT_AYAH_AR = 'إِنَّ عِدَّةَ الشُّهُورِ عِنْدَ اللَّهِ اثْنَا عَشَرَ شَهْرًا';
export const WEB_INSIGHT_AYAH_EN = '"Indeed, the number of months ordained by Allah is twelve" [9:36]';

/** Quran 4:103 — footer below the dial (web). */
export const WEB_DIAL_FOOTER_AYAH_4_103_AR =
  'إِنَّ ٱلصَّلَوٰةَ كَانَتْ عَلَى ٱلْمُؤْمِنِينَ كِتَـٰبًۭا مَّوْقُوتًۭا';
export const WEB_DIAL_FOOTER_AYAH_4_103_EN =
  '"Indeed, performing prayers is a duty on the believers at the appointed times." [4:103]';

/** Eid (incl. Friday): Duha, Midday, Dhuhr — matches iOS `PHONE_CUE_EID_DAYTIME_TAQABBAL`. */
const WEB_CUE_EID_DAYTIME_TAQABBAL = `تَقَبَّلَ اللهُ مِنَّا وَمِنكُم
Taqabbalallahu minna wa minkum!
May Allah accept [this worship] from you and us!`;

function webObservationalCueForSectorTitle(sectorTitle: string): string {
  switch (sectorTitle) {
    case 'Fajr':
      return 'If the sky is brightening, it is Fajr time.';
    case 'Sunrise':
      return 'Watch the horizon. Has the sun begun to rise?';
    case 'Duha':
      return 'Look at the sun. Has the morning light clearly spread?';
    case 'Midday':
      return 'The sun is at its highest point, and shadows are at their shortest. It is Midday.';
    case 'Dhuhr':
      return 'If the sun has passed the zenith and shadows have started to grow again, it is Dhuhr time.';
    case 'Asr':
      return "Asr starts when the shadow length equals the object's height plus its noon shadow.";
    case 'Maghrib':
      return 'If the sun has gone down, Maghrib time has begun.';
    case 'Isha':
      return 'Isha starts when the last twilight has disappeared.';
    case 'Last 3rd':
      return 'The last third of the night is here. Isha lasts from Maghrib to Fajr.';
    case "Jumu'ah":
      return "Prepare for Jumu'ah: take a bath, use perfume, dress well, and remain silent during the khutbah.";
    case 'EID AL-FITR':
      return 'Eid al-Fitr prayer time has started.';
    case 'EID AL-ADHA':
      return 'Eid al-Adha prayer time has started.';
    default:
      return sectorTitle;
  }
}

/** Observational cue above the dial — mirrors iOS `phoneHomeCurrentCueText` (Eid Duha/Midday/Dhuhr → Taqabbal). */
export function getWebObservationalCue(snapshot: ComputedIslamicDay, now: Date): string {
  const hijriParts = formatHijriDateParts(snapshot.hijriDate);
  const rawSectorTitle = getSectorDisplayName(now, snapshot.currentPhase, {
    duhaStart: snapshot.timeline.duhaStart,
    dhuhr: snapshot.timeline.dhuhr,
  });

  if (!hijriParts.isEid) {
    return webObservationalCueForSectorTitle(rawSectorTitle);
  }

  switch (snapshot.currentPhase) {
    case 'sunrise_to_dhuhr': {
      const sub = getSunriseToDhuhrSubPeriod(now, snapshot.timeline.duhaStart, snapshot.timeline.dhuhr);
      if (sub === 'duha' || sub === 'midday') return WEB_CUE_EID_DAYTIME_TAQABBAL;
      break;
    }
    case 'dhuhr_to_asr':
      return WEB_CUE_EID_DAYTIME_TAQABBAL;
    default:
      break;
  }
  return webObservationalCueForSectorTitle(rawSectorTitle);
}

/** Hide the "OBSERVE" overline (same as Jumu'ah) when the Eid Taqabbal block is shown. */
export function shouldHidePhaseGuidanceObserveOverline(guidanceText: string): boolean {
  return guidanceText === WEB_CUE_EID_DAYTIME_TAQABBAL;
}

/** Sector-only cue (no Eid window); prefer {@link getWebObservationalCue} for the live dial. */
export function getWebObservationalCueForSector(sectorTitle: string): string {
  return webObservationalCueForSectorTitle(sectorTitle);
}

export const WEB_HIJRI_MONTH_NAMES = [
  'Muharram',
  'Safar',
  'Rabi al-Awwal',
  'Rabi al-Thani',
  'Jumada al-Ula',
  'Jumada al-Thani',
  'Rajab',
  'Shaban',
  'Ramadan',
  'Shawwal',
  'Dhul Qadah',
  'Dhul Hijjah',
] as const;

const JIBRIL_GROUP = new Set(['Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Fajr']);
const SUN_DAY_GROUP = new Set(['Sunrise', 'Duha', 'Midday']);

const PHONE_JIBRIL_HADITH_AR = 'قَالَ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ ‏ "‏ أَمَّنِي جِبْرِيلُ عَلَيْهِ السَّلاَمُ عِنْدَ الْبَيْتِ مَرَّتَيْنِ فَصَلَّى بِيَ الظُّهْرَ حِينَ زَالَتِ الشَّمْسُ وَكَانَتْ قَدْرَ الشِّرَاكِ وَصَلَّى بِيَ الْعَصْرَ حِينَ كَانَ ظِلُّهُ مِثْلَهُ وَصَلَّى بِيَ - يَعْنِي الْمَغْرِبَ - حِينَ أَفْطَرَ الصَّائِمُ وَصَلَّى بِيَ الْعِشَاءَ حِينَ غَابَ الشَّفَقُ وَصَلَّى بِيَ الْفَجْرَ حِينَ حَرُمَ الطَّعَامُ وَالشَّرَابُ عَلَى الصَّائِمِ فَلَمَّا كَانَ الْغَدُ صَلَّى بِيَ الظُّهْرَ حِينَ كَانَ ظِلُّهُ مِثْلَهُ وَصَلَّى بِيَ الْعَصْرَ حِينَ كَانَ ظِلُّهُ مِثْلَيْهِ وَصَلَّى بِيَ الْمَغْرِبَ حِينَ أَفْطَرَ الصَّائِمُ وَصَلَّى بِيَ الْعِشَاءَ إِلَى ثُلُثِ اللَّيْلِ وَصَلَّى بِيَ الْفَجْرَ فَأَسْفَرَ ثُمَّ الْتَفَتَ إِلَىَّ فَقَالَ يَا مُحَمَّدُ هَذَا وَقْتُ الأَنْبِيَاءِ مِنْ قَبْلِكَ وَالْوَقْتُ مَا بَيْنَ هَذَيْنِ الْوَقْتَيْنِ ‏"‏ ‏.';
const PHONE_JIBRIL_HADITH_EN = `The Messenger of Allah (ﷺ) said: Gabriel (ﷺ) led me in prayer at the House (i.e. the Ka'bah). He prayed the noon prayer with me when the sun had passed the meridian to the extent of the thong of a sandal; he prayed the afternoon prayer with me when the shadow of everything was as long as itself; he prayed the sunset prayer with me when one who is fasting breaks the fast; he prayed the night prayer with me when the twilight had ended; and he prayed the dawn prayer with me when food and drink become forbidden to one who is keeping the fast.

On the following day he prayed the noon prayer with me when his shadow was as long as himself; he prayed the afternoon prayer with me when his shadow was twice as long as himself; he prayed the sunset prayer at the time when one who is fasting breaks the fast; he prayed the night prayer with me when about the third of the night had passed; and he prayed the dawn prayer with me when there was a fair amount of light.

Then turning to me he said: Muhammad, this is the time observed by the prophets before you, and the time is anywhere between two times.`;

const PHONE_DUHA_HADITH_ONE_AR = 'حَدَّثَنَا أَبُو جَعْفَرٍ السِّمْنَانِيُّ، حَدَّثَنَا أَبُو مُسْهِرٍ، حَدَّثَنَا إِسْمَاعِيلُ بْنُ عَيَّاشٍ، عَنْ بَحِيرِ بْنِ سَعْدٍ، عَنْ خَالِدِ بْنِ مَعْدَانَ، عَنْ جُبَيْرِ بْنِ نُفَيْرٍ، عَنْ أَبِي الدَّرْدَاءِ، وَأَبِي، ذَرٍّ عَنْ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ ‏ "‏ عَنِ اللَّهِ، عَزَّ وَجَلَّ أَنَّهُ قَالَ ابْنَ آدَمَ ارْكَعْ لِي مِنْ أَوَّلِ النَّهَارِ أَرْبَعَ رَكَعَاتٍ أَكْفِكَ آخِرَهُ ‏"‏.';
const PHONE_DUHA_HADITH_ONE_EN = `Allah's Messenger narrated that Allah, Blessed and Most High said: "Son of Adam: Perform four Rak'ah for Me in the beginning of the day it will suffice you for the latter part of it".`;
const PHONE_DUHA_HADITH_TWO_AR = 'حَدَّثَنَا عَبْدُ اللَّهِ بْنُ مُحَمَّدِ بْنِ أَسْمَاءَ الضُّبَعِيُّ، حَدَّثَنَا مَهْدِيٌّ، - وَهُوَ ابْنُ مَيْمُونٍ - حَدَّثَنَا وَاصِلٌ، مَوْلَى أَبِي عُيَيْنَةَ عَنْ يَحْيَى بْنِ عُقَيْلٍ، عَنْ يَحْيَى بْنِ يَعْمَرَ، عَنْ أَبِي الأَسْوَدِ الدُّؤَلِيِّ، عَنْ أَبِي ذَرٍّ، عَنِ النَّبِيِّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ أَنَّهُ قَالَ ‏ "‏ يُصْبِحُ عَلَى كُلِّ سُلاَمَى مِنْ أَحَدِكُمْ صَدَقَةٌ فَكُلُّ تَسْبِيحَةٍ صَدَقَةٌ وَكُلُّ تَحْمِيدَةٍ صَدَقَةٌ وَكُلُّ تَهْلِيلَةٍ صَدَقَةٌ وَكُلُّ تَكْبِيرَةٍ صَدَقَةٌ وَأَمْرٌ بِالْمَعْرُوفِ صَدَقَةٌ وَنَهْىٌ عَنِ الْمُنْكَرِ صَدَقَةٌ وَيُجْزِئُ مِنْ ذَلِكَ رَكْعَتَانِ يَرْكَعُهُمَا مِنَ الضُّحَى‏".';
const PHONE_DUHA_HADITH_TWO_EN = `Abu Dharr reported Allah's Apostle (ﷺ) as saying: "In the morning charity is due from every bone in the body of every one of you. Every utterance of Allah's glorification is an act of charity. Every utterance of praise of Him is an act of charity, every utterance of profession of His Oneness is an act of charity, every utterance of profession of His Greatness is an act of charity, enjoining good is an act of charity, forbidding what is distreputable is an act of charity, and two rak'ahs which one prays in the forenoon will suffice".`;
const PHONE_DUHA_HADITH_THREE_AR = 'قَالَ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ ‏"‏صَلِّ صَلاَةَ الصُّبْحِ ثُمَّ أَقْصِرْ عَنِ الصَّلاَةِ حَتَّى تَطْلُعَ الشَّمْسُ حَتَّى تَرْتَفِعَ فَإِنَّهَا تَطْلُعُ حِينَ تَطْلُعُ بَيْنَ قَرْنَىْ شَيْطَانٍ وَحِينَئِذٍ يَسْجُدُ لَهَا الْكُفَّارُ ثُمَّ صَلِّ فَإِنَّ الصَّلاَةَ مَشْهُودَةٌ مَحْضُورَةٌ حَتَّى يَسْتَقِلَّ الظِّلُّ بِالرُّمْحِ ثُمَّ أَقْصِرْ عَنِ الصَّلاَةِ فَإِنَّ حِينَئِذٍ تُسْجَرُ جَهَنَّمُ ‏"‏.';
const PHONE_DUHA_HADITH_THREE_EN = 'Messenger of Allah (ﷺ) said: “Observe the dawn prayer, then stop praying when the sun is rising till it is fully up, for when it rises it comes up between the horns of Satan, and the unbelievers prostrate themselves to it at that time. Then pray, for the prayer is witnessed and attended (by angels) till the shadow becomes about the length of a lance; then cease prayer, for at that time Hell is heated up.”';

const PHONE_LAST_THIRD_HADITH_AR = 'أَنَّ رَسُولَ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ قَالَ ‏ "يَنْزِلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الْآخِرِ فَيَقُولُ مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ وَمَنْ يَسْأَلُنِي فَأُعْطِيَهُ وَمَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ ‏"‏.‏';
const PHONE_LAST_THIRD_HADITH_EN = `Allah's Messenger (ﷺ) said, "Our Lord, the Blessed and the Exalted, descends every night to the lowest heaven when one-third of the latter part of the night is left, and says: Who supplicates Me so that I may answer him? Who asks Me so that I may give to him? Who asks Me forgiveness so that I may forgive him?"`;

const PHONE_JUMUAH_AYAH_AR = 'قَالَ اللَّهُ تَعَالَى: يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا نُودِىَ لِلصَّلَوٰةِ مِن يَوْمِ ٱلْجُمُعَةِ فَٱسْعَوْا۟ إِلَىٰ ذِكْرِ ٱللَّهِ وَذَرُوا۟ ٱلْبَيْعَ ۚ ذَٰلِكُمْ خَيْرٌۭ لَّكُمْ إِن كُنتُمْ تَعْلَمُونَ';
const PHONE_JUMUAH_AYAH_EN = 'Allah, the Exalted, said: "O believers! When the call to prayer is made on Friday, then proceed (diligently) to the remembrance of Allah and leave off (your) business. That is best for you, if only you knew" [62:9]';
const PHONE_JUMUAH_HADITH_ONE_AR = 'عَنِ النَّبِيِّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ قَالَ ‏ "الْجُمُعَةُ حَقٌّ وَاجِبٌ عَلَى كُلِّ مُسْلِمٍ فِي جَمَاعَةٍ إِلاَّ أَرْبَعَةً عَبْدٌ مَمْلُوكٌ أَوِ امْرَأَةٌ أَوْ صَبِيٌّ أَوْ مَرِيضٌ‏"';
const PHONE_JUMUAH_HADITH_ONE_EN = 'The Prophet (ﷺ) said: "The Friday prayer in congregation is a necessary duty for every Muslim, with four exceptions; a slave, a woman, a boy, and a sick person."';
const PHONE_JUMUAH_HADITH_TWO_AR = 'عَنِ النَّبِيِّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ قَالَ ‏ "مَنِ اغْتَسَلَ ثُمَّ أَتَى الْجُمُعَةَ فَصَلَّى مَا قُدِّرَ لَهُ ثُمَّ أَنْصَتَ حَتَّى يَفْرُغَ مِنْ خُطْبَتِهِ ثُمَّ يُصَلِّيَ مَعَهُ غُفِرَ لَهُ مَا بَيْنَهُ وَبَيْنَ الْجُمُعَةِ الأُخْرَى وَفَضْلَ ثَلاَثَةِ أَيَّامٍ‏"‏‏';
const PHONE_JUMUAH_HADITH_TWO_EN = `The Prophet (ﷺ) said: "He who took a bath and then came for Jumu'ah prayer and then prayed what was fixed for him, then kept silence till the Imam finished the sermon, and then prayed along with him, his sins between that time and the next Friday would be forgiven, and even of three days more."`;
const PHONE_JUMUAH_HADITH_THREE_AR = 'حَدَّثَنَا عَبْدُ اللَّهِ بْنُ يُوسُفَ، قَالَ أَخْبَرَنَا مَالِكٌ، عَنْ نَافِعٍ، عَنْ عَبْدِ اللَّهِ بْنِ عُمَرَ، أَنَّ رَسُولَ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ كَانَ يُصَلِّي قَبْلَ الظُّهْرِ رَكْعَتَيْنِ، وَبَعْدَهَا رَكْعَتَيْنِ، وَبَعْدَ الْمَغْرِبِ رَكْعَتَيْنِ فِي بَيْتِهِ، وَبَعْدَ الْعِشَاءِ رَكْعَتَيْنِ وَكَانَ لاَ يُصَلِّي بَعْدَ الْجُمُعَةِ حَتَّى يَنْصَرِفَ فَيُصَلِّي رَكْعَتَيْنِ‏.‏';
const PHONE_JUMUAH_HADITH_THREE_EN = "Narrated `Abdullah bin `Umar: Allah's Messenger (ﷺ) used to pray two rak`at before the Zuhr prayer and two rak`at after it. He also used to pray two rak`at after the Maghrib prayer in his house, and two rak`at after the `Isha' prayer. He never prayed after Jumu'ah prayer till he departed (from the Mosque), and then he would pray two rak`at at home.";

export function getReadingKeyForSectorDisplayName(title: string | null): ReadingKey | null {
  if (!title) return null;
  if (title === "Jumu'ah") return 'jumuah';
  if (JIBRIL_GROUP.has(title)) return 'prayerTimings';
  if (SUN_DAY_GROUP.has(title)) return 'sunDay';
  if (title === 'Last 3rd') return 'lastThird';
  return null;
}

export function getReadingKeyForFootnoteId(id: string): ReadingKey | null {
  if (['dhuhr', 'asr', 'maghrib', 'isha', 'fajr'].includes(id)) return 'prayerTimings';
  if (['sunrise', 'duha_start', 'duha_end'].includes(id)) return 'sunDay';
  if (id === 'last_third_start') return 'lastThird';
  return null;
}

const READING_CONTENT: Record<ReadingKey, ReadingPanelContent> = {
  prayerTimings: {
    title: 'Dhuhr, Asr, Maghrib, Isha, Fajr',
    blocks: [
      { kind: 'arabic', text: PHONE_JIBRIL_HADITH_AR },
      { kind: 'english', text: PHONE_JIBRIL_HADITH_EN },
      { kind: 'source', text: 'Sunan Abi Dawud, Hadith 393' },
    ],
    technicalSections: [
      {
        heading: 'Dhuhr calculation',
        lines: [
          { label: 'Start', detail: 'calculated according to Umm al-Qura, 18.5° (at the user’s coordinates).' },
          { label: 'End', detail: 'at the start of Asr.' },
        ],
      },
      {
        heading: 'Asr calculation',
        lines: [
          { label: 'Start', detail: 'when shadow length = object height + noon shadow (at the user’s coordinates).' },
          { label: 'End', detail: 'at the start of Maghrib.' },
        ],
      },
      {
        heading: 'Maghrib calculation',
        lines: [
          { label: 'Start', detail: 'at sunset, when the sun disappears below the horizon (at the user’s coordinates).' },
          { label: 'End', detail: 'at the start of Isha.' },
        ],
      },
      {
        heading: 'Isha calculation',
        lines: [
          { label: 'Start', detail: 'when the evening twilight disappears, using the Adhan model with Shafaq Ahmer and a 15° sun angle (at the user’s coordinates).' },
          { label: 'End', detail: 'at the start of Fajr.' },
        ],
      },
      {
        heading: 'Fajr calculation',
        lines: [
          { label: 'Start', detail: 'calculated according to Umm al-Qura, 18.5° (at the user’s coordinates).' },
          { label: 'End', detail: 'at the start of Sunrise.' },
        ],
      },
    ],
  },
  sunDay: {
    title: 'Sunrise, Duha, Midday',
    blocks: [
      { kind: 'arabic', text: PHONE_DUHA_HADITH_ONE_AR },
      { kind: 'english', text: PHONE_DUHA_HADITH_ONE_EN },
      { kind: 'source', text: 'Jami` at-Tirmidhi, Hadith 475' },
      { kind: 'arabic', text: PHONE_DUHA_HADITH_TWO_AR },
      { kind: 'english', text: PHONE_DUHA_HADITH_TWO_EN },
      { kind: 'source', text: 'Sahih Muslim, Hadith 720' },
      { kind: 'arabic', text: PHONE_DUHA_HADITH_THREE_AR },
      { kind: 'english', text: PHONE_DUHA_HADITH_THREE_EN },
      { kind: 'source', text: 'Sahih Muslim, Hadith 832' },
    ],
    technicalSections: [
      {
        heading: 'Sunrise calculation',
        lines: [
          { label: 'Start', detail: 'calculated with the Adhan library (at the user’s coordinates), using the standard apparent solar altitude of −50 arcminutes (≈ −0.83°).' },
          { label: 'End', detail: 'at the start of Duha.' },
        ],
      },
      {
        heading: 'Duha calculation',
        lines: [
          { label: 'Start', detail: 'when the sun reaches 4° altitude above the horizon (at the user’s coordinates); if needed, fallback = 20 minutes after Sunrise.' },
          { label: 'End', detail: 'at the start of Midday.' },
        ],
      },
      {
        heading: 'Midday calculation',
        lines: [
          { label: 'Start', detail: '5 minutes before Dhuhr.' },
          { label: 'End', detail: 'at Dhuhr.' },
        ],
      },
    ],
  },
  lastThird: {
    title: 'Last 3rd',
    blocks: [
      { kind: 'arabic', text: PHONE_LAST_THIRD_HADITH_AR },
      { kind: 'english', text: PHONE_LAST_THIRD_HADITH_EN },
      { kind: 'source', text: 'Sahih Muslim, Hadith 758' },
    ],
    technicalSections: [
      {
        heading: 'Last 3rd calculation',
        lines: [
          { label: 'Start', detail: 'time between last Maghrib and Fajr divided by 3.' },
          { label: 'End', detail: 'at the start of Fajr.' },
        ],
      },
    ],
  },
  jumuah: {
    title: "Jumu'ah",
    blocks: [
      { kind: 'arabic', text: PHONE_JUMUAH_AYAH_AR },
      { kind: 'english', text: PHONE_JUMUAH_AYAH_EN },
      { kind: 'arabic', text: PHONE_JUMUAH_HADITH_ONE_AR },
      { kind: 'english', text: PHONE_JUMUAH_HADITH_ONE_EN },
      { kind: 'source', text: 'Sunan Abi Dawud 1067' },
      { kind: 'arabic', text: PHONE_JUMUAH_HADITH_TWO_AR },
      { kind: 'english', text: PHONE_JUMUAH_HADITH_TWO_EN },
      { kind: 'source', text: 'Sahih Muslim 857' },
      { kind: 'arabic', text: PHONE_JUMUAH_HADITH_THREE_AR },
      { kind: 'english', text: PHONE_JUMUAH_HADITH_THREE_EN },
      { kind: 'source', text: 'Sahih al-Bukhari 937' },
    ],
  },
};

export function getReadingPanelContent(key: ReadingKey): ReadingPanelContent {
  return READING_CONTENT[key];
}
