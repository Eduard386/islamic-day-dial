import type { ComputedTimeline } from './types.js';
import { getCurrentPhase } from './phases.js';
import { getSunriseToDhuhrSubPeriod } from './formatting.js';

/**
 * Target for countdown: always the start of the next sector.
 * - Fajr: → Sunrise
 * - Sunrise (sub): → Duha
 * - Duha (sub): → Midday
 * - Midday (sub): → Dhuhr
 * - Dhuhr: → Asr
 * - Asr: → Maghrib
 * - Maghrib: → Isha
 * - Isha / Last third: → Fajr
 */
export function getCountdownTarget(now: Date, timeline: ComputedTimeline): Date {
  const phase = getCurrentPhase(now, timeline);

  switch (phase) {
    case 'maghrib_to_isha':
      return timeline.isha;
    case 'isha_to_last_third':
    case 'last_third_to_fajr':
      return timeline.fajr;
    case 'fajr_to_sunrise':
      return timeline.sunrise;
    case 'sunrise_to_dhuhr': {
      const sub = getSunriseToDhuhrSubPeriod(now, timeline.duhaStart, timeline.dhuhr);
      if (sub === 'sunrise') return timeline.duhaStart;
      if (sub === 'duha') return timeline.duhaEnd;
      return timeline.dhuhr;
    }
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
