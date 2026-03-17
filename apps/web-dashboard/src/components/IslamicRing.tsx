import type { ComputedIslamicDay, IslamicPhaseId, RingSegment } from '@islamic-day-dial/core';
import { describeArc, polarToXY } from '../lib/geometry';
import { SEGMENT_COLORS, SEGMENT_COLORS_ACTIVE, COLORS } from '../lib/colors';

type Props = {
  snapshot: ComputedIslamicDay;
  size?: number;
};

const MARKER_LABELS: Record<string, string> = {
  maghrib: 'Mgh',
  isha: 'Isha',
  islamic_midnight: 'Mid',
  last_third_start: '⅓',
  fajr: 'Fajr',
  sunrise: 'Rise',
  dhuhr: 'Dhr',
  asr: 'Asr',
};

/** Merged night segment: isha → fajr (Mid and ⅓ are markers only, no separate segments) */
const NIGHT_SEGMENT_IDS = new Set<IslamicPhaseId>([
  'isha_to_midnight',
  'midnight_to_last_third',
  'last_third_to_fajr',
]);

const NIGHT_COLOR = '#8b5cf6';
const NIGHT_COLOR_ACTIVE = '#a78bfa';

type DisplaySegment = {
  id: string;
  startAngleDeg: number;
  endAngleDeg: number;
  color: string;
  colorActive: string;
  isActive: boolean;
};

function getDisplaySegments(
  segments: RingSegment[],
  currentPhase: IslamicPhaseId,
): DisplaySegment[] {
  const result: DisplaySegment[] = [];
  let nightStart: number | null = null;
  let nightEnd: number | null = null;

  for (const seg of segments) {
    if (NIGHT_SEGMENT_IDS.has(seg.id as IslamicPhaseId)) {
      if (nightStart === null) nightStart = seg.startAngleDeg;
      nightEnd = seg.endAngleDeg;
      continue;
    }
    const isActive = seg.id === currentPhase;
    result.push({
      id: seg.id,
      startAngleDeg: seg.startAngleDeg,
      endAngleDeg: seg.endAngleDeg,
      color: SEGMENT_COLORS[seg.id as IslamicPhaseId],
      colorActive: SEGMENT_COLORS_ACTIVE[seg.id as IslamicPhaseId],
      isActive,
    });
  }

  if (nightStart !== null && nightEnd !== null) {
    const isActive =
      currentPhase === 'isha_to_midnight' ||
      currentPhase === 'midnight_to_last_third' ||
      currentPhase === 'last_third_to_fajr';
    result.splice(1, 0, {
      id: 'isha_to_fajr',
      startAngleDeg: nightStart,
      endAngleDeg: nightEnd,
      color: NIGHT_COLOR,
      colorActive: NIGHT_COLOR_ACTIVE,
      isActive,
    });
  }

  return result;
}

export function IslamicRing({ snapshot, size = 420 }: Props) {
  const cx = size / 2;
  const cy = size / 2;
  const ringR = size * 0.38;
  const ringStroke = size * 0.09;

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
        <filter id="glow-soft" x="-25%" y="-25%" width="150%" height="150%">
          <feGaussianBlur stdDeviation="4" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <radialGradient id="pearl" cx="40%" cy="35%" r="60%">
          <stop offset="0%" stopColor="#505068" />
          <stop offset="50%" stopColor="#1a1a2e" />
          <stop offset="100%" stopColor="#08080e" />
        </radialGradient>
      </defs>

      {/* Glow layer — filter on group for even glow */}
      <g filter="url(#glow-soft)" opacity={0.5}>
        {displaySegments.map((seg) => {
          const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
          if (!path) return null;
          return (
            <path
              key={`glow-${seg.id}`}
              d={path}
              fill="none"
              stroke={seg.isActive ? seg.colorActive : seg.color}
              strokeWidth={ringStroke + 14}
              strokeLinecap="round"
            />
          );
        })}
      </g>

      {/* Crisp segments */}
      {displaySegments.map((seg) => {
        const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
        if (!path) return null;
        const color = seg.isActive ? seg.colorActive : seg.color;
        return (
          <path
            key={seg.id}
            d={path}
            fill="none"
            stroke={color}
            strokeWidth={ringStroke}
            strokeLinecap="butt"
          />
        );
      })}

      {/* Marker ticks + labels */}
      {ring.markers.map((m) => {
        const isPrimary = m.kind === 'primary';
        const tickLen = isPrimary ? size * 0.035 : size * 0.025;
        const inner = polarToXY(cx, cy, ringR - ringStroke / 2 - 2, m.angleDeg);
        const outer = polarToXY(cx, cy, ringR - ringStroke / 2 - 2 - tickLen, m.angleDeg);
        const labelPt = polarToXY(cx, cy, ringR + ringStroke / 2 + (isPrimary ? 14 : 12), m.angleDeg);

        return (
          <g key={m.id}>
            <line
              x1={inner.x}
              y1={inner.y}
              x2={outer.x}
              y2={outer.y}
              stroke={isPrimary ? COLORS.markerPrimary : COLORS.markerSecondary}
              strokeWidth={isPrimary ? 2 : 1.2}
            />
            <text
              x={labelPt.x}
              y={labelPt.y}
              fill={isPrimary ? COLORS.text : COLORS.textSecondary}
              fontSize={isPrimary ? 11 : 9}
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

      {/* Current position — black pearl */}
      {(() => {
        const pos = polarToXY(cx, cy, ringR, progressAngle);
        return (
          <>
            <circle cx={pos.x} cy={pos.y} r={11} fill="#08080e" opacity={0.25} />
            <circle
              cx={pos.x}
              cy={pos.y}
              r={7}
              fill="url(#pearl)"
              stroke="#404060"
              strokeWidth={1}
            />
            <circle cx={pos.x - 1.5} cy={pos.y - 1.5} r={2} fill="#606080" opacity={0.6} />
          </>
        );
      })()}
    </svg>
  );
}
