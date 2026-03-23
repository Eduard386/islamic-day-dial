import { describe, it, expect } from 'vitest';
import { computeIslamicDaySnapshot } from '@islamic-day-dial/core';
import type { UserContext } from '@islamic-day-dial/core';

/**
 * Duha sector starts when the sun reaches 4° above the horizon.
 * Tests verify dynamic duhaStart computation (solar altitude, not fixed 20 min).
 */
describe('Duha sector start (sunrise_to_dhuhr)', () => {
  const MECCA: UserContext['location'] = { latitude: 21.4225, longitude: 39.8262 };

  it('duhaStart is after sunrise and before duhaEnd', () => {
    const snapshot = computeIslamicDaySnapshot({
      now: new Date('2026-03-20T08:00:00.000Z'),
      location: MECCA,
      timezone: 'Asia/Riyadh',
    });
    const { sunrise, duhaStart, duhaEnd } = snapshot.timeline;
    expect(duhaStart.getTime()).toBeGreaterThan(sunrise.getTime());
    expect(duhaStart.getTime()).toBeLessThan(duhaEnd.getTime());
  });

  it('duhaStart is computed around 4° solar altitude (Mecca, March)', () => {
    const snapshot = computeIslamicDaySnapshot({
      now: new Date('2026-03-20T08:00:00.000Z'),
      location: MECCA,
      timezone: 'Asia/Riyadh',
    });
    const diffMinutes =
      (snapshot.timeline.duhaStart.getTime() - snapshot.timeline.sunrise.getTime()) / 60000;
    expect(diffMinutes).toBeGreaterThan(20);
    expect(diffMinutes).toBeLessThan(26);
  });

  it('duhaStart varies by location (high latitude vs Mecca)', () => {
    const meccaSnapshot = computeIslamicDaySnapshot({
      now: new Date('2026-06-15T08:00:00.000Z'),
      location: MECCA,
      timezone: 'Asia/Riyadh',
    });
    const londonSnapshot = computeIslamicDaySnapshot({
      now: new Date('2026-06-15T08:00:00.000Z'),
      location: { latitude: 51.5074, longitude: -0.1278 },
      timezone: 'Europe/London',
    });
    const meccaDiff =
      (meccaSnapshot.timeline.duhaStart.getTime() - meccaSnapshot.timeline.sunrise.getTime()) /
      60000;
    const londonDiff =
      (londonSnapshot.timeline.duhaStart.getTime() - londonSnapshot.timeline.sunrise.getTime()) /
      60000;
    expect(meccaDiff).not.toEqual(londonDiff);
  });
});
