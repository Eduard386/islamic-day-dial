import { describe, it, expect } from 'vitest';
import { getHijriDate, getIslamicDayHijriDate } from '../calendar.js';

describe('getHijriDate', () => {
  it('converts a known Gregorian date to Hijri', () => {
    // July 3, 2019 = 30 Shawwal 1440 (verified)
    const date = new Date(2019, 6, 3);
    const hijri = getHijriDate(date);
    expect(hijri.year).toBe(1440);
    expect(hijri.monthNumber).toBe(10);
    expect(hijri.monthNameEn).toBe('Shawwal');
    expect(hijri.day).toBe(30);
  });

  it('returns valid month names', () => {
    const date = new Date(2025, 2, 15);
    const hijri = getHijriDate(date);
    expect(hijri.monthNameEn.length).toBeGreaterThan(0);
    expect(hijri.monthNameAr!.length).toBeGreaterThan(0);
  });
});

describe('getIslamicDayHijriDate', () => {
  it('returns today\'s Hijri date before Maghrib', () => {
    const now = new Date('2025-03-15T12:00:00.000Z');
    const maghrib = new Date('2025-03-15T15:30:00.000Z');
    const hijri = getIslamicDayHijriDate(now, maghrib);
    const plain = getHijriDate(new Date(2025, 2, 15));
    expect(hijri.day).toBe(plain.day);
    expect(hijri.monthNumber).toBe(plain.monthNumber);
    expect(hijri.year).toBe(plain.year);
  });

  it('returns tomorrow\'s Hijri date after Maghrib', () => {
    const now = new Date('2025-03-15T16:00:00.000Z');
    const maghrib = new Date('2025-03-15T15:30:00.000Z');
    const hijri = getIslamicDayHijriDate(now, maghrib);
    const tomorrowPlain = getHijriDate(new Date(2025, 2, 16));
    expect(hijri.day).toBe(tomorrowPlain.day);
    expect(hijri.monthNumber).toBe(tomorrowPlain.monthNumber);
    expect(hijri.year).toBe(tomorrowPlain.year);
  });
});
