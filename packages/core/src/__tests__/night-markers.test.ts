import { describe, it, expect } from 'vitest';
import { getLastThirdStart } from '../night-markers.js';

describe('night-markers', () => {
  const lastMaghrib = new Date('2025-03-15T15:30:00.000Z'); // 18:30 Riyadh
  const fajr = new Date('2025-03-16T02:00:00.000Z');        // 05:00 Riyadh

  const nightDurationMs = fajr.getTime() - lastMaghrib.getTime(); // 10.5 hours

  describe('getLastThirdStart', () => {
    it('returns fajr minus one-third of the night', () => {
      const lastThird = getLastThirdStart(lastMaghrib, fajr);
      const expected = new Date(fajr.getTime() - nightDurationMs / 3);
      expect(lastThird.getTime()).toBe(expected.getTime());
    });

    it('is before Fajr', () => {
      const lastThird = getLastThirdStart(lastMaghrib, fajr);
      expect(lastThird.getTime()).toBeLessThan(fajr.getTime());
    });
  });
});
