import type { HijriDate, IslamicPhaseId } from './types.js';

export function formatHijriDate(date: HijriDate): string {
  return `${date.day} ${date.monthNameEn} ${date.year}`;
}

export function formatCountdown(ms: number): string {
  if (ms <= 0) return '00:00:00';
  const totalSeconds = Math.floor(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  return (
    String(hours).padStart(2, '0') +
    ':' +
    String(minutes).padStart(2, '0') +
    ':' +
    String(seconds).padStart(2, '0')
  );
}

const PHASE_LABELS: Record<IslamicPhaseId, string> = {
  maghrib_to_isha: 'Maghrib → Isha',
  isha_to_midnight: 'Isha → Midnight',
  midnight_to_last_third: 'Midnight → Last Third',
  last_third_to_fajr: 'Last Third → Fajr',
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
  midnight_to_last_third: 'Night',
  last_third_to_fajr: 'Last Third',
  fajr_to_sunrise: 'Fajr',
  sunrise_to_dhuhr: 'Sunrise',
  dhuhr_to_asr: 'Dhuhr',
  asr_to_maghrib: 'Asr',
};

export function formatCurrentPeriod(phase: IslamicPhaseId): string {
  return PERIOD_NAMES[phase];
}

const TRANSITION_LABELS: Record<string, string> = {
  isha: 'Isha',
  islamic_midnight: 'Islamic Midnight',
  last_third_start: 'Last Third',
  fajr: 'Fajr',
  sunrise: 'Sunrise',
  dhuhr: 'Dhuhr',
  asr: 'Asr',
  maghrib: 'Maghrib',
};

export function formatTransition(id: string): string {
  return TRANSITION_LABELS[id] ?? id;
}
