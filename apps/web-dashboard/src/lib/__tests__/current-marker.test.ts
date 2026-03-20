import { describe, it, expect } from 'vitest';
import { isNightPeriod, getCurrentMarkerVisualState } from '../current-marker.js';
import type { IslamicPhaseId, HijriDate } from '@islamic-day-dial/core';

describe('isNightPeriod', () => {
  it('returns true for maghrib_to_isha', () => {
    expect(isNightPeriod('maghrib_to_isha')).toBe(true);
  });

  it('returns true for isha_to_midnight', () => {
    expect(isNightPeriod('isha_to_midnight')).toBe(true);
  });

  it('returns true for last_third_to_fajr', () => {
    expect(isNightPeriod('last_third_to_fajr')).toBe(true);
  });

  it('returns true for fajr_to_sunrise (moon shown instead of black marker)', () => {
    expect(isNightPeriod('fajr_to_sunrise')).toBe(true);
  });

  it('returns false for sunrise_to_dhuhr', () => {
    expect(isNightPeriod('sunrise_to_dhuhr')).toBe(false);
  });

  it('returns false for dhuhr_to_asr', () => {
    expect(isNightPeriod('dhuhr_to_asr')).toBe(false);
  });

  it('returns false for asr_to_maghrib', () => {
    expect(isNightPeriod('asr_to_maghrib')).toBe(false);
  });
});

describe('getCurrentMarkerVisualState', () => {
  const mockHijriDate: HijriDate = {
    day: 15,
    monthNumber: 9,
    monthNameEn: 'Ramadan',
    year: 1446,
  };

  it('returns isNight true for night phases', () => {
    const state = getCurrentMarkerVisualState('isha_to_midnight', mockHijriDate);
    expect(state.isNight).toBe(true);
  });

  it('returns isNight false for day phases', () => {
    const state = getCurrentMarkerVisualState('dhuhr_to_asr', mockHijriDate);
    expect(state.isNight).toBe(false);
  });

  it('returns moonPhase only at night', () => {
    const nightState = getCurrentMarkerVisualState('isha_to_midnight', mockHijriDate);
    const dayState = getCurrentMarkerVisualState('dhuhr_to_asr', mockHijriDate);
    expect(nightState.moonPhase).not.toBeNull();
    expect(dayState.moonPhase).toBeNull();
  });

  it('uses hijriDate.day by default', () => {
    const state = getCurrentMarkerVisualState('isha_to_midnight', mockHijriDate);
    expect(state.hijriDayUsed).toBe(15);
  });

  it('uses debugHijriDay when provided', () => {
    const state = getCurrentMarkerVisualState('isha_to_midnight', mockHijriDate, 7);
    expect(state.hijriDayUsed).toBe(7);
    expect(state.moonPhase?.id).toBe('waxing_crescent');
  });
});
