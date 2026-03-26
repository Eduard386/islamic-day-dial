import type { IslamicPhaseId } from './types.js';
import { getSunriseToDhuhrSubPeriod } from './formatting.js';

/** Minimal timeline slice needed for glow decisions */
export type GlowTimelineSlice = { duhaStart: Date; dhuhr: Date };

/**
 * Jumu'ah (Friday): glow shown only when marker is in DUHA, MIDDAY or DHUHR.
 * Not during SUNRISE, Fajr, night (Maghrib…Last 3rd), Asr→Maghrib.
 */
export function isJumuahGlowWindow(
  now: Date,
  timeline: GlowTimelineSlice,
  currentPhase: IslamicPhaseId,
): boolean {
  if (now.getDay() !== 5) return false;
  if (currentPhase === 'dhuhr_to_asr') return true;
  if (currentPhase === 'sunrise_to_dhuhr') {
    const sub = getSunriseToDhuhrSubPeriod(now, timeline.duhaStart, timeline.dhuhr);
    return sub === 'duha' || sub === 'midday';
  }
  return false;
}

/** When marker is in last third of night: last-third pulsating glow */
export function isLastThirdPhase(currentPhase: IslamicPhaseId): boolean {
  return currentPhase === 'last_third_to_fajr';
}

/** When marker is in Isha sector: both Isha and Last Third segments get glow */
export const NIGHT_SECTORS_GROUP = new Set<string>(['isha_to_last_third', 'last_third_to_fajr']);

/** Is marker in Isha or Last Third (either gets night glow) */
export function isInIshaOrLastThirdSector(currentPhase: IslamicPhaseId): boolean {
  return NIGHT_SECTORS_GROUP.has(currentPhase);
}
