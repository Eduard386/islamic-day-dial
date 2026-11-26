import type { HijriDate, IslamicPhaseId } from './types.js';

/** Minimal timeline slice needed for glow decisions */
export type GlowTimelineSlice = { duhaStart: Date; duhaEnd: Date; dhuhr: Date; asr: Date };

const JUMUAH_GLOW_MIN_STRENGTH = 0.3;

function isEidDay(hijriDate?: HijriDate): boolean {
  if (!hijriDate) return false;
  return (hijriDate.monthNumber === 10 && hijriDate.day === 1)
    || (hijriDate.monthNumber === 12 && hijriDate.day === 10);
}

/**
 * Special noon glow.
 * Jumu'ah: from the start of Duha until the end of Dhuhr, full strength at Dhuhr's end.
 * Eid al-Fitr and Eid al-Adha: from the start of Duha until the end of Duha.
 * On an Eid that falls on Friday, the shorter Eid window is used.
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
  const eid = isEidDay(hijriDate);
  if (!isFriday && !eid) return 0;
  if (eid) {
    if (currentPhase !== 'sunrise_to_dhuhr') return 0;
  } else if (currentPhase !== 'sunrise_to_dhuhr' && currentPhase !== 'dhuhr_to_asr') {
    return 0;
  }

  const start = timeline.duhaStart.getTime();
  const end = eid ? timeline.duhaEnd.getTime() : timeline.asr.getTime();
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

/** Night phases that show their own glow: Isha until midnight, and the last third alone. */
export const NIGHT_SECTORS_GROUP = new Set<string>(['isha_to_last_third', 'last_third_to_fajr']);

/** Is marker in Isha or Last Third (either gets night glow) */
export function isInIshaOrLastThirdSector(currentPhase: IslamicPhaseId): boolean {
  return NIGHT_SECTORS_GROUP.has(currentPhase);
}
