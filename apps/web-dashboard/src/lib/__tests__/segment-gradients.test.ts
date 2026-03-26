import { describe, it, expect } from 'vitest';
import {
  getSegmentGradientStops,
  getConicGradientCss,
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

  it('returns night black for isha_to_last_third', () => {
    const stops = getSegmentGradientStops('isha_to_last_third');
    expect(stops[0].color).toBe('#000000');
    expect(stops[1].color).toBe('#000000');
  });

  it('returns stops for all segment ids', () => {
    const ids = [
      'maghrib_to_isha',
      'isha_to_last_third',
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

describe('getConicGradientCss', () => {
  const mockSegments = [
    { id: 'maghrib_to_isha', startAngleDeg: 0, endAngleDeg: 45 },
    { id: 'isha_to_last_third', startAngleDeg: 45, endAngleDeg: 90 },
    { id: 'last_third_to_fajr', startAngleDeg: 90, endAngleDeg: 180 },
    { id: 'fajr_to_sunrise', startAngleDeg: 180, endAngleDeg: 200 },
    { id: 'sunrise_to_dhuhr', startAngleDeg: 200, endAngleDeg: 300 },
    { id: 'dhuhr_to_asr', startAngleDeg: 300, endAngleDeg: 330 },
    { id: 'asr_to_maghrib', startAngleDeg: 330, endAngleDeg: 360 },
  ];

  it('returns conic-gradient CSS string', () => {
    const css = getConicGradientCss(mockSegments);
    expect(css).toMatch(/^conic-gradient\(/);
    expect(css).toContain('deg');
    expect(css.endsWith(')')).toBe(true);
  });

  it('includes color stops for full 360°', () => {
    const css = getConicGradientCss(mockSegments);
    expect(css).toContain('0deg');
    expect(css).toContain('360deg');
  });

  it('includes segment colors (maghrib red, blue, black)', () => {
    const css = getConicGradientCss(mockSegments);
    expect(css).toMatch(/rgb\(200,\s*74,\s*58\)|#C84A3A/);
    expect(css).toContain('#7CB8E8');
    expect(css).toContain('#000000');
  });

  it('uses mirror gradient when mirrorSegment provided', () => {
    const mirror: MirrorSegment = { startAngleDeg: 180, spanDeg: 90 };
    const cssWithMirror = getConicGradientCss(mockSegments, mirror);
    const cssWithoutMirror = getConicGradientCss(mockSegments);
    expect(cssWithMirror).not.toBe(cssWithoutMirror);
    expect(cssWithMirror).toContain(MIRROR_GRADIENT_PALETTE[MIRROR_GRADIENT_PALETTE.length - 1]);
  });

  it('works with null mirrorSegment', () => {
    const css = getConicGradientCss(mockSegments, null);
    expect(css).toMatch(/^conic-gradient\(/);
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
