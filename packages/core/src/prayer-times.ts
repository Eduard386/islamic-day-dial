import { Coordinates, PrayerTimes, CalculationMethod, Shafaq } from 'adhan';
import type { Location, PrayerTimesData } from './types.js';

/**
 * Compute prayer times for a given Gregorian date and location.
 * Uses Umm al-Qura for Dhuhr/Asr/Maghrib and Hijri calendar consistency.
 * Isha: computed by twilight disappearance (15° sun angle, Shafaq.Ahmer),
 * per hadith: "Perform Isha when the evening twilight disappears".
 */
export function getPrayerTimesForDate(
  date: Date,
  location: Location,
): PrayerTimesData {
  const coords = new Coordinates(location.latitude, location.longitude);
  const params = CalculationMethod.UmmAlQura();
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
