import type { IslamicPhaseId } from '@islamic-day-dial/core';

export type GradientStop = { offset: number; color: string };

/**
 * Sky colors for Islamic day ring.
 * Asr, Maghrib, Isha — unchanged.
 * Mirror segment: from Fajr for (Asr→Isha) duration, gradient red→blue (reverse of Asr→Isha).
 * Rest of Fajr/Sunrise/Duha: black→blue then flat blue.
 */
const NIGHT_BLACK = '#000000';
const SUNSET_RED = '#C84A3A';
const DHUHR_END_BLUE = '#7CB8E8';

/** Mirror of Asr→Isha: black → yellow → blue (smooth fade out of night) */
export const MIRROR_GRADIENT_PALETTE = [
  NIGHT_BLACK,
  '#080808',
  '#181408',
  '#282008',
  '#383008',
  '#484018',
  '#585028',
  '#706038',
  '#887040',
  '#A08048',
  '#B89050',
  '#D0A858',
  '#E8C060',
  '#E8D070',
  '#D8D080',
  '#C8D090',
  '#B8D0A0',
  '#A8D0B0',
  '#98D0C0',
  '#88D0D0',
  '#78D0E0',
  '#70C8E4',
  '#74C4E8',
  DHUHR_END_BLUE,
];

/** Maghrib → Isha: red sunset → black night (unchanged) */
const MAGHRIB_PALETTE = [
  SUNSET_RED,
  '#B04038',
  '#983634',
  '#802C30',
  '#68242C',
  '#501C28',
  '#381420',
  '#200C18',
  '#080408',
  NIGHT_BLACK,
];

/** Fajr → Sunrise: тёмная часть дольше (как в реальности — небо тёмное большую часть фаджра) */
const FAJR_SUNRISE_PALETTE = [
  /* 0–45%: глубокий мрак, почти без изменений */
  NIGHT_BLACK,
  '#000208',
  '#00040C',
  '#000610',
  '#000814',
  '#000A18',
  '#000C1C',
  '#000E20',
  '#001024',
  '#001228',
  '#00142C',
  '#001630',
  '#001834',
  '#081C38',
  '#10203C',
  '#182440',
  /* 45–75%: переход из тёмно-синего */
  '#204050',
  '#284860',
  '#305070',
  '#385880',
  '#406090',
  '#4868A0',
  '#5070B0',
  '#5878C0',
  '#6080D0',
  /* 75–100%: рассветный свет */
  '#68A0E0',
  '#70B0E8',
  '#74BCE8',
  DHUHR_END_BLUE,
];

/** Sunrise → Duha → Midday → Dhuhr: flat blue */
const SUNRISE_TO_DHUHR_PALETTE = [DHUHR_END_BLUE];

/** Dhuhr → Asr: blue bridge */
const DHUHR_ASR_PALETTE = [DHUHR_END_BLUE];

/** Asr: blue (as Dhuhr end) → red sunset Maghrib */
const ASR_PALETTE = [
  DHUHR_END_BLUE,
  '#78B0E0',
  '#80A8D8',
  '#88A0D0',
  '#9098C8',
  '#9890C0',
  '#A088B8',
  '#A880A8',
  '#B07898',
  '#B87088',
  '#C06878',
  '#C86068',
  '#D05858',
  '#D85048',
  SUNSET_RED,
];

function getPaletteForSegment(id: IslamicPhaseId): string[] {
  switch (id) {
    case 'maghrib_to_isha':
      return MAGHRIB_PALETTE;
    case 'isha_to_midnight':
      return [NIGHT_BLACK];
    case 'last_third_to_fajr':
      return [NIGHT_BLACK];
    case 'fajr_to_sunrise':
      return FAJR_SUNRISE_PALETTE;
    case 'sunrise_to_dhuhr':
      return SUNRISE_TO_DHUHR_PALETTE;
    case 'dhuhr_to_asr':
      return DHUHR_ASR_PALETTE;
    case 'asr_to_maghrib':
      return ASR_PALETTE;
    default:
      return [NIGHT_BLACK];
  }
}

/**
 * Per-segment gradient stops. Used for Jumu'ah glow.
 */
