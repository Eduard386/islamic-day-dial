import { describe, it, expect } from 'vitest';
import { getIslamicDayProgress, timestampToAngle, getMarkers, getRingSegments } from '../ring.js';
import type { ComputedTimeline } from '../types.js';

const lastMaghrib = new Date('2025-03-15T15:30:00.000Z');
const nextMaghrib = new Date('2025-03-16T15:30:00.000Z');

describe('getIslamicDayProgress', () => {
  it('returns 0 at lastMaghrib', () => {
    expect(getIslamicDayProgress(lastMaghrib, lastMaghrib, nextMaghrib)).toBe(0);
  });

  it('returns 1 at nextMaghrib', () => {
    expect(getIslamicDayProgress(nextMaghrib, lastMaghrib, nextMaghrib)).toBe(1);
  });

  it('returns 0.5 at midpoint', () => {
    const mid = new Date((lastMaghrib.getTime() + nextMaghrib.getTime()) / 2);
    expect(getIslamicDayProgress(mid, lastMaghrib, nextMaghrib)).toBeCloseTo(0.5, 10);
  });

  it('clamps to 0 for times before lastMaghrib', () => {
    const before = new Date(lastMaghrib.getTime() - 60000);
    expect(getIslamicDayProgress(before, lastMaghrib, nextMaghrib)).toBe(0);
  });

  it('clamps to 1 for times after nextMaghrib', () => {
    const after = new Date(nextMaghrib.getTime() + 60000);
    expect(getIslamicDayProgress(after, lastMaghrib, nextMaghrib)).toBe(1);
  });
});

describe('timestampToAngle', () => {
  it('returns 0 at lastMaghrib', () => {
    expect(timestampToAngle(lastMaghrib, lastMaghrib, nextMaghrib)).toBe(0);
  });

  it('returns 360 at nextMaghrib', () => {
    expect(timestampToAngle(nextMaghrib, lastMaghrib, nextMaghrib)).toBe(360);
  });

  it('returns 180 at midpoint', () => {
    const mid = new Date((lastMaghrib.getTime() + nextMaghrib.getTime()) / 2);
    expect(timestampToAngle(mid, lastMaghrib, nextMaghrib)).toBeCloseTo(180, 5);
  });
});

describe('getMarkers', () => {
  const timeline: ComputedTimeline = {
    lastMaghrib: new Date('2025-03-15T15:30:00.000Z'),
    isha: new Date('2025-03-15T17:00:00.000Z'),
    lastThirdStart: new Date('2025-03-15T22:30:00.000Z'),
    fajr: new Date('2025-03-16T02:00:00.000Z'),
    sunrise: new Date('2025-03-16T03:15:00.000Z'),
    duhaStart: new Date('2025-03-16T03:35:00.000Z'),
    duhaEnd: new Date('2025-03-16T09:10:00.000Z'),
    dhuhr: new Date('2025-03-16T09:15:00.000Z'),
    asr: new Date('2025-03-16T12:30:00.000Z'),
    nextMaghrib: new Date('2025-03-16T15:30:00.000Z'),
  };

  it('returns 9 markers', () => {
    const markers = getMarkers(timeline);
    expect(markers).toHaveLength(9);
  });

  it('first marker is maghrib at 0°', () => {
    const markers = getMarkers(timeline);
    expect(markers[0].id).toBe('maghrib');
    expect(markers[0].angleDeg).toBe(0);
    expect(markers[0].kind).toBe('primary');
  });

  it('markers are in ascending angle order', () => {
    const markers = getMarkers(timeline);
    for (let i = 1; i < markers.length; i++) {
      expect(markers[i].angleDeg).toBeGreaterThan(markers[i - 1].angleDeg);
    }
  });

  it('secondary markers are last_third_start, duha_start, duha_end', () => {
    const markers = getMarkers(timeline);
    const secondary = markers.filter(m => m.kind === 'secondary');
    expect(secondary.map(m => m.id)).toEqual(['last_third_start', 'duha_start', 'duha_end']);
  });
});

describe('getRingSegments', () => {
  const timeline: ComputedTimeline = {
    lastMaghrib: new Date('2025-03-15T15:30:00.000Z'),
    isha: new Date('2025-03-15T17:00:00.000Z'),
    lastThirdStart: new Date('2025-03-15T22:30:00.000Z'),
    fajr: new Date('2025-03-16T02:00:00.000Z'),
    sunrise: new Date('2025-03-16T03:15:00.000Z'),
    duhaStart: new Date('2025-03-16T03:35:00.000Z'),
    duhaEnd: new Date('2025-03-16T09:10:00.000Z'),
    dhuhr: new Date('2025-03-16T09:15:00.000Z'),
    asr: new Date('2025-03-16T12:30:00.000Z'),
    nextMaghrib: new Date('2025-03-16T15:30:00.000Z'),
  };

  it('returns 7 segments', () => {
    const segments = getRingSegments(timeline);
    expect(segments).toHaveLength(7);
  });

  it('first segment starts at 0°', () => {
    const segments = getRingSegments(timeline);
    expect(segments[0].startAngleDeg).toBe(0);
  });

  it('last segment ends at 360°', () => {
    const segments = getRingSegments(timeline);
    expect(segments[segments.length - 1].endAngleDeg).toBeCloseTo(360, 5);
  });

  it('segments are contiguous (no gaps)', () => {
    const segments = getRingSegments(timeline);
    for (let i = 1; i < segments.length; i++) {
      expect(segments[i].startAngleDeg).toBeCloseTo(segments[i - 1].endAngleDeg, 5);
    }
  });
});
