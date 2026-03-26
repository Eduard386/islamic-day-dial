import { describe, it, expect } from 'vitest';
import {
  isJumuahGlowWindow,
  isLastThirdPhase,
  NIGHT_SECTORS_GROUP,
  isInIshaOrLastThirdSector,
} from '@islamic-day-dial/core';

describe('isJumuahGlowWindow', () => {
  const timeline = {
    duhaStart: new Date('2025-03-21T04:38:00.000Z'),
    dhuhr: new Date('2025-03-21T09:15:00.000Z'),
  };

  it('returns false when not Friday', () => {
    const thursday = new Date('2025-03-20T10:00:00.000Z'); // Thu
    expect(isJumuahGlowWindow(thursday, timeline, 'dhuhr_to_asr')).toBe(false);
  });

  it('returns true on Friday when in dhuhr_to_asr', () => {
    const friday = new Date('2025-03-21T10:00:00.000Z'); // Fri
    expect(isJumuahGlowWindow(friday, timeline, 'dhuhr_to_asr')).toBe(true);
  });

  it('returns true on Friday when in duha sub-period', () => {
    const friday = new Date('2025-03-21T06:00:00.000Z'); // Fri, after dynamic duhaStart
    expect(isJumuahGlowWindow(friday, timeline, 'sunrise_to_dhuhr')).toBe(true);
  });

  it('returns true on Friday when in midday sub-period', () => {
    const friday = new Date('2025-03-21T09:12:00.000Z'); // Fri, last 5 min before dhuhr
    expect(isJumuahGlowWindow(friday, timeline, 'sunrise_to_dhuhr')).toBe(true);
  });

  it('returns false on Friday when in sunrise sub-period', () => {
    const friday = new Date('2025-03-21T04:20:00.000Z'); // Fri, before dynamic duhaStart
    expect(isJumuahGlowWindow(friday, timeline, 'sunrise_to_dhuhr')).toBe(false);
  });

  it('returns false on Friday when in night phases', () => {
    const friday = new Date('2025-03-21T03:00:00.000Z');
    expect(isJumuahGlowWindow(friday, timeline, 'isha_to_last_third')).toBe(false);
    expect(isJumuahGlowWindow(friday, timeline, 'last_third_to_fajr')).toBe(false);
    expect(isJumuahGlowWindow(friday, timeline, 'maghrib_to_isha')).toBe(false);
  });

  it('returns false on Friday when in asr_to_maghrib', () => {
    const friday = new Date('2025-03-21T14:00:00.000Z');
    expect(isJumuahGlowWindow(friday, timeline, 'asr_to_maghrib')).toBe(false);
  });
});

describe('isLastThirdPhase', () => {
  it('returns true for last_third_to_fajr', () => {
    expect(isLastThirdPhase('last_third_to_fajr')).toBe(true);
  });

  it('returns false for other phases', () => {
    expect(isLastThirdPhase('isha_to_last_third')).toBe(false);
    expect(isLastThirdPhase('dhuhr_to_asr')).toBe(false);
    expect(isLastThirdPhase('maghrib_to_isha')).toBe(false);
  });
});

describe('NIGHT_SECTORS_GROUP', () => {
  it('contains isha_to_last_third and last_third_to_fajr', () => {
    expect(NIGHT_SECTORS_GROUP.has('isha_to_last_third')).toBe(true);
    expect(NIGHT_SECTORS_GROUP.has('last_third_to_fajr')).toBe(true);
  });

  it('does not contain other phases', () => {
    expect(NIGHT_SECTORS_GROUP.has('maghrib_to_isha')).toBe(false);
    expect(NIGHT_SECTORS_GROUP.has('dhuhr_to_asr')).toBe(false);
  });
});

describe('isInIshaOrLastThirdSector', () => {
  it('returns true for isha_to_last_third (Isha glow + Last Third weak glow)', () => {
    expect(isInIshaOrLastThirdSector('isha_to_last_third')).toBe(true);
  });

  it('returns true for last_third_to_fajr (Last Third pulsating + Isha weak glow)', () => {
    expect(isInIshaOrLastThirdSector('last_third_to_fajr')).toBe(true);
  });

  it('returns false for maghrib_to_isha', () => {
    expect(isInIshaOrLastThirdSector('maghrib_to_isha')).toBe(false);
  });

  it('returns false for day phases', () => {
    expect(isInIshaOrLastThirdSector('sunrise_to_dhuhr')).toBe(false);
    expect(isInIshaOrLastThirdSector('dhuhr_to_asr')).toBe(false);
  });
});
