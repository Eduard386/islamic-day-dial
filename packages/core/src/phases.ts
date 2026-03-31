import type { IslamicPhaseId, ComputedTimeline } from './types.js';
import { PHASE_BOUNDARIES } from './types.js';

/**
 * Determine which Islamic day phase `now` falls into.
 * Walks the timeline boundaries in order and returns the first phase
 * where now ∈ [start, end).
 */
export function getCurrentPhase(now: Date, timeline: ComputedTimeline): IslamicPhaseId {
  const t = now.getTime();

  for (const { id, startKey, endKey } of PHASE_BOUNDARIES) {
    const start = timeline[startKey].getTime();
    const end = timeline[endKey].getTime();
    if (t >= start && t < end) {
      return id;
    }
  }

  return 'asr_to_maghrib';
}

/**
 * Find the next boundary transition after `now`.
 */
export function getNextTransition(
  now: Date,
  timeline: ComputedTimeline,
): { id: string; at: Date } {
  const t = now.getTime();

  const orderedPoints: Array<{ id: string; at: Date }> = [
    { id: 'isha', at: timeline.isha },
    { id: 'last_third_start', at: timeline.lastThirdStart },
    { id: 'fajr', at: timeline.fajr },
    { id: 'sunrise', at: timeline.sunrise },
    { id: 'duha_start', at: timeline.duhaStart },
    { id: 'duha_end', at: timeline.duhaEnd },
    { id: 'dhuhr', at: timeline.dhuhr },
    { id: 'asr', at: timeline.asr },
    { id: 'maghrib', at: timeline.nextMaghrib },
  ];

  for (const point of orderedPoints) {
    if (point.at.getTime() > t) {
      return point;
    }
  }

  return { id: 'maghrib', at: timeline.nextMaghrib };
}
