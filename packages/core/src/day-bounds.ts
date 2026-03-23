import type { PrayerTimesData, ComputedTimeline, Location } from './types.js';
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
  location: Location,
): ComputedTimeline {
  const afterMaghrib = now.getTime() >= todayPT.maghrib.getTime();

  const nightPT = afterMaghrib ? todayPT : yesterdayPT;
  const dayPT = afterMaghrib ? tomorrowPT : todayPT;
  const lastMaghrib = nightPT.maghrib;
  const nextMaghrib = dayPT.maghrib;
  const fajr = dayPT.fajr;

  const sunrise = dayPT.sunrise;
  const dhuhr = dayPT.dhuhr;
  const duhaEnd = new Date(dhuhr.getTime() - 5 * 60 * 1000);
  const duhaStart = getDuhaStart(sunrise, dhuhr, location, duhaEnd);

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

const DUHA_START_ALTITUDE_DEG = 4;
const DUHA_START_FALLBACK_MS = 20 * 60 * 1000;
const SEARCH_STEPS = 24;

function getDuhaStart(
  sunrise: Date,
  dhuhr: Date,
  location: Location,
  duhaEnd: Date,
): Date {
  const fallback = new Date(Math.min(sunrise.getTime() + DUHA_START_FALLBACK_MS, duhaEnd.getTime()));
  const sunriseAltitude = getSolarAltitude(sunrise, location);
  if (sunriseAltitude >= DUHA_START_ALTITUDE_DEG) {
    return sunrise;
  }

  const dhuhrAltitude = getSolarAltitude(dhuhr, location);
  if (dhuhrAltitude < DUHA_START_ALTITUDE_DEG) {
    return fallback;
  }

  let low = sunrise.getTime();
  let high = dhuhr.getTime();
  for (let i = 0; i < SEARCH_STEPS; i += 1) {
    const mid = (low + high) / 2;
    const altitude = getSolarAltitude(new Date(mid), location);
    if (altitude < DUHA_START_ALTITUDE_DEG) {
      low = mid;
    } else {
      high = mid;
    }
  }

  return new Date(Math.min(high, duhaEnd.getTime()));
}

function getSolarAltitude(date: Date, location: Location): number {
  const jd = date.getTime() / 86400000 + 2440587.5;
  const t = (jd - 2451545.0) / 36525.0;

  const meanLongitude = normalizeDegrees(280.46646 + t * (36000.76983 + t * 0.0003032));
  const meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  const eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

  const equationOfCenter =
    Math.sin(toRadians(meanAnomaly)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
    Math.sin(toRadians(2 * meanAnomaly)) * (0.019993 - 0.000101 * t) +
    Math.sin(toRadians(3 * meanAnomaly)) * 0.000289;

  const trueLongitude = meanLongitude + equationOfCenter;
  const omega = 125.04 - 1934.136 * t;
  const apparentLongitude = trueLongitude - 0.00569 - 0.00478 * Math.sin(toRadians(omega));

  const epsilon0 =
    23 +
    (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
  const epsilon = epsilon0 + 0.00256 * Math.cos(toRadians(omega));
  const declination = toDegrees(
    Math.asin(Math.sin(toRadians(epsilon)) * Math.sin(toRadians(apparentLongitude))),
  );

  const y = Math.tan(toRadians(epsilon / 2)) ** 2;
  const equationOfTime =
    4 *
    toDegrees(
      y * Math.sin(toRadians(2 * meanLongitude)) -
      2 * eccentricity * Math.sin(toRadians(meanAnomaly)) +
      4 * eccentricity * y * Math.sin(toRadians(meanAnomaly)) * Math.cos(toRadians(2 * meanLongitude)) -
      0.5 * y * y * Math.sin(toRadians(4 * meanLongitude)) -
      1.25 * eccentricity * eccentricity * Math.sin(toRadians(2 * meanAnomaly)),
    );

  const utcMinutes =
    date.getUTCHours() * 60 + date.getUTCMinutes() + date.getUTCSeconds() / 60 + date.getUTCMilliseconds() / 60000;
  const trueSolarTime = ((utcMinutes + equationOfTime + 4 * location.longitude) % 1440 + 1440) % 1440;
  const hourAngle = trueSolarTime / 4 - 180;

  const zenith = toDegrees(
    Math.acos(
      Math.sin(toRadians(location.latitude)) * Math.sin(toRadians(declination)) +
      Math.cos(toRadians(location.latitude)) *
        Math.cos(toRadians(declination)) *
        Math.cos(toRadians(hourAngle)),
    ),
  );

  return 90 - zenith;
}

function toRadians(deg: number): number {
  return (deg * Math.PI) / 180;
}

function toDegrees(rad: number): number {
  return (rad * 180) / Math.PI;
}

function normalizeDegrees(deg: number): number {
  return ((deg % 360) + 360) % 360;
}
