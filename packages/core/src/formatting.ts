import type { HijriDate, IslamicPhaseId } from './types.js';

export function formatHijriDate(date: HijriDate): string {
  if (date.monthNumber === 10 && date.day === 1) {
    return 'EID AL-FITR';
  }
  if (date.monthNumber === 12 && date.day === 10) {
    return 'EID AL-ADHA';
  }
  return `${date.day} ${date.monthNameEn} ${date.year}`;
}

export type HijriDateParts = {
  dayMonth: string;
  year: string;
  isEid: boolean;
};

export function formatHijriDateParts(date: HijriDate): HijriDateParts {
  if (date.monthNumber === 10 && date.day === 1) {
    return { dayMonth: 'EID AL-FITR', year: String(date.year), isEid: true };
  }
  if (date.monthNumber === 12 && date.day === 10) {
    return { dayMonth: 'EID AL-ADHA', year: String(date.year), isEid: true };
  }
  return {
    dayMonth: `${date.day} ${date.monthNameEn}`,
    year: String(date.year),
    isEid: false,
  };
}

export function formatCountdown(ms: number): string {
  if (ms <= 0) return '-00:00';
  const totalSeconds = Math.floor(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  return '-' + String(hours).padStart(2, '0') + ':' + String(minutes).padStart(2, '0');
}

const PHASE_LABELS: Record<IslamicPhaseId, string> = {
  maghrib_to_isha: 'Maghrib → Isha',
  isha_to_midnight: 'Isha',
  last_third_to_fajr: 'Isha',
  fajr_to_sunrise: 'Fajr → Sunrise',
  sunrise_to_dhuhr: 'Sunrise → Dhuhr',
  dhuhr_to_asr: 'Dhuhr → Asr',
  asr_to_maghrib: 'Asr → Maghrib',
};

export function formatPhase(phase: IslamicPhaseId): string {
  return PHASE_LABELS[phase];
}

const PERIOD_NAMES: Record<IslamicPhaseId, string> = {
  maghrib_to_isha: 'Maghrib',
  isha_to_midnight: 'Isha',
  last_third_to_fajr: 'Isha',
  fajr_to_sunrise: 'Fajr',
  sunrise_to_dhuhr: 'Duha',
  dhuhr_to_asr: 'Dhuhr',
  asr_to_maghrib: 'Asr',
};

export function formatCurrentPeriod(phase: IslamicPhaseId): string {
  return PERIOD_NAMES[phase];
}

/** Display name for current sector: Jumu'ah on Fri (Duha/Midday/Dhuhr), Sunrise/Duha/Midday, or default phase label */
export function getSectorDisplayName(
  now: Date,
  currentPhase: IslamicPhaseId,
  timeline: { sunrise: Date; dhuhr: Date },
): string {
  const isFriday = now.getDay() === 5;
  if (currentPhase === 'dhuhr_to_asr' && isFriday) return "Jumu'ah";
  if (currentPhase !== 'sunrise_to_dhuhr') return formatCurrentPeriod(currentPhase);
  const sub = getSunriseToDhuhrSubPeriod(now, timeline.sunrise, timeline.dhuhr);
  if (sub === 'sunrise') return 'Sunrise';
  if (isFriday && (sub === 'duha' || sub === 'midday')) return "Jumu'ah";
  return sub === 'duha' ? 'Duha' : 'Midday';
}

export type SunriseToDhuhrSubPeriod = 'sunrise' | 'duha' | 'midday';

/** Sub-period within sunrise_to_dhuhr: SUNRISE (0–20 min), DUHA (20 min–5 min before Dhuhr), MIDDAY (last 5 min) */
export function getSunriseToDhuhrSubPeriod(
  now: Date,
  sunrise: Date,
  dhuhr: Date,
): SunriseToDhuhrSubPeriod {
  const t = now.getTime();
  const duhaStart = sunrise.getTime() + 20 * 60 * 1000;
  const duhaEnd = dhuhr.getTime() - 5 * 60 * 1000;
  if (t < duhaStart) return 'sunrise';
  if (t >= duhaEnd) return 'midday';
  return 'duha';
}

const TRANSITION_LABELS: Record<string, string> = {
  isha: 'Isha',
  islamic_midnight: 'Islamic Midnight',
  last_third_start: '2/3',
  fajr: 'Fajr',
  sunrise: 'Sunrise',
  dhuhr: 'Dhuhr',
  asr: 'Asr',
  maghrib: 'Maghrib',
};

export function formatTransition(id: string): string {
  return TRANSITION_LABELS[id] ?? id;
}
