/**
 * Artistic moon phase scheme by hijri day (1–30).
 * Implemented via overlapping circles — no bitmaps.
 *
 * Shadow offset: position of shadow center in radius units.
 * Positive = shadow right (lit left, waxing); negative = shadow left (lit right, waning).
 * 1 = half moon (first quarter), -1 = half moon (last quarter), 0 = full.
 * ~0.18 = very thin crescent; ~-0.18 = very thin waning (end of month).
 */

export type MoonPhaseId =
  | 'very_thin_waxing_crescent'   // 1–3
  | 'waxing_crescent'             // 4–7
  | 'first_quarter'               // 8–10
  | 'waxing_gibbous'              // 11–13
  | 'full'                        // 14–16
  | 'waning_gibbous'              // 17–20
  | 'last_quarter'                // 21–23
  | 'waning_crescent'             // 24–27
  | 'very_thin_waning_crescent';  // 28–30

export type MoonPhaseParams = {
  id: MoonPhaseId;
  /** Shadow circle offset in radius units. Positive = shadow right (lit left, waxing). */
  shadowOffset: number;
};

const PHASE_RANGES: Array<{ id: MoonPhaseId; range: [number, number] }> = [
  { id: 'very_thin_waxing_crescent', range: [1, 3] },
  { id: 'waxing_crescent', range: [4, 7] },
  { id: 'first_quarter', range: [8, 10] },
  { id: 'waxing_gibbous', range: [11, 13] },
  { id: 'full', range: [14, 16] },
  { id: 'waning_gibbous', range: [17, 20] },
  { id: 'last_quarter', range: [21, 23] },
  { id: 'waning_crescent', range: [24, 27] },
  { id: 'very_thin_waning_crescent', range: [28, 30] },
];

/** Waxing: lit on right (negative) = growing. Waning: lit on left (positive) = aging. */
const PHASE_OFFSETS: Record<MoonPhaseId, number> = {
  very_thin_waxing_crescent: -0.18,
  waxing_crescent: -0.5,
  first_quarter: -1.0,
  waxing_gibbous: -1.35,
  full: 0,
  waning_gibbous: 1.35,
  last_quarter: 1.0,
  waning_crescent: 0.5,
  very_thin_waning_crescent: 0.18,
};

export function getMoonPhaseByHijriDay(day: number): MoonPhaseParams {
  const d = Math.max(1, Math.min(30, Math.floor(day)));

  for (const { id, range } of PHASE_RANGES) {
    if (d >= range[0] && d <= range[1]) {
      return { id, shadowOffset: PHASE_OFFSETS[id] };
    }
  }

  return { id: 'full', shadowOffset: 0 };
}
