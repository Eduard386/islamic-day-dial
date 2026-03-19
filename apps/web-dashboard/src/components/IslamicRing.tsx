import type { ComputedIslamicDay, IslamicPhaseId, RingSegment } from '@islamic-day-dial/core';
import { describeArc, polarToXY } from '../lib/geometry';
import { COLORS } from '../lib/colors';
import { SEGMENT_GRADIENTS, SEGMENT_GRADIENTS_ACTIVE } from '../lib/segment-gradients';
import { getCurrentMarkerVisualState } from '../lib/current-marker';
import { CurrentMarker, CurrentMarkerDefs } from './CurrentMarker';

type Props = {
  snapshot: ComputedIslamicDay;
  size?: number;
};

/** Primary: Fajr, Dhuhr, Asr, Maghrib, Isha — short ticks */
const PRIMARY_MARKER_IDS = new Set<string>(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);

/** Secondary: Sunrise, Midnight, Last 3rd — very short strokes */
const SECONDARY_MARKER_IDS = new Set<string>(['sunrise', 'last_third_start']);

const MARKER_STROKE = '#FFF8E7';

/** Gap segments + Isha group: all use same dark color */
const GAP_SEGMENT_IDS = new Set<string>(['last_third_to_fajr']);

/** Both Isha arcs use same dark color (ringGap) */
const ISHA_DARK_SEGMENT_IDS = new Set<string>(['isha_to_midnight', 'last_third_to_fajr']);

/** When in any of these 2 night sectors, highlight both */
const NIGHT_SECTORS_GROUP = new Set<string>(['isha_to_midnight', 'last_third_to_fajr']);

const MARKER_R = 11.5;

function getDisplaySegments(
  segments: RingSegment[],
  currentPhase: IslamicPhaseId,
): Array<{
  id: string;
  startAngleDeg: number;
  endAngleDeg: number;
  isActive: boolean;
  isGap: boolean;
}> {
  const inNightGroup = NIGHT_SECTORS_GROUP.has(currentPhase);
  return segments.map((seg) => {
    const isGap = GAP_SEGMENT_IDS.has(seg.id) || ISHA_DARK_SEGMENT_IDS.has(seg.id);
    const isActive =
      seg.id === currentPhase ||
      (inNightGroup && NIGHT_SECTORS_GROUP.has(seg.id));
    return {
      id: seg.id,
      startAngleDeg: seg.startAngleDeg,
      endAngleDeg: seg.endAngleDeg,
      isActive,
      isGap,
    };
  });
}

export function IslamicRing({ snapshot, size = 420 }: Props) {
  const cx = size / 2;
  const cy = size / 2;
  const ringStroke = size * 0.081;
  const ringInner = size * 0.25125;
  const ringR = ringInner + ringStroke / 2;

  const { ring, currentPhase } = snapshot;
  const progressAngle = ring.progress * 360;
  const displaySegments = getDisplaySegments(ring.segments, currentPhase);
  const inIshaSector = NIGHT_SECTORS_GROUP.has(currentPhase);

  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      style={{ display: 'block' }}
    >
      <defs>
        <CurrentMarkerDefs r={MARKER_R} />
        <filter id="glow-ish" filterUnits="userSpaceOnUse" x="0" y="0" width={size} height={size}>
          <feGaussianBlur stdDeviation="4" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
          </feMerge>
        </filter>
        {/* Segment gradients — direction from start to end of arc (Isha arcs use solid dark) */}
        {displaySegments
          .filter((s) => !s.isGap)
          .map((seg) => {
            const grad = SEGMENT_GRADIENTS_ACTIVE[seg.id as IslamicPhaseId];
            const start = polarToXY(cx, cy, ringR, seg.startAngleDeg);
            const end = polarToXY(cx, cy, ringR, seg.endAngleDeg);
            return (
              <linearGradient
                key={`grad-${seg.id}-${seg.isActive}`}
                id={`grad-${seg.id}-${seg.isActive}`}
                x1={start.x}
                y1={start.y}
                x2={end.x}
                y2={end.y}
                gradientUnits="userSpaceOnUse"
              >
                {grad.stops.map((s, i) => (
                  <stop key={i} offset={`${s.offset}%`} stopColor={s.color} />
                ))}
              </linearGradient>
            );
          })}
      </defs>

      {/* Isha glow only: keep ring bright, but add neon halo when marker is inside Isha sectors */}
      {inIshaSector &&
        displaySegments
          .filter((seg) => NIGHT_SECTORS_GROUP.has(seg.id))
          .map((seg) => {
            const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
            if (!path) return null;
            return (
              <g key={`glow-ish-${seg.id}`} filter="url(#glow-ish)" opacity={0.35}>
                <path
                  d={path}
                  fill="none"
                  stroke="rgba(59, 130, 246, 1)"
                  strokeWidth={ringStroke + 6}
                  strokeLinecap="butt"
                />
              </g>
            );
          })}

      {/* Segments — gradients, inactive dimmer; Isha arcs + gaps = same dark color */}
      {displaySegments.map((seg) => {
        const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
        if (!path) return null;
        const useDarkColor = seg.isGap;
        const opacity = 1;
        const stroke = useDarkColor ? COLORS.ringGap : `url(#grad-${seg.id}-${seg.isActive})`;
        return (
          <path
            key={seg.id}
            d={path}
            fill="none"
            stroke={stroke}
            strokeWidth={ringStroke}
            strokeLinecap="butt"
            opacity={opacity}
          />
        );
      })}

      {/* Markers — primary = short ticks, secondary = small dots; all from inner edge */}
      {ring.markers.map((m) => {
        const isPrimary = PRIMARY_MARKER_IDS.has(m.id);
        const isSecondary = SECONDARY_MARKER_IDS.has(m.id);
        const inner = polarToXY(cx, cy, ringInner, m.angleDeg);

        if (isPrimary || isSecondary) {
          const tickLen = size * 0.014;
          const outer = polarToXY(cx, cy, ringInner - tickLen, m.angleDeg);
          return (
            <line
              key={m.id}
              x1={inner.x}
              y1={inner.y}
              x2={outer.x}
              y2={outer.y}
              stroke={MARKER_STROKE}
              strokeWidth={1.2}
              strokeLinecap="round"
            />
          );
        }
        return null;
      })}

      {/* Current position — minimal disk, moon phase at night */}
      {(() => {
        const pos = polarToXY(cx, cy, ringR, progressAngle);
        const markerState = getCurrentMarkerVisualState(
          currentPhase,
          snapshot.hijriDate,
        );
        return (
          <CurrentMarker
            x={pos.x}
            y={pos.y}
            r={MARKER_R}
            state={markerState}
          />
        );
      })()}
    </svg>
  );
}
