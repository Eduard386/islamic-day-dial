import { getSunriseToDhuhrSubPeriod, type ComputedIslamicDay } from '@islamic-day-dial/core';
import loadingAsr from '../assets/loading/loading-asr.png';
import loadingDhuhr from '../assets/loading/loading-dhuhr.png';
import loadingDuha from '../assets/loading/loading-duha.png';
import loadingFajr from '../assets/loading/loading-fajr.png';
import loadingIsha from '../assets/loading/loading-isha.png';
import loadingLastThird from '../assets/loading/loading-last-third.png';
import loadingMaghrib from '../assets/loading/loading-maghrib.png';
import loadingMidday from '../assets/loading/loading-midday.png';
import loadingSunrise from '../assets/loading/loading-sunrise.png';

export type LoadingStillKey =
  | 'fajr'
  | 'sunrise'
  | 'duha'
  | 'midday'
  | 'dhuhr'
  | 'asr'
  | 'maghrib'
  | 'isha'
  | 'lastThird';

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
};

/** Background still matches the current phase (same on Eid / Jumu'ah days). */
export function getLoadingStillKey(snapshot: ComputedIslamicDay, now: Date): LoadingStillKey {
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
