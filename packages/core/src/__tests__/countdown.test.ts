import { describe, it, expect } from 'vitest';
import { getCountdown } from '../countdown.js';

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
