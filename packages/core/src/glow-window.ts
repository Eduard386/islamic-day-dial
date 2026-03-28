import type { HijriDate, IslamicPhaseId } from './types.js';

/** Minimal timeline slice needed for glow decisions */
export type GlowTimelineSlice = { duhaStart: Date; dhuhr: Date; asr: Date };

const JUMUAH_GLOW_MIN_STRENGTH = 0.3;

function isEidDay(hijriDate?: HijriDate): boolean {
  if (!hijriDate) return false;
  return (hijriDate.monthNumber === 10 && hijriDate.day === 1)
    || (hijriDate.monthNumber === 12 && hijriDate.day === 10);
}

/**
 * Special noon glow (Jumu'ah / Eid): shown from the start of Duha until the end of Dhuhr.
 * It starts weak at Duha and reaches full strength by the end of Dhuhr.
 */
export function isJumuahGlowWindow(
  now: Date,
  timeline: GlowTimelineSlice,
  currentPhase: IslamicPhaseId,
  hijriDate?: HijriDate,
): boolean {
  return getJumuahGlowStrength(now, timeline, currentPhase, hijriDate) > 0;
}

export function getJumuahGlowStrength(
  now: Date,
  timeline: GlowTimelineSlice,
  currentPhase: IslamicPhaseId,
  hijriDate?: HijriDate,
): number {
  const isFriday = now.getDay() === 5;
  if (!isFriday && !isEidDay(hijriDate)) return 0;
  if (currentPhase !== 'sunrise_to_dhuhr' && currentPhase !== 'dhuhr_to_asr') return 0;

  const start = timeline.duhaStart.getTime();
  const end = timeline.asr.getTime();
  const current = now.getTime();

  if (current < start || current >= end) return 0;
  if (end <= start) return 1;

  const progress = Math.max(0, Math.min(1, (current - start) / (end - start)));
  return JUMUAH_GLOW_MIN_STRENGTH + (1 - JUMUAH_GLOW_MIN_STRENGTH) * progress;
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
