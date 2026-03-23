import { Coordinates, PrayerTimes, CalculationMethod, Madhab, Shafaq } from 'adhan';
import type { Location, PrayerTimesData } from './types.js';

/**
 * Compute prayer times for a given Gregorian date and location.
 * Fajr: Umm al-Qura (18.5°).
 * Asr: Shafi (shadow length equals object length).
 * Isha: twilight disappearance (15° sun angle, Shafaq.Ahmer),
 * instead of Umm al-Qura's fixed 90-minute interval.
 */
export function getPrayerTimesForDate(
  date: Date,
  location: Location,
): PrayerTimesData {
  const coords = new Coordinates(location.latitude, location.longitude);
  const params = CalculationMethod.UmmAlQura();
  params.madhab = Madhab.Shafi;
  // Isha by twilight disappearance instead of fixed 90-min interval
  params.ishaInterval = 0;
  params.ishaAngle = 15;
  params.shafaq = Shafaq.Ahmer;
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
