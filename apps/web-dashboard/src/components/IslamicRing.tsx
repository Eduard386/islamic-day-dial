import type { ComputedIslamicDay, IslamicPhaseId, RingSegment } from '@islamic-day-dial/core';
import { describeArc, polarToXY } from '../lib/geometry';
import { COLORS } from '../lib/colors';
import { SEGMENT_GRADIENTS, SEGMENT_GRADIENTS_ACTIVE } from '../lib/segment-gradients';

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

/** Night phases: show moon instead of black pearl */
const NIGHT_PHASES = new Set<IslamicPhaseId>([
  'isha_to_midnight',
  'midnight_to_last_third',
  'last_third_to_fajr',
]);

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
  const ringR = size * 0.38;
  const ringStroke = size * 0.09;
  const ringInner = ringR - ringStroke / 2;

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
        <radialGradient id="pearl" cx="40%" cy="35%" r="60%">
          <stop offset="0%" stopColor="#505068" />
          <stop offset="50%" stopColor="#1a1a2e" />
          <stop offset="100%" stopColor="#08080e" />
        </radialGradient>
        <radialGradient id="moon" cx="35%" cy="30%" r="65%">
          <stop offset="0%" stopColor="#f5e6c8" />
          <stop offset="40%" stopColor="#e8c878" />
          <stop offset="100%" stopColor="#d4a04a" />
        </radialGradient>
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

      {/* Current position — moon at night, black pearl by day */}
      {(() => {
        const pos = polarToXY(cx, cy, ringR, progressAngle);
        const isNight = NIGHT_PHASES.has(currentPhase);
        return (
          <>
            <circle
              cx={pos.x}
              cy={pos.y}
              r={11.5}
              fill={isNight ? 'url(#moon)' : 'url(#pearl)'}
              stroke={isNight ? '#c9a04a' : '#404060'}
              strokeWidth={1.5}
            />
            <circle
              cx={pos.x - 2.2}
              cy={pos.y - 2.2}
              r={2.8}
              fill={isNight ? '#f0d8a0' : '#606080'}
              opacity={isNight ? 0.9 : 0.6}
            />
          </>
        );
      })()}
    </svg>
  );
}
