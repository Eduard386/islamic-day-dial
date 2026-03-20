import type {
  ComputedTimeline,
  RingMarker,
  RingSegment,
  RingMarkerId,
  RingMarkerKind,
} from './types.js';
import { PHASE_BOUNDARIES } from './types.js';

/**
 * Linear progress through the Islamic day: 0 at lastMaghrib, 1 at nextMaghrib.
 */
export function getIslamicDayProgress(
  now: Date,
  lastMaghrib: Date,
  nextMaghrib: Date,
): number {
  const total = nextMaghrib.getTime() - lastMaghrib.getTime();
  if (total <= 0) return 0;
  const elapsed = now.getTime() - lastMaghrib.getTime();
  return Math.max(0, Math.min(1, elapsed / total));
}

/**
 * Convert a timestamp to an angle (0–360°) on the ring.
 * 0° = top = lastMaghrib, angles increase clockwise.
 */
export function timestampToAngle(
  timestamp: Date,
  lastMaghrib: Date,
  nextMaghrib: Date,
): number {
  const progress = getIslamicDayProgress(timestamp, lastMaghrib, nextMaghrib);
  return progress * 360;
}

const MARKER_DEFS: ReadonlyArray<{
  id: RingMarkerId;
  timelineKey: keyof ComputedTimeline;
  kind: RingMarkerKind;
}> = [
  { id: 'maghrib', timelineKey: 'lastMaghrib', kind: 'primary' },
  { id: 'isha', timelineKey: 'isha', kind: 'primary' },
  { id: 'last_third_start', timelineKey: 'lastThirdStart', kind: 'secondary' },
  { id: 'fajr', timelineKey: 'fajr', kind: 'primary' },
  { id: 'sunrise', timelineKey: 'sunrise', kind: 'primary' },
  { id: 'duha_start', timelineKey: 'duhaStart', kind: 'secondary' },
  { id: 'duha_end', timelineKey: 'duhaEnd', kind: 'secondary' },
  { id: 'dhuhr', timelineKey: 'dhuhr', kind: 'primary' },
  { id: 'asr', timelineKey: 'asr', kind: 'primary' },
];

export function getMarkers(timeline: ComputedTimeline): RingMarker[] {
  return MARKER_DEFS.map(({ id, timelineKey, kind }) => {
    const timestamp = timeline[timelineKey];
    return {
      id,
      timestamp,
      angleDeg: timestampToAngle(timestamp, timeline.lastMaghrib, timeline.nextMaghrib),
      kind,
    };
  });
}

export function getRingSegments(timeline: ComputedTimeline): RingSegment[] {
  return PHASE_BOUNDARIES.map(({ id, startKey, endKey }) => {
    const start = timeline[startKey];
    const end = timeline[endKey];
    return {
      id,
      start,
      end,
      startAngleDeg: timestampToAngle(start, timeline.lastMaghrib, timeline.nextMaghrib),
      endAngleDeg: timestampToAngle(end, timeline.lastMaghrib, timeline.nextMaghrib),
    };
  });
}
