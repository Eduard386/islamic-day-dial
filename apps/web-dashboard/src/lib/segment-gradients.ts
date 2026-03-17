import type { IslamicPhaseId } from '@islamic-day-dial/core';

type GradientDef = { stops: Array<{ offset: number; color: string }> };

function g(start: string, end: string): GradientDef {
  return { stops: [{ offset: 0, color: start }, { offset: 100, color: end }] };
}

/**
 * Anchor colors at boundaries (clockwise):
 * Isha darkens to Midnight (DARK) = same as Fajr start.
 * Fajr: DARK → BLUE. Sunrise: BLUE → YELLOW. Dhuhr: YELLOW → GREEN.
 * Asr: GREEN → PINK. Maghrib: PINK → PURPLE. Isha: PURPLE → DARK.
 */
const DARK = '#0f172a';      // end Isha / start Fajr
const BLUE = '#38bdf8';      // end Fajr / start Sunrise
const YELLOW = '#eab308';    // end Sunrise / start Dhuhr
const GREEN = '#22c55e';     // end Dhuhr / start Asr
const PINK = '#c9a8b8';      // dusty rose / mauve — end Asr / start Maghrib
const PURPLE = '#9d8bb8';   // mauve — end Maghrib / start Isha (softer transition)

const ANCHORS: Record<string, string> = {
  maghrib: PINK,
  isha: PURPLE,
  mid: DARK,
  last3rd: DARK,
  fajr: DARK,
  sunrise: BLUE,
  dhuhr: YELLOW,
  asr: GREEN,
};

const ANCHORS_ACTIVE: Record<string, string> = {
  maghrib: '#d4b8c8',
  isha: '#b09fc8',
  mid: '#1e293b',
  last3rd: '#1e293b',
  fajr: '#1e293b',
  sunrise: '#7dd3fc',
  dhuhr: '#fde047',
  asr: '#4ade80',
};

export const SEGMENT_GRADIENTS: Record<IslamicPhaseId, GradientDef> = {
  maghrib_to_isha: g(ANCHORS.maghrib, ANCHORS.isha),
  isha_to_midnight: g(ANCHORS.isha, ANCHORS.mid),
  midnight_to_last_third: g(ANCHORS.mid, ANCHORS.last3rd),
  last_third_to_fajr: g(ANCHORS.last3rd, ANCHORS.fajr),
  fajr_to_sunrise: g(ANCHORS.fajr, ANCHORS.sunrise),
  sunrise_to_dhuhr: g(ANCHORS.sunrise, ANCHORS.dhuhr),
  dhuhr_to_asr: g(ANCHORS.dhuhr, ANCHORS.asr),
  asr_to_maghrib: g(ANCHORS.asr, ANCHORS.maghrib),
};

export const SEGMENT_GRADIENTS_ACTIVE: Record<IslamicPhaseId, GradientDef> = {
  maghrib_to_isha: g(ANCHORS_ACTIVE.maghrib, ANCHORS_ACTIVE.isha),
  isha_to_midnight: g(ANCHORS_ACTIVE.isha, ANCHORS_ACTIVE.mid),
  midnight_to_last_third: g(ANCHORS_ACTIVE.mid, ANCHORS_ACTIVE.last3rd),
  last_third_to_fajr: g(ANCHORS_ACTIVE.last3rd, ANCHORS_ACTIVE.fajr),
  fajr_to_sunrise: g(ANCHORS_ACTIVE.fajr, ANCHORS_ACTIVE.sunrise),
  sunrise_to_dhuhr: g(ANCHORS_ACTIVE.sunrise, ANCHORS_ACTIVE.dhuhr),
  dhuhr_to_asr: g(ANCHORS_ACTIVE.dhuhr, ANCHORS_ACTIVE.asr),
  asr_to_maghrib: g(ANCHORS_ACTIVE.asr, ANCHORS_ACTIVE.maghrib),
};
