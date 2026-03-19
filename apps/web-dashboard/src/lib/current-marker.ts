import type { IslamicPhaseId, HijriDate } from '@islamic-day-dial/core';
import { getMoonPhaseByHijriDay as getMoonPhase, type MoonPhaseParams } from './moon-phases.js';

/**
 * Night period: between Maghrib and Fajr (sunset to dawn).
 */
const NIGHT_PHASES: Set<IslamicPhaseId> = new Set([
  'maghrib_to_isha',
  'isha_to_midnight',
  'last_third_to_fajr',
]);

export function isNightPeriod(currentPhase: IslamicPhaseId): boolean {
  return NIGHT_PHASES.has(currentPhase);
}

export { getMoonPhaseByHijriDay } from './moon-phases.js';
export type { MoonPhaseParams, MoonPhaseId } from './moon-phases.js';

export type CurrentMarkerState = {
  isNight: boolean;
  /** Only meaningful when isNight */
  moonPhase: MoonPhaseParams | null;
  /** For debug override */
  hijriDayUsed: number;
};

export function getCurrentMarkerVisualState(
  currentPhase: IslamicPhaseId,
  hijriDate: HijriDate,
  debugHijriDay?: number,
): CurrentMarkerState {
  const isNight = isNightPeriod(currentPhase);
  const hijriDayUsed = debugHijriDay ?? hijriDate.day;
  return {
    isNight,
    moonPhase: isNight ? getMoonPhase(hijriDayUsed) : null,
    hijriDayUsed,
  };
}
