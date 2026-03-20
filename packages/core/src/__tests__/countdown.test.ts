import { describe, it, expect } from 'vitest';
import { getCountdown, getCountdownTarget } from '../countdown.js';
import type { ComputedTimeline } from '../types.js';

function makeTimeline(entries: Record<string, number>): ComputedTimeline {
  const toDate = (ms: number) => new Date(ms);
  const sunrise = entries.sunrise ?? 0;
  const dhuhr = entries.dhuhr ?? 0;
  return {
    lastMaghrib: toDate(entries.lastMaghrib ?? 0),
    isha: toDate(entries.isha ?? 0),
    islamicMidnight: toDate(entries.islamicMidnight ?? 0),
    lastThirdStart: toDate(entries.lastThirdStart ?? 0),
    fajr: toDate(entries.fajr ?? 0),
    sunrise: toDate(sunrise),
    duhaStart: toDate(sunrise + 20 * 60 * 1000),
    duhaEnd: toDate(dhuhr - 5 * 60 * 1000),
    dhuhr: toDate(dhuhr),
    asr: toDate(entries.asr ?? 0),
    nextMaghrib: toDate(entries.nextMaghrib ?? 0),
  };
}

describe('getCountdownTarget', () => {
  it('Fajr sector: target is DUHA label (sunrise + 20 min)', () => {
    const sunrise = 100000;
    const dhuhr = 200000;
    const tl = makeTimeline({
      fajr: 80000, sunrise, dhuhr,
      lastMaghrib: 0, isha: 10000, islamicMidnight: 20000, lastThirdStart: 30000,
      asr: 250000, nextMaghrib: 300000,
    });
    const now = new Date(90000); // in fajr_to_sunrise
    const target = getCountdownTarget(now, tl);
    expect(target.getTime()).toBe(sunrise + 20 * 60 * 1000);
  });

  it('Maghrib sector: target is Isha', () => {
    const isha = 50000;
    const tl = makeTimeline({
      lastMaghrib: 0, isha, islamicMidnight: 60000, lastThirdStart: 70000,
      fajr: 80000, sunrise: 100000, dhuhr: 150000, asr: 200000, nextMaghrib: 300000,
    });
    const now = new Date(25000); // in maghrib_to_isha
    const target = getCountdownTarget(now, tl);
    expect(target.getTime()).toBe(isha);
  });

  it('Isha sectors: target is Fajr', () => {
    const fajr = 80000;
    const tl = makeTimeline({
      lastMaghrib: 0, isha: 10000, islamicMidnight: 20000, lastThirdStart: 30000,
      fajr, sunrise: 100000, dhuhr: 150000, asr: 200000, nextMaghrib: 300000,
    });
    const now = new Date(25000); // in isha_to_midnight
    const target = getCountdownTarget(now, tl);
    expect(target.getTime()).toBe(fajr);
  });
});

describe('getCountdown', () => {
  it('returns positive ms when transition is in the future', () => {
    const now = new Date('2025-03-15T15:00:00.000Z');
    const next = new Date('2025-03-15T16:00:00.000Z');
    expect(getCountdown(now, next)).toBe(3600000); // 1 hour
  });

  it('returns 0 when transition is exactly now', () => {
    const now = new Date('2025-03-15T15:00:00.000Z');
    expect(getCountdown(now, now)).toBe(0);
  });

  it('returns 0 when transition is in the past', () => {
    const now = new Date('2025-03-15T16:00:00.000Z');
    const past = new Date('2025-03-15T15:00:00.000Z');
    expect(getCountdown(now, past)).toBe(0);
  });
});
