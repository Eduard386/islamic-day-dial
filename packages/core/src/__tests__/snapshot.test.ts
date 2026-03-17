import { describe, it, expect } from 'vitest';
import { computeIslamicDaySnapshot } from '../snapshot.js';
import type { UserContext, ComputedIslamicDay } from '../types.js';

const ISTANBUL: UserContext = {
  now: new Date('2024-07-15T11:00:00.000Z'), // 14:00 Istanbul (before Maghrib)
  location: { latitude: 41.0082, longitude: 28.9784 },
  timezone: 'Europe/Istanbul',
};

const MECCA_EVENING: UserContext = {
  now: new Date('2025-03-15T15:30:00.000Z'), // 18:30 Riyadh
  location: { latitude: 21.4225, longitude: 39.8262 },
  timezone: 'Asia/Riyadh',
};

function assertValidSnapshot(snapshot: ComputedIslamicDay) {
  expect(snapshot.hijriDate.day).toBeGreaterThanOrEqual(1);
  expect(snapshot.hijriDate.day).toBeLessThanOrEqual(30);
  expect(snapshot.hijriDate.monthNumber).toBeGreaterThanOrEqual(1);
  expect(snapshot.hijriDate.monthNumber).toBeLessThanOrEqual(12);
  expect(snapshot.hijriDate.year).toBeGreaterThanOrEqual(1400);
  expect(snapshot.hijriDate.monthNameEn.length).toBeGreaterThan(0);

  expect(snapshot.ring.progress).toBeGreaterThanOrEqual(0);
  expect(snapshot.ring.progress).toBeLessThanOrEqual(1);
  expect(snapshot.ring.markers).toHaveLength(8);
  expect(snapshot.ring.segments).toHaveLength(8);

  expect(snapshot.countdownMs).toBeGreaterThanOrEqual(0);
  expect(snapshot.nextTransition.id.length).toBeGreaterThan(0);
  expect(snapshot.nextTransition.at).toBeInstanceOf(Date);

  const tl = snapshot.timeline;
  expect(tl.lastMaghrib.getTime()).toBeLessThan(tl.isha.getTime());
  expect(tl.isha.getTime()).toBeLessThan(tl.islamicMidnight.getTime());
  expect(tl.islamicMidnight.getTime()).toBeLessThan(tl.lastThirdStart.getTime());
  expect(tl.lastThirdStart.getTime()).toBeLessThan(tl.fajr.getTime());
  expect(tl.fajr.getTime()).toBeLessThan(tl.sunrise.getTime());
  expect(tl.sunrise.getTime()).toBeLessThan(tl.dhuhr.getTime());
  expect(tl.dhuhr.getTime()).toBeLessThan(tl.asr.getTime());
  expect(tl.asr.getTime()).toBeLessThan(tl.nextMaghrib.getTime());
}

describe('computeIslamicDaySnapshot', () => {
  it('produces a valid snapshot for Istanbul summer afternoon', () => {
    const snapshot = computeIslamicDaySnapshot(ISTANBUL);
    assertValidSnapshot(snapshot);
    expect(snapshot.currentPhase).toBe('dhuhr_to_asr');
  });

  it('produces a valid snapshot for Mecca evening', () => {
    const snapshot = computeIslamicDaySnapshot(MECCA_EVENING);
    assertValidSnapshot(snapshot);
  });

  it('timeline markers are strictly ordered', () => {
    const snapshot = computeIslamicDaySnapshot(ISTANBUL);
    const tl = snapshot.timeline;
    const times = [
      tl.lastMaghrib, tl.isha, tl.islamicMidnight, tl.lastThirdStart,
      tl.fajr, tl.sunrise, tl.dhuhr, tl.asr, tl.nextMaghrib,
    ];
    for (let i = 1; i < times.length; i++) {
      expect(times[i].getTime()).toBeGreaterThan(times[i - 1].getTime());
    }
  });

  it('ring segments cover the full 360°', () => {
    const snapshot = computeIslamicDaySnapshot(ISTANBUL);
    const segments = snapshot.ring.segments;
    expect(segments[0].startAngleDeg).toBe(0);
    expect(segments[segments.length - 1].endAngleDeg).toBeCloseTo(360, 3);
  });

  it('ring markers first is maghrib at 0°', () => {
    const snapshot = computeIslamicDaySnapshot(ISTANBUL);
    expect(snapshot.ring.markers[0].id).toBe('maghrib');
    expect(snapshot.ring.markers[0].angleDeg).toBe(0);
  });
});
