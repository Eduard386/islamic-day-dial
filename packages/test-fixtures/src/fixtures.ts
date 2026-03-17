import type { Location, UserContext } from '@islamic-day-dial/core';

export const ISTANBUL: Location = { latitude: 41.0082, longitude: 28.9784 };
export const MECCA: Location = { latitude: 21.4225, longitude: 39.8262 };
export const LONDON: Location = { latitude: 51.5074, longitude: -0.1278 };

/**
 * Istanbul, summer afternoon (before Maghrib).
 * July 15 2024, 14:00 local (UTC+3 → 11:00 UTC).
 */
export const ISTANBUL_SUMMER_AFTERNOON: UserContext = {
  now: new Date('2024-07-15T11:00:00.000Z'),
  location: ISTANBUL,
  timezone: 'Europe/Istanbul',
};

/**
 * Istanbul, summer night (after Isha).
 * July 15 2024, 23:00 local (UTC+3 → 20:00 UTC).
 */
export const ISTANBUL_SUMMER_NIGHT: UserContext = {
  now: new Date('2024-07-15T20:00:00.000Z'),
  location: ISTANBUL,
  timezone: 'Europe/Istanbul',
};

/**
 * Istanbul, winter morning (before Dhuhr).
 * January 15 2025, 10:00 local (UTC+3 → 07:00 UTC).
 */
export const ISTANBUL_WINTER_MORNING: UserContext = {
  now: new Date('2025-01-15T07:00:00.000Z'),
  location: ISTANBUL,
  timezone: 'Europe/Istanbul',
};

/**
 * Mecca, Ramadan evening (just after Maghrib).
 * March 15 2025, 18:30 local (UTC+3 → 15:30 UTC).
 */
export const MECCA_RAMADAN_EVENING: UserContext = {
  now: new Date('2025-03-15T15:30:00.000Z'),
  location: MECCA,
  timezone: 'Asia/Riyadh',
};

/**
 * Mecca, Ramadan pre-Fajr (last third of the night).
 * March 16 2025, 04:00 local (UTC+3 → 01:00 UTC).
 */
export const MECCA_RAMADAN_PRE_FAJR: UserContext = {
  now: new Date('2025-03-16T01:00:00.000Z'),
  location: MECCA,
  timezone: 'Asia/Riyadh',
};

/**
 * London, spring equinox area.
 * March 21 2025, 12:00 local (UTC+0 → 12:00 UTC).
 */
export const LONDON_SPRING_NOON: UserContext = {
  now: new Date('2025-03-21T12:00:00.000Z'),
  location: LONDON,
  timezone: 'Europe/London',
};

export const ALL_FIXTURES: Record<string, UserContext> = {
  ISTANBUL_SUMMER_AFTERNOON,
  ISTANBUL_SUMMER_NIGHT,
  ISTANBUL_WINTER_MORNING,
  MECCA_RAMADAN_EVENING,
  MECCA_RAMADAN_PRE_FAJR,
  LONDON_SPRING_NOON,
};
