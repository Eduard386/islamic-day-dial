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
const SECONDARY_MARKER_IDS = new Set<string>(['sunrise', 'islamic_midnight', 'last_third_start']);

const MARKER_STROKE = 'rgba(200, 198, 220, 0.8)';

/** Gap segments: deep dark */
const GAP_SEGMENT_IDS = new Set<string>(['midnight_to_last_third', 'last_third_to_fajr']);

/** Segments needing fixed light glow (dark gradients or gap) — otherwise midColor is too dark */
const LIGHT_GLOW_SEGMENTS = new Set<string>([
  'maghrib_to_isha',
  'isha_to_midnight',
  'fajr_to_sunrise',
  'asr_to_maghrib',
  'midnight_to_last_third',
  'last_third_to_fajr',
]);

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
  return segments.map((seg) => {
    const isGap = GAP_SEGMENT_IDS.has(seg.id);
    const isActive = seg.id === currentPhase;
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

  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      style={{ display: 'block' }}
    >
      <defs>
        <filter id="glow-active" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
          </feMerge>
        </filter>
        <CurrentMarkerDefs r={MARKER_R} />
        {/* Segment gradients — direction from start to end of arc */}
        {displaySegments
          .filter((s) => !s.isGap)
          .map((seg) => {
            const grad = seg.isActive
              ? SEGMENT_GRADIENTS_ACTIVE[seg.id as IslamicPhaseId]
              : SEGMENT_GRADIENTS[seg.id as IslamicPhaseId];
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

      {/* Halo — active segment; use fixed light color for dark/gap segments */}
      {displaySegments
        .filter((s) => s.isActive)
        .map((seg) => {
          const grad = SEGMENT_GRADIENTS_ACTIVE[seg.id as IslamicPhaseId];
          const midColor = grad.stops[Math.floor(grad.stops.length / 2)]?.color ?? grad.stops[0]!.color;
          const glowColor = LIGHT_GLOW_SEGMENTS.has(seg.id)
            ? 'rgba(230, 210, 255, 0.85)'
            : midColor;
          const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
          if (!path) return null;
          return (
            <g key={`glow-${seg.id}`} filter="url(#glow-active)" opacity={0.28}>
              <path
                d={path}
                fill="none"
                stroke={glowColor}
                strokeWidth={ringStroke + 6}
                strokeLinecap="butt"
              />
            </g>
          );
        })}


      {/* Segments — gradients, inactive dimmer, gaps darkest */}
      {displaySegments.map((seg) => {
        const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
        if (!path) return null;
        const opacity = seg.isGap ? 1 : seg.isActive ? 1 : 0.65;
        const stroke =
          seg.isGap ? COLORS.ringGap : `url(#grad-${seg.id}-${seg.isActive})`;
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

        if (isPrimary) {
          const tickLen = size * 0.032;
          const outer = polarToXY(cx, cy, ringInner - tickLen, m.angleDeg);
          return (
            <line
              key={m.id}
              x1={inner.x}
              y1={inner.y}
              x2={outer.x}
              y2={outer.y}
              stroke={MARKER_STROKE}
              strokeWidth={1.8}
              strokeLinecap="round"
            />
          );
        }
        if (isSecondary) {
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
