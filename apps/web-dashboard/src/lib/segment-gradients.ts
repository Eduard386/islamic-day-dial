import type { IslamicPhaseId } from '@islamic-day-dial/core';

type GradientDef = { stops: Array<{ offset: number; color: string }> };

function g(start: string, end: string): GradientDef {
  return { stops: [{ offset: 0, color: start }, { offset: 100, color: end }] };
}

function g3(start: string, mid: string, end: string): GradientDef {
  return { stops: [{ offset: 0, color: start }, { offset: 50, color: mid }, { offset: 100, color: end }] };
}

/** Smooth 4-stop gradient for softer transitions at segment boundaries */
function g4(start: string, q1: string, q2: string, end: string): GradientDef {
  return {
    stops: [
      { offset: 0, color: start },
      { offset: 33, color: q1 },
      { offset: 66, color: q2 },
      { offset: 100, color: end },
    ],
  };
}


/**
 * Phase colors (clockwise from Maghrib):
 * Fajr → Sunrise: black (night) → blue
 * Sunrise → Dhuhr: blue → green
 * Dhuhr → Asr: green → yellow
 * Asr → Maghrib: yellow → orange
 * Maghrib → Isha: orange → purple → black (night)
 */
const NIGHT = '#0a0a12';     // black as night — Fajr start, Isha end
const BLUE = '#38bdf8';      // end Fajr / start Sunrise
const GREEN = '#22c55e';     // end Sunrise / start Dhuhr
const YELLOW = '#eab308';    // end Dhuhr / start Asr
const ORANGE = '#f97316';    // end Asr / start Maghrib
const PURPLE = '#a855f7';    // end Maghrib / start Isha

const ANCHORS: Record<string, string> = {
  maghrib: ORANGE,
  isha: PURPLE,
  mid: NIGHT,
  last3rd: NIGHT,
  fajr: NIGHT,
  sunrise: BLUE,
  dhuhr: GREEN,
  asr: YELLOW,
};

const ANCHORS_ACTIVE: Record<string, string> = {
  maghrib: '#fb923c',
  isha: '#c084fc',
  mid: '#1a1a2e',
  last3rd: '#1a1a2e',
  fajr: '#1a1a2e',
  sunrise: '#7dd3fc',
  dhuhr: '#4ade80',
  asr: '#fde047',
};

/* Intermediate colors for smooth transitions (avoid sharp boundaries) */
const GREEN_YELLOW = '#7ed34d';   // blend green→yellow
const YELLOW_GREEN = '#b8e62e';   // blend green→yellow
const YELLOW_ORANGE = '#f0b010'; // blend yellow→orange
const ORANGE_YELLOW = '#f5a623'; // blend yellow→orange
const ORANGE_PURPLE = '#e07a5a'; // blend orange→purple (lighter, no dark streak)
const PURPLE_ORANGE = '#c45a9d'; // blend orange→purple

export const SEGMENT_GRADIENTS: Record<IslamicPhaseId, GradientDef> = {
  maghrib_to_isha: g4(ANCHORS.maghrib, ORANGE_PURPLE, PURPLE_ORANGE, ANCHORS.isha),
  isha_to_midnight: g(ANCHORS.isha, ANCHORS.mid),
  midnight_to_last_third: g(ANCHORS.mid, ANCHORS.last3rd),
  last_third_to_fajr: g(ANCHORS.last3rd, ANCHORS.fajr),
  fajr_to_sunrise: g(ANCHORS.fajr, ANCHORS.sunrise),
  sunrise_to_dhuhr: g(ANCHORS.sunrise, ANCHORS.dhuhr),
  dhuhr_to_asr: g4(ANCHORS.dhuhr, GREEN_YELLOW, YELLOW_GREEN, ANCHORS.asr),
  asr_to_maghrib: g4(ANCHORS.asr, YELLOW_ORANGE, ORANGE_YELLOW, ANCHORS.maghrib),
};

export const SEGMENT_GRADIENTS_ACTIVE: Record<IslamicPhaseId, GradientDef> = {
  maghrib_to_isha: g4(ANCHORS_ACTIVE.maghrib, '#e07a6b', '#c96b9a', ANCHORS_ACTIVE.isha),
  isha_to_midnight: g(ANCHORS_ACTIVE.isha, ANCHORS_ACTIVE.mid),
  midnight_to_last_third: g(ANCHORS_ACTIVE.mid, ANCHORS_ACTIVE.last3rd),
  last_third_to_fajr: g(ANCHORS_ACTIVE.last3rd, ANCHORS_ACTIVE.fajr),
  fajr_to_sunrise: g(ANCHORS_ACTIVE.fajr, ANCHORS_ACTIVE.sunrise),
  sunrise_to_dhuhr: g(ANCHORS_ACTIVE.sunrise, ANCHORS_ACTIVE.dhuhr),
  dhuhr_to_asr: g4(ANCHORS_ACTIVE.dhuhr, '#8ee85a', '#c8f050', ANCHORS_ACTIVE.asr),
  asr_to_maghrib: g4(ANCHORS_ACTIVE.asr, '#f5c230', '#f9a825', ANCHORS_ACTIVE.maghrib),
};
