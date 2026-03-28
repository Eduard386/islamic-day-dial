import {
  getSectorDisplayName,
  getSunriseToDhuhrSubPeriod,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';
import loadingAsr from '../assets/loading/loading-asr.jpg';
import loadingDhuhr from '../assets/loading/loading-dhuhr.jpg';
import loadingDuha from '../assets/loading/loading-duha.jpg';
import loadingEidAlAdha from '../assets/loading/loading-eid-al-adha.jpg';
import loadingEidAlFitr from '../assets/loading/loading-eid-al-fitr.jpg';
import loadingFajr from '../assets/loading/loading-fajr.jpg';
import loadingIsha from '../assets/loading/loading-isha.jpg';
import loadingJumuah from '../assets/loading/loading-jumuah.jpg';
import loadingLastThird from '../assets/loading/loading-last-third.jpg';
import loadingMaghrib from '../assets/loading/loading-maghrib.jpg';
import loadingMidday from '../assets/loading/loading-midday.jpg';
import loadingSunrise from '../assets/loading/loading-sunrise.jpg';

export type LoadingStillKey =
  | 'fajr'
  | 'sunrise'
  | 'duha'
  | 'midday'
  | 'dhuhr'
  | 'asr'
  | 'maghrib'
  | 'isha'
  | 'lastThird'
  | 'jumuah'
  | 'eidAlFitr'
  | 'eidAlAdha';

export const LOADING_STILL_SOURCES: Record<LoadingStillKey, string> = {
  fajr: loadingFajr,
  sunrise: loadingSunrise,
  duha: loadingDuha,
  midday: loadingMidday,
  dhuhr: loadingDhuhr,
  asr: loadingAsr,
  maghrib: loadingMaghrib,
  isha: loadingIsha,
  lastThird: loadingLastThird,
  jumuah: loadingJumuah,
  eidAlFitr: loadingEidAlFitr,
  eidAlAdha: loadingEidAlAdha,
};

export function getLoadingStillKey(snapshot: ComputedIslamicDay, now: Date): LoadingStillKey {
  if (snapshot.hijriDate.monthNumber === 10 && snapshot.hijriDate.day === 1) {
    return 'eidAlFitr';
  }
  if (snapshot.hijriDate.monthNumber === 12 && snapshot.hijriDate.day === 10) {
    return 'eidAlAdha';
  }

  const sectorTitle = getSectorDisplayName(
    now,
    snapshot.currentPhase,
    { duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr },
  );
  if (sectorTitle === "Jumu'ah") {
    return 'jumuah';
  }

  switch (snapshot.currentPhase) {
    case 'maghrib_to_isha':
      return 'maghrib';
    case 'isha_to_last_third':
      return 'isha';
    case 'last_third_to_fajr':
      return 'lastThird';
    case 'fajr_to_sunrise':
      return 'fajr';
    case 'sunrise_to_dhuhr': {
      const subPeriod = getSunriseToDhuhrSubPeriod(
        now,
        snapshot.timeline.duhaStart,
        snapshot.timeline.dhuhr,
      );
      if (subPeriod === 'sunrise') return 'sunrise';
      if (subPeriod === 'duha') return 'duha';
      return 'midday';
    }
    case 'dhuhr_to_asr':
      return 'dhuhr';
    case 'asr_to_maghrib':
      return 'asr';
  }
}
