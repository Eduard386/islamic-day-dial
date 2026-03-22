import { describe, it, expect } from 'vitest';
import { formatHijriDate, formatCountdown, formatPhase, getSunriseToDhuhrSubPeriod } from '../formatting.js';

describe('formatHijriDate', () => {
  it('formats day monthName year', () => {
    expect(formatHijriDate({ day: 14, monthNumber: 9, monthNameEn: 'Ramadan', year: 1447 }))
      .toBe('14 Ramadan 1447');
  });

  it('returns EID AL-FITR on 1 Shawwal', () => {
    expect(formatHijriDate({ day: 1, monthNumber: 10, monthNameEn: 'Shawwal', year: 1447 }))
      .toBe('EID AL-FITR');
  });

  it('returns EID AL-ADHA on 10 Dhul Hijjah', () => {
    expect(formatHijriDate({ day: 10, monthNumber: 12, monthNameEn: 'Dhul Hijjah', year: 1447 }))
      .toBe('EID AL-ADHA');
  });

  it('formats regular date on 2 Shawwal', () => {
    expect(formatHijriDate({ day: 2, monthNumber: 10, monthNameEn: 'Shawwal', year: 1447 }))
      .toBe('2 Shawwal 1447');
  });
});

describe('formatCountdown', () => {
  it('formats as -HH:MM (no seconds)', () => {
    const ms = (1 * 3600 + 23 * 60 + 45) * 1000;
    expect(formatCountdown(ms)).toBe('-01:23');
  });

  it('returns -00:00 for 0', () => {
    expect(formatCountdown(0)).toBe('-00:00');
  });

  it('returns -00:00 for negative', () => {
    expect(formatCountdown(-5000)).toBe('-00:00');
  });

  it('pads single digits', () => {
    const ms = (0 * 3600 + 5 * 60 + 3) * 1000;
    expect(formatCountdown(ms)).toBe('-00:05');
  });
});

describe('formatPhase', () => {
  it('returns human-readable label', () => {
    expect(formatPhase('fajr_to_sunrise')).toBe('Fajr → Sunrise');
  });
});

describe('getSunriseToDhuhrSubPeriod', () => {
  const sunrise = new Date('2025-03-16T03:15:00.000Z');
  const dhuhr = new Date('2025-03-16T09:15:00.000Z');

  it('returns sunrise before duha_start', () => {
    expect(getSunriseToDhuhrSubPeriod(new Date('2025-03-16T03:20:00.000Z'), sunrise, dhuhr)).toBe('sunrise');
  });

  it('returns duha in the middle', () => {
    expect(getSunriseToDhuhrSubPeriod(new Date('2025-03-16T06:00:00.000Z'), sunrise, dhuhr)).toBe('duha');
  });

  it('returns midday in last 5 min', () => {
    expect(getSunriseToDhuhrSubPeriod(new Date('2025-03-16T09:12:00.000Z'), sunrise, dhuhr)).toBe('midday');
  });

  it('returns duha at exactly 20 min after sunrise (boundary)', () => {
    // sunrise + 20 min = duha start; at that moment sub-period is duha
    expect(getSunriseToDhuhrSubPeriod(new Date('2025-03-16T03:35:00.000Z'), sunrise, dhuhr)).toBe('duha');
  });

  it('returns sunrise at 19 min after sunrise (still in sunrise sub-period)', () => {
    expect(getSunriseToDhuhrSubPeriod(new Date('2025-03-16T03:34:00.000Z'), sunrise, dhuhr)).toBe('sunrise');
  });
});
