import type { ComputedTimeline } from './types.js';
import { getCurrentPhase } from './phases.js';

/** DUHA label visibility: hidden first 20 min and last 5 min of sunrise_to_dhuhr */
const DUHA_LABEL_FIRST_MS = 20 * 60 * 1000;

/**
 * Target for countdown based on current phase and DUHA visibility.
 * - Fajr sector: countdown to DUHA label appearance (sunrise + 20 min)
 * - Sunrise_to_dhuhr, before DUHA visible: countdown to DUHA label
 * - Sunrise_to_dhuhr, DUHA visible: countdown to Dhuhr
 * - Sunrise_to_dhuhr, last 5 min (DUHA hidden): countdown to Dhuhr
 * - Dhuhr sector: countdown to Asr
 * - Asr sector: countdown to Maghrib
 * - Maghrib sector: countdown to Isha
 * - Isha sectors: countdown to Fajr
 */
export function getCountdownTarget(now: Date, timeline: ComputedTimeline): Date {
  const t = now.getTime();
  const phase = getCurrentPhase(now, timeline);
  const duhaLabelAt = timeline.sunrise.getTime() + DUHA_LABEL_FIRST_MS;

  switch (phase) {
    case 'maghrib_to_isha':
      return timeline.isha;
    case 'isha_to_midnight':
    case 'last_third_to_fajr':
      return timeline.fajr;
    case 'fajr_to_sunrise':
      return new Date(duhaLabelAt);
    case 'sunrise_to_dhuhr':
      return t < duhaLabelAt ? new Date(duhaLabelAt) : timeline.dhuhr;
    case 'dhuhr_to_asr':
      return timeline.asr;
    case 'asr_to_maghrib':
      return timeline.nextMaghrib;
    default:
      return timeline.nextMaghrib;
  }
}

/**
 * Milliseconds remaining until the countdown target.
 * Returns 0 if the target is in the past (shouldn't happen in normal flow).
 */
export function getCountdown(now: Date, targetAt: Date): number {
  return Math.max(0, targetAt.getTime() - now.getTime());
}
