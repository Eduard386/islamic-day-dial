import { describe, it, expect } from 'vitest';
import { getIslamicMidnight, getLastThirdStart } from '../night-markers.js';

describe('night-markers', () => {
  const lastMaghrib = new Date('2025-03-15T15:30:00.000Z'); // 18:30 Riyadh
  const fajr = new Date('2025-03-16T02:00:00.000Z');        // 05:00 Riyadh

  const nightDurationMs = fajr.getTime() - lastMaghrib.getTime(); // 10.5 hours

  describe('getIslamicMidnight', () => {
    it('returns the midpoint between Maghrib and Fajr', () => {
      const midnight = getIslamicMidnight(lastMaghrib, fajr);
      const expected = new Date(lastMaghrib.getTime() + nightDurationMs / 2);
      expect(midnight.getTime()).toBe(expected.getTime());
    });

    it('handles short summer nights', () => {
      const shortMaghrib = new Date('2024-07-15T17:30:00.000Z'); // 20:30 Istanbul
      const shortFajr = new Date('2024-07-16T00:30:00.000Z');    // 03:30 Istanbul
      const midnight = getIslamicMidnight(shortMaghrib, shortFajr);
      const nightMs = shortFajr.getTime() - shortMaghrib.getTime(); // 7 hours
      const expected = new Date(shortMaghrib.getTime() + nightMs / 2);
      expect(midnight.getTime()).toBe(expected.getTime());
    });
  });

  describe('getLastThirdStart', () => {
    it('returns fajr minus one-third of the night', () => {
      const lastThird = getLastThirdStart(lastMaghrib, fajr);
      const expected = new Date(fajr.getTime() - nightDurationMs / 3);
      expect(lastThird.getTime()).toBe(expected.getTime());
    });

    it('is after Islamic midnight', () => {
      const midnight = getIslamicMidnight(lastMaghrib, fajr);
      const lastThird = getLastThirdStart(lastMaghrib, fajr);
      expect(lastThird.getTime()).toBeGreaterThan(midnight.getTime());
    });

    it('is before Fajr', () => {
      const lastThird = getLastThirdStart(lastMaghrib, fajr);
      expect(lastThird.getTime()).toBeLessThan(fajr.getTime());
    });
  });
});
