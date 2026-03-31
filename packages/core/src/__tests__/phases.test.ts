import { describe, it, expect } from 'vitest';
import { getCurrentPhase, getNextTransition } from '../phases.js';
import type { ComputedTimeline } from '../types.js';

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

describe('getCurrentPhase', () => {
  it('returns maghrib_to_isha right after Maghrib', () => {
    const now = new Date('2025-03-15T15:31:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('maghrib_to_isha');
  });

  it('returns isha_to_last_third after Isha', () => {
    const now = new Date('2025-03-15T17:30:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('isha_to_last_third');
  });

  it('returns isha_to_last_third until last third start', () => {
    const now = new Date('2025-03-15T21:00:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('isha_to_last_third');
  });

  it('returns last_third_to_fajr after last third start', () => {
    const now = new Date('2025-03-15T23:00:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('last_third_to_fajr');
  });

  it('returns fajr_to_sunrise after Fajr', () => {
    const now = new Date('2025-03-16T02:30:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('fajr_to_sunrise');
  });

  it('returns sunrise_to_dhuhr after Sunrise', () => {
    const now = new Date('2025-03-16T05:00:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('sunrise_to_dhuhr');
  });

  it('returns dhuhr_to_asr after Dhuhr', () => {
    const now = new Date('2025-03-16T10:00:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('dhuhr_to_asr');
  });

  it('returns asr_to_maghrib after Asr', () => {
    const now = new Date('2025-03-16T13:00:00.000Z');
    expect(getCurrentPhase(now, timeline)).toBe('asr_to_maghrib');
  });

  it('returns maghrib_to_isha exactly at Maghrib', () => {
    expect(getCurrentPhase(timeline.lastMaghrib, timeline)).toBe('maghrib_to_isha');
  });

  it('returns isha_to_last_third exactly at Isha', () => {
    expect(getCurrentPhase(timeline.isha, timeline)).toBe('isha_to_last_third');
  });
});

describe('getNextTransition', () => {
  it('returns Isha when in maghrib_to_isha phase', () => {
    const now = new Date('2025-03-15T16:00:00.000Z');
    const result = getNextTransition(now, timeline);
    expect(result.id).toBe('isha');
    expect(result.at).toEqual(timeline.isha);
  });

  it('returns Fajr when in last_third_to_fajr phase', () => {
    const now = new Date('2025-03-16T01:00:00.000Z');
    const result = getNextTransition(now, timeline);
    expect(result.id).toBe('fajr');
    expect(result.at).toEqual(timeline.fajr);
  });

  it('returns Duha start during the sunrise sub-period', () => {
    const now = new Date('2025-03-16T03:20:00.000Z');
    const result = getNextTransition(now, timeline);
    expect(result.id).toBe('duha_start');
    expect(result.at).toEqual(timeline.duhaStart);
  });

  it('returns Duha end during the duha sub-period', () => {
    const now = new Date('2025-03-16T06:00:00.000Z');
    const result = getNextTransition(now, timeline);
    expect(result.id).toBe('duha_end');
    expect(result.at).toEqual(timeline.duhaEnd);
  });

  it('returns Dhuhr during the midday sub-period', () => {
    const now = new Date('2025-03-16T09:12:00.000Z');
    const result = getNextTransition(now, timeline);
    expect(result.id).toBe('dhuhr');
    expect(result.at).toEqual(timeline.dhuhr);
  });

  it('returns nextMaghrib when in asr_to_maghrib phase', () => {
    const now = new Date('2025-03-16T14:00:00.000Z');
    const result = getNextTransition(now, timeline);
    expect(result.id).toBe('maghrib');
    expect(result.at).toEqual(timeline.nextMaghrib);
  });
});
