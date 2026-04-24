import {
  getSunriseToDhuhrSubPeriod,
  timestampToAngle,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';

export type ExplodedArcId =
  | 'maghrib'
  | 'isha'
  | 'lastThird'
  | 'fajr'
  | 'sunrise'
  | 'duha'
  | 'midday'
  | 'dhuhr'
  | 'asr';

export type ExplodedArcSpec = {
  id: ExplodedArcId;
  originalStartAngleDeg: number;
  originalEndAngleDeg: number;
  startAngleDeg: number;
  endAngleDeg: number;
};

const EXPLODED_ARC_SCALE = 0.925;
const DUHA_CLUSTER_GAP_FACTOR = 0.24;

function angleSpan(startDeg: number, endDeg: number): number {
  const raw = endDeg - startDeg;
  return raw >= 0 ? raw : raw + 360;
}

function adjustedArcBounds(startDeg: number, endDeg: number, scale: number): { start: number; end: number } {
  const span = angleSpan(startDeg, endDeg);
  const midpoint = startDeg + span / 2;
  const adjustedSpan = span * scale;
  return {
    start: midpoint - adjustedSpan / 2,
    end: midpoint + adjustedSpan / 2,
  };
}

function makeSpec(id: ExplodedArcId, start: number, end: number): ExplodedArcSpec {
  const adjusted = adjustedArcBounds(start, end, EXPLODED_ARC_SCALE);
  return {
    id,
    originalStartAngleDeg: start,
    originalEndAngleDeg: end,
    startAngleDeg: adjusted.start,
    endAngleDeg: adjusted.end,
  };
}

function tightenedDuhaCluster(specs: ExplodedArcSpec[]): ExplodedArcSpec[] {
  const adjusted = [...specs];
  const byId = new Map(adjusted.map((spec, index) => [spec.id, index]));

  const tightenGap = (leftId: ExplodedArcId, rightId: ExplodedArcId) => {
    const leftIndex = byId.get(leftId);
    const rightIndex = byId.get(rightId);
    if (leftIndex == null || rightIndex == null) return;

    const currentGap = angleSpan(adjusted[leftIndex].endAngleDeg, adjusted[rightIndex].startAngleDeg);
    if (currentGap <= 0.01 || currentGap >= 40) return;

    const desiredGap = currentGap * DUHA_CLUSTER_GAP_FACTOR;
    const delta = (currentGap - desiredGap) / 2;

    adjusted[leftIndex] = {
      ...adjusted[leftIndex],
      endAngleDeg: adjusted[leftIndex].endAngleDeg + delta,
    };

    adjusted[rightIndex] = {
      ...adjusted[rightIndex],
      startAngleDeg: adjusted[rightIndex].startAngleDeg - delta,
    };
  };

  tightenGap('sunrise', 'duha');
  tightenGap('duha', 'midday');

  return adjusted;
}

export function getExplodedRingArcSpecs(snapshot: ComputedIslamicDay): ExplodedArcSpec[] {
  const timeline = snapshot.timeline;
  const angleFor = (timestamp: Date) =>
    timestampToAngle(timestamp, timeline.lastMaghrib, timeline.nextMaghrib);

  return tightenedDuhaCluster([
    makeSpec('maghrib', angleFor(timeline.lastMaghrib), angleFor(timeline.isha)),
    makeSpec('isha', angleFor(timeline.isha), angleFor(timeline.lastThirdStart)),
    makeSpec('lastThird', angleFor(timeline.lastThirdStart), angleFor(timeline.fajr)),
    makeSpec('fajr', angleFor(timeline.fajr), angleFor(timeline.sunrise)),
    makeSpec('sunrise', angleFor(timeline.sunrise), angleFor(timeline.duhaStart)),
    makeSpec('duha', angleFor(timeline.duhaStart), angleFor(timeline.duhaEnd)),
    makeSpec('midday', angleFor(timeline.duhaEnd), angleFor(timeline.dhuhr)),
    makeSpec('dhuhr', angleFor(timeline.dhuhr), angleFor(timeline.asr)),
    makeSpec('asr', angleFor(timeline.asr), angleFor(timeline.nextMaghrib)),
  ]);
}

export function getExplodedArcMidAngle(spec: ExplodedArcSpec): number {
  return spec.startAngleDeg + angleSpan(spec.startAngleDeg, spec.endAngleDeg) / 2;
}

/** Map prayer marker → exploded arc whose *visual start* is that boundary (ticks must use exploded angles). */
export const MARKER_ID_TO_EXPLODED_ARC_START: Readonly<Partial<Record<string, ExplodedArcId>>> = {
  maghrib: 'maghrib',
  isha: 'isha',
  last_third_start: 'lastThird',
  fajr: 'fajr',
  sunrise: 'sunrise',
  duha_start: 'duha',
  duha_end: 'midday',
  dhuhr: 'dhuhr',
  asr: 'asr',
};

export function getExplodedTickAngleDeg(
  markerId: string,
  fallbackAngleDeg: number,
  explodedArcById: Map<ExplodedArcId, ExplodedArcSpec>,
): number {
  const arcId = MARKER_ID_TO_EXPLODED_ARC_START[markerId];
  if (arcId) {
    const spec = explodedArcById.get(arcId);
    if (spec) return spec.startAngleDeg;
  }
  return fallbackAngleDeg;
}

/** Duha / Midday / Dhuhr: keep leader anchors on exploded (tightened) geometry; all other arcs use timeline angles. */
const DIAL_FOOTNOTE_EXPLODED_ANCHOR_ON_EID: ReadonlySet<ExplodedArcId> = new Set(['duha', 'midday', 'dhuhr']);

function originalArcMidAngle(spec: ExplodedArcSpec): number {
  return spec.originalStartAngleDeg + angleSpan(spec.originalStartAngleDeg, spec.originalEndAngleDeg) / 2;
}

/** Dial footnote leader attachment: on Eid, non-noon sectors stay aligned with the real ring gradient. */
export function getDialFootnoteAnchorAngleDeg(spec: ExplodedArcSpec, isEidDay: boolean): number {
  if (isEidDay && !DIAL_FOOTNOTE_EXPLODED_ANCHOR_ON_EID.has(spec.id)) {
    return originalArcMidAngle(spec);
  }
  return getExplodedArcMidAngle(spec);
}

export function adjustExplodedAngle(spec: ExplodedArcSpec, originalAngle: number): number {
  const originalSpan = angleSpan(spec.originalStartAngleDeg, spec.originalEndAngleDeg);
  if (originalSpan <= 0) return originalAngle;

  const traveled = angleSpan(spec.originalStartAngleDeg, originalAngle >= 360 ? 0 : originalAngle);
  const t = Math.max(0, Math.min(1, traveled / originalSpan));
  const adjustedSpan = angleSpan(spec.startAngleDeg, spec.endAngleDeg);
  return spec.startAngleDeg + adjustedSpan * t;
}

export function getCurrentExplodedArcId(snapshot: ComputedIslamicDay, now: Date): ExplodedArcId {
  switch (snapshot.currentPhase) {
    case 'maghrib_to_isha':
      return 'maghrib';
    case 'isha_to_last_third':
      return 'isha';
    case 'last_third_to_fajr':
      return 'lastThird';
    case 'fajr_to_sunrise':
      return 'fajr';
    case 'sunrise_to_dhuhr': {
      const subPeriod = getSunriseToDhuhrSubPeriod(now, snapshot.timeline.duhaStart, snapshot.timeline.dhuhr);
      if (subPeriod === 'sunrise') return 'sunrise';
      if (subPeriod === 'duha') return 'duha';
      return 'midday';
    }
    case 'dhuhr_to_asr':
      return 'dhuhr';
    case 'asr_to_maghrib':
      return 'asr';
  }
}
