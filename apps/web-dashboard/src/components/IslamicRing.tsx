import type { ComputedIslamicDay, IslamicPhaseId, RingSegment } from '@islamic-day-dial/core';
import { describeArc, polarToXY } from '../lib/geometry';
import { COLORS } from '../lib/colors';
import { SEGMENT_GRADIENTS, SEGMENT_GRADIENTS_ACTIVE } from '../lib/segment-gradients';

type Props = {
  snapshot: ComputedIslamicDay;
  size?: number;
};

const MARKER_LABELS: Record<string, string> = {
  maghrib: 'Maghrib',
  isha: 'Isha',
  islamic_midnight: 'Midnight',
  last_third_start: 'Last 3rd',
  fajr: 'Fajr',
  sunrise: 'Sunrise',
  dhuhr: 'Dhuhr',
  asr: 'Asr',
};

/** Gap segments: deep dark */
const GAP_SEGMENT_IDS = new Set<string>(['midnight_to_last_third', 'last_third_to_fajr']);

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
          <feGaussianBlur stdDeviation="5" result="blur" />
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
          <stop offset="0%" stopColor="#fffef0" />
          <stop offset="40%" stopColor="#fef9c3" />
          <stop offset="100%" stopColor="#fde68a" />
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

      {/* Halo — only active segment, stronger */}
      {displaySegments
        .filter((s) => s.isActive && !s.isGap)
        .map((seg) => {
          const grad = SEGMENT_GRADIENTS_ACTIVE[seg.id as IslamicPhaseId];
          const midColor = grad.stops[Math.floor(grad.stops.length / 2)]?.color ?? grad.stops[0]!.color;
          const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
          if (!path) return null;
          return (
            <g key={`glow-${seg.id}`} filter="url(#glow-active)" opacity={0.4}>
              <path
                d={path}
                fill="none"
                stroke={midColor}
                strokeWidth={ringStroke + 16}
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

      {/* Ticks at segment junctions — inside ring, extending inward */}
      {ring.markers.map((m) => {
        const isPrimary = m.kind === 'primary' || m.id === 'islamic_midnight' || m.id === 'last_third_start';
        const tickLen = isPrimary ? size * 0.05 : size * 0.04;
        const inner = polarToXY(cx, cy, ringInner, m.angleDeg);
        const outer = polarToXY(cx, cy, ringInner - tickLen, m.angleDeg);
        const labelPt = polarToXY(cx, cy, ringR + ringStroke / 2 + (isPrimary ? 16 : 12), m.angleDeg);

        return (
          <g key={m.id}>
            <line
              x1={inner.x}
              y1={inner.y}
              x2={outer.x}
              y2={outer.y}
              stroke="rgba(255,255,255,0.95)"
              strokeWidth={isPrimary ? 2.2 : 1.5}
              strokeLinecap="round"
            />
            <text
              x={labelPt.x}
              y={labelPt.y}
              fill={isPrimary ? COLORS.text : COLORS.textSecondary}
              fontSize={isPrimary ? 10 : 9}
              fontWeight={isPrimary ? 600 : 400}
              textAnchor="middle"
              dominantBaseline="central"
              fontFamily="Inter, sans-serif"
            >
              {MARKER_LABELS[m.id] ?? m.id}
            </text>
          </g>
        );
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
              stroke={isNight ? '#e4d48c' : '#404060'}
              strokeWidth={1.5}
            />
            <circle
              cx={pos.x - 2.2}
              cy={pos.y - 2.2}
              r={2.8}
              fill={isNight ? '#fffef0' : '#606080'}
              opacity={isNight ? 0.9 : 0.6}
            />
          </>
        );
      })()}
    </svg>
  );
}
