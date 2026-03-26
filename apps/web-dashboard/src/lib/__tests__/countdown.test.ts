import { describe, it, expect } from 'vitest';
import {
  computeIslamicDaySnapshot,
  getCountdown,
  getCountdownTarget,
  type UserContext,
} from '@islamic-day-dial/core';

/**
 * Web countdown tests: verify countdown always targets the start of the next sector.
 * Mirrors packages/core/src/__tests__/countdown.test.ts logic using real snapshots.
 */

const MECCA: UserContext = {
  now: new Date('2025-03-16T06:00:00.000Z'),
  location: { latitude: 21.4225, longitude: 39.8262 },
  timezone: 'Asia/Riyadh',
};

describe('countdown targets next sector start (web)', () => {
  it('snapshot.countdownMs equals getCountdown(now, getCountdownTarget(now, timeline))', () => {
    const snapshot = computeIslamicDaySnapshot(MECCA);
    const target = getCountdownTarget(MECCA.now, snapshot.timeline);
    const expectedMs = getCountdown(MECCA.now, target);
    expect(snapshot.countdownMs).toBe(expectedMs);
  });

  it('Fajr sector: countdown targets Sunrise', () => {
    const base: UserContext = {
      now: new Date('2025-03-16T06:00:00.000Z'),
      location: { latitude: 21.4225, longitude: 39.8262 },
      timezone: 'Asia/Riyadh',
    };
    const seed = computeIslamicDaySnapshot(base);
    const midFajr = new Date(
      (seed.timeline.fajr.getTime() + seed.timeline.sunrise.getTime()) / 2,
    );
    const ctx: UserContext = { ...base, now: midFajr };
    const snapshot = computeIslamicDaySnapshot(ctx);
    expect(snapshot.currentPhase).toBe('fajr_to_sunrise');
    const target = getCountdownTarget(ctx.now, snapshot.timeline);
    expect(target.getTime()).toBe(snapshot.timeline.sunrise.getTime());
  });

  it('Dhuhr sector: countdown targets Asr', () => {
    const ctx: UserContext = {
      now: new Date('2024-07-15T11:00:00.000Z'), // 14:00 Istanbul, Dhuhr–Asr
      location: { latitude: 41.0082, longitude: 28.9784 },
      timezone: 'Europe/Istanbul',
    };
    const snapshot = computeIslamicDaySnapshot(ctx);
    expect(snapshot.currentPhase).toBe('dhuhr_to_asr');
    const target = getCountdownTarget(ctx.now, snapshot.timeline);
    expect(target.getTime()).toBe(snapshot.timeline.asr.getTime());
  });

  it('Maghrib sector: countdown targets Isha', () => {
    const ctx: UserContext = {
      now: new Date('2025-03-15T16:00:00.000Z'), // after Maghrib, before Isha
      location: { latitude: 21.4225, longitude: 39.8262 },
      timezone: 'Asia/Riyadh',
    };
    const snapshot = computeIslamicDaySnapshot(ctx);
    expect(snapshot.currentPhase).toBe('maghrib_to_isha');
    const target = getCountdownTarget(ctx.now, snapshot.timeline);
    expect(target.getTime()).toBe(snapshot.timeline.isha.getTime());
  });

  it('Isha sector: countdown targets Fajr', () => {
    const ctx: UserContext = {
      now: new Date('2025-03-15T20:00:00.000Z'), // isha_to_last_third
      location: { latitude: 21.4225, longitude: 39.8262 },
      timezone: 'Asia/Riyadh',
    };
    const snapshot = computeIslamicDaySnapshot(ctx);
    expect(['isha_to_last_third', 'last_third_to_fajr']).toContain(snapshot.currentPhase);
    const target = getCountdownTarget(ctx.now, snapshot.timeline);
    expect(target.getTime()).toBe(snapshot.timeline.fajr.getTime());
  });

  it('countdown is non-negative', () => {
    const snapshot = computeIslamicDaySnapshot(MECCA);
    expect(snapshot.countdownMs).toBeGreaterThanOrEqual(0);
  });
});
