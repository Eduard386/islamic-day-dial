import type { IslamicPhaseId } from '@islamic-day-dial/core';

type GradientDef = { stops: Array<{ offset: number; color: string }> };

function g(start: string, end: string): GradientDef {
  return { stops: [{ offset: 0, color: start }, { offset: 100, color: end }] };
}

/**
 * Dark blue ↔ Yellow, with black night at Isha and Fajr:
 * - Fajr: gradient from black night
 * - Isha: gradient into black night
 */
const NIGHT = '#0a0a12';
const BLUE_MID = '#3b82a8';
const YELLOW = '#eab308';

/** Day segments: night→blue→yellow | yellow→blue→night */
export const SEGMENT_GRADIENTS: Record<IslamicPhaseId, GradientDef> = {
  fajr_to_sunrise: g(NIGHT, BLUE_MID),
  sunrise_to_dhuhr: g(BLUE_MID, YELLOW),
  dhuhr_to_asr: g(YELLOW, YELLOW),
  asr_to_maghrib: g(YELLOW, BLUE_MID),
  maghrib_to_isha: g(BLUE_MID, NIGHT),
  isha_to_midnight: g(NIGHT, NIGHT),
  midnight_to_last_third: g(NIGHT, NIGHT),
  last_third_to_fajr: g(NIGHT, NIGHT),
};

/** Active variants — slightly brighter */
const YELLOW_ACTIVE = '#fde047';
const BLUE_MID_ACTIVE = '#5ba3d4';

export const SEGMENT_GRADIENTS_ACTIVE: Record<IslamicPhaseId, GradientDef> = {
  fajr_to_sunrise: g(NIGHT, BLUE_MID_ACTIVE),
  sunrise_to_dhuhr: g(BLUE_MID_ACTIVE, YELLOW_ACTIVE),
  dhuhr_to_asr: g(YELLOW_ACTIVE, YELLOW_ACTIVE),
  asr_to_maghrib: g(YELLOW_ACTIVE, BLUE_MID_ACTIVE),
  maghrib_to_isha: g(BLUE_MID_ACTIVE, NIGHT),
  isha_to_midnight: g(NIGHT, NIGHT),
  midnight_to_last_third: g(NIGHT, NIGHT),
  last_third_to_fajr: g(NIGHT, NIGHT),
};
