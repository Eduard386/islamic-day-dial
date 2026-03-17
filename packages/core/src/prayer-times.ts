import { Coordinates, PrayerTimes, CalculationMethod } from 'adhan';
import type { Location, PrayerTimesData } from './types.js';

/**
 * Compute prayer times for a given Gregorian date and location.
 * Uses Umm al-Qura calculation method for consistency with the Hijri calendar.
 *
 * The `date` parameter determines which day's prayers to compute —
 * adhan extracts year/month/day using local-timezone Date methods.
 */
export function getPrayerTimesForDate(
  date: Date,
  location: Location,
): PrayerTimesData {
  const coords = new Coordinates(location.latitude, location.longitude);
  const params = CalculationMethod.UmmAlQura();
  const pt = new PrayerTimes(coords, date, params);

  return {
    fajr: pt.fajr,
    sunrise: pt.sunrise,
    dhuhr: pt.dhuhr,
    asr: pt.asr,
    maghrib: pt.maghrib,
    isha: pt.isha,
  };
}

export function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}
