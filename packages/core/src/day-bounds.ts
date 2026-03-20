import type { PrayerTimesData, ComputedTimeline } from './types.js';
import { getIslamicMidnight, getLastThirdStart } from './night-markers.js';

export type IslamicDayBounds = {
  lastMaghrib: Date;
  nextMaghrib: Date;
};

/**
 * Determine the Islamic day boundaries (lastMaghrib → nextMaghrib)
 * based on the current time relative to today's Maghrib.
 */
export function getIslamicDayBounds(
  now: Date,
  todayPT: PrayerTimesData,
  yesterdayPT: PrayerTimesData,
  tomorrowPT: PrayerTimesData,
): IslamicDayBounds {
  if (now.getTime() >= todayPT.maghrib.getTime()) {
    return {
      lastMaghrib: todayPT.maghrib,
      nextMaghrib: tomorrowPT.maghrib,
    };
  }
  return {
    lastMaghrib: yesterdayPT.maghrib,
    nextMaghrib: todayPT.maghrib,
  };
}

/**
 * Build the full ordered timeline for the current Islamic day.
 *
 * After today's Maghrib:
 *   lastMaghrib=today → Isha=today → … → Fajr=tomorrow → … → nextMaghrib=tomorrow
 *
 * Before today's Maghrib:
 *   lastMaghrib=yesterday → Isha=yesterday → … → Fajr=today → … → nextMaghrib=today
 */
export function buildTimeline(
  now: Date,
  todayPT: PrayerTimesData,
  yesterdayPT: PrayerTimesData,
  tomorrowPT: PrayerTimesData,
): ComputedTimeline {
  const afterMaghrib = now.getTime() >= todayPT.maghrib.getTime();

  const nightPT = afterMaghrib ? todayPT : yesterdayPT;
  const dayPT = afterMaghrib ? tomorrowPT : todayPT;
  const lastMaghrib = nightPT.maghrib;
  const nextMaghrib = dayPT.maghrib;
  const fajr = dayPT.fajr;

  const sunrise = dayPT.sunrise;
  const dhuhr = dayPT.dhuhr;
  const duhaStart = new Date(sunrise.getTime() + 20 * 60 * 1000);
  const duhaEnd = new Date(dhuhr.getTime() - 5 * 60 * 1000);

  return {
    lastMaghrib,
    isha: nightPT.isha,
    islamicMidnight: getIslamicMidnight(lastMaghrib, fajr),
    lastThirdStart: getLastThirdStart(lastMaghrib, fajr),
    fajr,
    sunrise,
    duhaStart,
    duhaEnd,
    dhuhr,
    asr: dayPT.asr,
    nextMaghrib,
  };
}
