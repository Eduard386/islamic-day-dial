import { describe, it, expect } from 'vitest';
import {
  getSegmentGradientStops,
  getSweepSubArcs,
  MIRROR_GRADIENT_PALETTE,
  type MirrorSegment,
} from '../segment-gradients.js';

describe('getSegmentGradientStops', () => {
  it('returns gradient stops for maghrib_to_isha', () => {
    const stops = getSegmentGradientStops('maghrib_to_isha');
    expect(stops.length).toBeGreaterThan(2);
    expect(stops[0].offset).toBe(0);
    expect(stops[stops.length - 1].offset).toBe(100);
    expect(stops[0].color).toMatch(/^#|^rgb/);
  });

  it('returns single-color stops for single-color segments', () => {
    const stops = getSegmentGradientStops('sunrise_to_dhuhr');
    expect(stops).toHaveLength(2);
    expect(stops[0]).toEqual({ offset: 0, color: expect.any(String) });
    expect(stops[1]).toEqual({ offset: 100, color: expect.any(String) });
    expect(stops[0].color).toBe(stops[1].color);
  });

  it('returns night black for isha_to_midnight', () => {
    const stops = getSegmentGradientStops('isha_to_midnight');
    expect(stops[0].color).toBe('#000000');
    expect(stops[1].color).toBe('#000000');
  });

  it('returns stops for all segment ids', () => {
    const ids = [
      'maghrib_to_isha',
      'isha_to_midnight',
      'last_third_to_fajr',
      'fajr_to_sunrise',
      'sunrise_to_dhuhr',
      'dhuhr_to_asr',
      'asr_to_maghrib',
    ] as const;
    for (const id of ids) {
      const stops = getSegmentGradientStops(id);
      expect(stops.length).toBeGreaterThanOrEqual(2);
      expect(stops[0].offset).toBe(0);
      expect(stops[stops.length - 1].offset).toBe(100);
    }
  });
});

describe('getSweepSubArcs', () => {
  const mockSegments = [
    { id: 'maghrib_to_isha', startAngleDeg: 0, endAngleDeg: 45 },
    { id: 'isha_to_midnight', startAngleDeg: 45, endAngleDeg: 90 },
    { id: 'last_third_to_fajr', startAngleDeg: 90, endAngleDeg: 180 },
    { id: 'fajr_to_sunrise', startAngleDeg: 180, endAngleDeg: 200 },
    { id: 'sunrise_to_dhuhr', startAngleDeg: 200, endAngleDeg: 300 },
    { id: 'dhuhr_to_asr', startAngleDeg: 300, endAngleDeg: 330 },
    { id: 'asr_to_maghrib', startAngleDeg: 330, endAngleDeg: 360 },
  ];

  it('returns 480 sub-arcs', () => {
    const arcs = getSweepSubArcs(mockSegments);
    expect(arcs).toHaveLength(480);
  });

  it('each sub-arc has startAngleDeg, endAngleDeg, color', () => {
    const arcs = getSweepSubArcs(mockSegments);
    for (const arc of arcs) {
      expect(arc).toHaveProperty('startAngleDeg');
      expect(arc).toHaveProperty('endAngleDeg');
      expect(arc).toHaveProperty('color');
      expect(typeof arc.color).toBe('string');
      expect(arc.color).toMatch(/^rgb\(|^#/);
    }
  });

  it('sub-arcs cover full 360°', () => {
    const arcs = getSweepSubArcs(mockSegments);
    expect(arcs[0].startAngleDeg).toBe(0);
    expect(arcs[arcs.length - 1].endAngleDeg).toBe(360);
  });

  it('uses mirror gradient when mirrorSegment provided and angle in range', () => {
    const mirror: MirrorSegment = { startAngleDeg: 180, spanDeg: 90 };
    const arcs = getSweepSubArcs(mockSegments, mirror);
    const arcAtFajr = arcs.find((a) => {
      const mid = (a.startAngleDeg + a.endAngleDeg) / 2;
      return mid >= 180 && mid < 270;
    });
    expect(arcAtFajr).toBeDefined();
    expect(arcAtFajr!.color).not.toBe('#000000');
    expect(MIRROR_GRADIENT_PALETTE[0]).toBe('#000000');
    expect(MIRROR_GRADIENT_PALETTE[MIRROR_GRADIENT_PALETTE.length - 1]).toBe('#7CB8E8');
  });

  it('uses segment palette when outside mirror range', () => {
    const mirror: MirrorSegment = { startAngleDeg: 180, spanDeg: 90 };
    const arcs = getSweepSubArcs(mockSegments, mirror);
    const arcAtTop = arcs[0];
    const mid = (arcAtTop.startAngleDeg + arcAtTop.endAngleDeg) / 2;
    expect(mid).toBeLessThan(180);
    expect(arcAtTop.color).toBeDefined();
  });

  it('works with null mirrorSegment', () => {
    const arcs = getSweepSubArcs(mockSegments, null);
    expect(arcs).toHaveLength(480);
  });
});

describe('MIRROR_GRADIENT_PALETTE', () => {
  it('starts with black', () => {
    expect(MIRROR_GRADIENT_PALETTE[0]).toBe('#000000');
  });

  it('ends with blue', () => {
    expect(MIRROR_GRADIENT_PALETTE[MIRROR_GRADIENT_PALETTE.length - 1]).toBe('#7CB8E8');
  });

  it('has valid hex colors throughout', () => {
    for (const c of MIRROR_GRADIENT_PALETTE) {
      expect(c).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});
