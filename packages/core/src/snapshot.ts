import type { UserContext, ComputedIslamicDay } from './types.js';
import { getIslamicDayHijriDate } from './calendar.js';
import { getPrayerTimesForDate, addDays } from './prayer-times.js';
import { buildTimeline } from './day-bounds.js';
import { getCurrentPhase, getNextTransition } from './phases.js';
import { getCountdown, getCountdownTarget } from './countdown.js';
import { getIslamicDayProgress, getMarkers, getRingSegments } from './ring.js';

/**
 * Main orchestrator: computes the full Islamic day snapshot
 * from the user's current time, location, and timezone.
 */
export function computeIslamicDaySnapshot(input: UserContext): ComputedIslamicDay {
  const { now, location } = input;

  const todayPT = getPrayerTimesForDate(now, location);
  const yesterdayPT = getPrayerTimesForDate(addDays(now, -1), location);
  const tomorrowPT = getPrayerTimesForDate(addDays(now, 1), location);

  const timeline = buildTimeline(now, todayPT, yesterdayPT, tomorrowPT);

  const hijriDate = getIslamicDayHijriDate(now, todayPT.maghrib);

  const currentPhase = getCurrentPhase(now, timeline);
  const nextTransition = getNextTransition(now, timeline);
  const countdownTarget = getCountdownTarget(now, timeline);
  const countdownMs = getCountdown(now, countdownTarget);

  const progress = getIslamicDayProgress(now, timeline.lastMaghrib, timeline.nextMaghrib);
  const markers = getMarkers(timeline);
  const segments = getRingSegments(timeline);

  return {
    hijriDate,
    prayerTimes: {
      fajr: timeline.fajr,
      sunrise: timeline.sunrise,
      dhuhr: timeline.dhuhr,
      asr: timeline.asr,
      maghrib: timeline.lastMaghrib,
      isha: timeline.isha,
    },
    derivedMarkers: {
      islamicMidnight: timeline.islamicMidnight,
      lastThirdStart: timeline.lastThirdStart,
    },
    timeline,
    currentPhase,
    nextTransition,
    countdownMs,
    ring: {
      progress,
      markers,
      segments,
    },
  };
}
