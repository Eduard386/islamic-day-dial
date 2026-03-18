import { describe, it, expect } from 'vitest';
import { getMoonPhaseByHijriDay, type MoonPhaseId } from '../moon-phases.js';

describe('getMoonPhaseByHijriDay', () => {
  describe('phase boundaries', () => {
    it('day 1 returns very_thin_waxing_crescent', () => {
      expect(getMoonPhaseByHijriDay(1).id).toBe('very_thin_waxing_crescent');
    });

    it('day 3 returns very_thin_waxing_crescent (end of range)', () => {
      expect(getMoonPhaseByHijriDay(3).id).toBe('very_thin_waxing_crescent');
    });

    it('day 4 returns waxing_crescent (start of range)', () => {
      expect(getMoonPhaseByHijriDay(4).id).toBe('waxing_crescent');
    });

    it('day 8 returns first_quarter', () => {
      expect(getMoonPhaseByHijriDay(8).id).toBe('first_quarter');
    });

    it('day 14 returns full', () => {
      expect(getMoonPhaseByHijriDay(14).id).toBe('full');
    });

    it('day 15 returns full (middle of month)', () => {
      expect(getMoonPhaseByHijriDay(15).id).toBe('full');
    });

    it('day 17 returns waning_gibbous', () => {
      expect(getMoonPhaseByHijriDay(17).id).toBe('waning_gibbous');
    });

    it('day 21 returns last_quarter', () => {
      expect(getMoonPhaseByHijriDay(21).id).toBe('last_quarter');
    });

    it('day 28 returns very_thin_waning_crescent', () => {
      expect(getMoonPhaseByHijriDay(28).id).toBe('very_thin_waning_crescent');
    });

    it('day 30 returns very_thin_waning_crescent (end of month)', () => {
      expect(getMoonPhaseByHijriDay(30).id).toBe('very_thin_waning_crescent');
    });
  });

  describe('shadow offset signs', () => {
    it('waxing phases have negative offset (lit on right)', () => {
      expect(getMoonPhaseByHijriDay(1).shadowOffset).toBeLessThan(0);
      expect(getMoonPhaseByHijriDay(5).shadowOffset).toBeLessThan(0);
      expect(getMoonPhaseByHijriDay(10).shadowOffset).toBeLessThan(0);
      expect(getMoonPhaseByHijriDay(12).shadowOffset).toBeLessThan(0);
    });

    it('full moon has zero offset', () => {
      expect(getMoonPhaseByHijriDay(15).shadowOffset).toBe(0);
    });

    it('waning phases have positive offset (lit on left)', () => {
      expect(getMoonPhaseByHijriDay(18).shadowOffset).toBeGreaterThan(0);
      expect(getMoonPhaseByHijriDay(22).shadowOffset).toBeGreaterThan(0);
      expect(getMoonPhaseByHijriDay(25).shadowOffset).toBeGreaterThan(0);
      expect(getMoonPhaseByHijriDay(29).shadowOffset).toBeGreaterThan(0);
    });
  });

  describe('edge cases', () => {
    it('clamps day < 1 to 1', () => {
      expect(getMoonPhaseByHijriDay(0).id).toBe('very_thin_waxing_crescent');
      expect(getMoonPhaseByHijriDay(-5).id).toBe('very_thin_waxing_crescent');
    });

    it('clamps day > 30 to 30', () => {
      expect(getMoonPhaseByHijriDay(31).id).toBe('very_thin_waning_crescent');
      expect(getMoonPhaseByHijriDay(100).id).toBe('very_thin_waning_crescent');
    });

    it('floors fractional days', () => {
      expect(getMoonPhaseByHijriDay(3.9).id).toBe('very_thin_waxing_crescent');
      expect(getMoonPhaseByHijriDay(4.1).id).toBe('waxing_crescent');
    });
  });
});