export function getSegmentGradientStops(
  segmentId: IslamicPhaseId,
): GradientStop[] {
  const palette = getPaletteForSegment(segmentId);
  if (palette.length === 0) {
    return [{ offset: 0, color: NIGHT_BLACK }, { offset: 100, color: NIGHT_BLACK }];
  }
  if (palette.length === 1) {
    return [{ offset: 0, color: palette[0] }, { offset: 100, color: palette[0] }];
  }
  return palette.map((color, i) => ({
    offset: (i / (palette.length - 1)) * 100,
    color,
  }));
}

/** Sub-arc for sweep rendering: solid color along the arc */
export type SweepSubArc = { startAngleDeg: number; endAngleDeg: number; color: string };

const SUB_ARCS_PER_RING = 480;

function lerpColor(a: string, b: string, t: number): string {
  const parse = (hex: string) => {
    const n = parseInt(hex.slice(1), 16);
    return { r: (n >> 16) & 0xff, g: (n >> 8) & 0xff, b: n & 0xff };
  };
  const ca = parse(a);
  const cb = parse(b);
  return `rgb(${Math.round(ca.r + (cb.r - ca.r) * t)},${Math.round(ca.g + (cb.g - ca.g) * t)},${Math.round(ca.b + (cb.b - ca.b) * t)})`;
}

function isInAngleRange(angle: number, startDeg: number, spanDeg: number): boolean {
  const diff = (angle - startDeg + 360) % 360;
  return diff < spanDeg;
}

export type MirrorSegment = {
  startAngleDeg: number;
  spanDeg: number;
};

/**
 * Returns sub-arcs for the full ring. Color varies along the arc (sweep), no triangle, no seams.
 * If mirrorSegment is provided, sub-arcs within that range use the mirror gradient (red→blue).
 */
export function getSweepSubArcs(
  segments: Array<{ id: string; startAngleDeg: number; endAngleDeg: number }>,
  mirrorSegment?: MirrorSegment | null,
): SweepSubArc[] {
  const result: SweepSubArc[] = [];
  const step = 360 / SUB_ARCS_PER_RING;
  for (let i = 0; i < SUB_ARCS_PER_RING; i++) {
    const startAngle = i * step;
    const endAngle = (i + 1) * step;
    const midAngle = (startAngle + endAngle) / 2;

    let color: string;
    if (mirrorSegment && isInAngleRange(midAngle, mirrorSegment.startAngleDeg, mirrorSegment.spanDeg)) {
      const t = mirrorSegment.spanDeg > 0
        ? ((midAngle - mirrorSegment.startAngleDeg + 360) % 360) / mirrorSegment.spanDeg
        : 0;
      const clampedT = Math.max(0, Math.min(1, t));
      const palette = MIRROR_GRADIENT_PALETTE;
      const idx = clampedT * (palette.length - 1);
      const i0 = Math.floor(idx);
      const i1 = Math.min(i0 + 1, palette.length - 1);
      color = lerpColor(palette[i0], palette[i1], idx - i0);
    } else {
      const seg = segments.find((s) => {
        if (s.endAngleDeg <= 360) {
          return midAngle >= s.startAngleDeg && midAngle < s.endAngleDeg;
        }
        // Wrapping segment (endAngleDeg > 360): covers [start, 360) ∪ [0, end - 360)
        return (midAngle >= s.startAngleDeg && midAngle < 360) ||
          (midAngle >= 0 && midAngle < s.endAngleDeg - 360);
      });
      const palette = seg ? getPaletteForSegment(seg.id as IslamicPhaseId) : [NIGHT_BLACK];
      const span = seg ? seg.endAngleDeg - seg.startAngleDeg : 360;
      let t = 0;
      if (seg && span > 0) {
        if (seg.endAngleDeg <= 360) {
          t = (midAngle - seg.startAngleDeg) / span;
        } else {
          const wrapEnd = seg.endAngleDeg - 360;
          t = midAngle >= seg.startAngleDeg
            ? (midAngle - seg.startAngleDeg) / span
            : (360 - seg.startAngleDeg + midAngle) / span;
        }
        t = Math.max(0, Math.min(1, t));
      }
      const idx = t * (palette.length - 1);
      const i0 = Math.floor(idx);
      const i1 = Math.min(i0 + 1, palette.length - 1);
      color = palette.length === 1 ? palette[0] : lerpColor(palette[i0], palette[i1], idx - i0);
    }
    result.push({ startAngleDeg: startAngle, endAngleDeg: endAngle, color });
  }
  return result;
}

