import {
  getSunriseToDhuhrSubPeriod,
  type ComputedIslamicDay,
  type IslamicPhaseId,
  type RingSegment,
} from '@islamic-day-dial/core';
import { toDisplayAngle } from '../config/ring-anchor';
import { describeArc, polarToXY } from '../lib/geometry';
import { getSegmentGradientStops, getSweepSubArcs, type MirrorSegment } from '../lib/segment-gradients';
import { getCurrentMarkerVisualState } from '../lib/current-marker';
import { CurrentMarker, CurrentMarkerDefs } from './CurrentMarker';

export type Clock12Anchor = 'maghrib' | 'midday';

type Props = {
  snapshot: ComputedIslamicDay;
  /** Для джума-подсветки (пятница) и границ времени */
  now?: Date;
  size?: number;
  /** 12 часов сверху: Maghrib (начало исламского дня) или Midday (полдень) */
  clock12Anchor?: Clock12Anchor;
};

/** Primary: Fajr, Dhuhr, Asr, Maghrib, Isha — short ticks */
const PRIMARY_MARKER_IDS = new Set<string>(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);

/** Secondary: Sunrise, Midnight, Last 3rd, Duha boundaries — tick marks */
const SECONDARY_MARKER_IDS = new Set<string>(['sunrise', 'last_third_start', 'duha_start', 'duha_end']);

const MARKER_STROKE = '#fbeccb';

/** Gap segments + Isha group: all use same dark color */
const GAP_SEGMENT_IDS = new Set<string>(['last_third_to_fajr']);

/** Both Isha arcs use same dark color (ringGap) */
const ISHA_DARK_SEGMENT_IDS = new Set<string>(['isha_to_midnight', 'last_third_to_fajr']);

/** When in any of these 2 night sectors, highlight both */
const NIGHT_SECTORS_GROUP = new Set<string>(['isha_to_midnight', 'last_third_to_fajr']);

const MARKER_R = 14;

/** Last third breathing: 2 cycles per 10s = 5s per cycle */
const LAST_THIRD_BREATHE = {
  duration: 5,
  blur: 10,
  strokeWidth: 45,
  color: 'rgba(3, 99, 255, 0.9)',
};

/** Glow: blur (сила), strokeWidth (ширина), opacity, color */
const ISHA_GLOW = { blur: 4, opacity: 0.35, strokeWidth: 6, color: 'rgba(59, 130, 246, 1)' };
/** Last third: peakOpacity — максимальная яркость при нарастании (0–1) */
const LAST_THIRD_GLOW = { blur: 6, opacity: 0.35, strokeWidth: 10, color: 'rgba(59, 130, 246, 1)', peakOpacity: 0.7 };
/** Скорость мерцания glow Last 3rd (секунды на полный цикл ISHA→ярко→ISHA) */
const LAST_THIRD_GLOW_PULSE_DURATION = 3;

/**
 * Джума (пятница): яркость, размытие, ширина и пульс подсветки DUHA + MIDDAY + DHUHR.
 * (Отдельно от ISHA_GLOW / LAST_THIRD_GLOW — меняйте здесь, не трогая ночные сектора.)
 */
const JUMU_GLOW = {
  pulseDuration: 3,
  baseBlur: 3,
  peakBlur: 5,
  baseOpacity: 0.35,
  peakOpacity: 1.4,
  baseStrokeExtra: 6,
  peakStrokeExtra: 7,
};

/**
 * Пятница: подсветка трёх дуг только пока маркер в DUHA, MIDDAY или DHUHR.
 * Нет в SUNRISE, Fajr, ночи (Maghrib…Last 3rd), Asr→Maghrib.
 */
function isJumuahGlowWindow(
  now: Date,
  timeline: ComputedIslamicDay['timeline'],
  currentPhase: IslamicPhaseId,
): boolean {
  if (now.getDay() !== 5) return false;
  if (currentPhase === 'dhuhr_to_asr') return true;
  if (currentPhase === 'sunrise_to_dhuhr') {
    const sub = getSunriseToDhuhrSubPeriod(now, timeline.sunrise, timeline.dhuhr);
    return sub === 'duha' || sub === 'midday';
  }
  return false;
}

function getDisplaySegments(
  segments: RingSegment[],
  currentPhase: IslamicPhaseId,
): Array<{
  id: string;
  startAngleDeg: number;
  endAngleDeg: number;
  isGap: boolean;
}> {
  return segments.map((seg) => {
    const isGap = GAP_SEGMENT_IDS.has(seg.id) || ISHA_DARK_SEGMENT_IDS.has(seg.id);
    return {
      id: seg.id,
      startAngleDeg: seg.startAngleDeg,
      endAngleDeg: seg.endAngleDeg,
      isGap,
    };
  });
}

export function IslamicRing({ snapshot, now = new Date(), size = 420, clock12Anchor = 'maghrib' }: Props) {
  const cx = size / 2;
  const cy = size / 2;
  const ringStroke = size * 0.081;
  const ringInner = size * 0.25125;
  const ringR = ringInner + ringStroke / 2;

  const { ring, currentPhase } = snapshot;
  const { timeline } = snapshot;
  const dhuhrMarker = ring.markers.find((m) => m.id === 'dhuhr');
  const offsetDeg =
    clock12Anchor === 'midday' && dhuhrMarker ? -dhuhrMarker.angleDeg : 0;
  const toD = (a: number) => toDisplayAngle(a, offsetDeg);

  const progressAngle = toD(ring.progress * 360);
  const displaySegments = getDisplaySegments(ring.segments, currentPhase).map(
    (s) => {
      let startAngleDeg = toD(s.startAngleDeg);
      let endAngleDeg = toD(s.endAngleDeg);
      // Нормализация при переходе через 0° ( sunrise_to_dhuhr при anchor=midday )
      if (endAngleDeg <= startAngleDeg) endAngleDeg += 360;
      return { ...s, startAngleDeg, endAngleDeg };
    },
  );
  const inIshaSector = NIGHT_SECTORS_GROUP.has(currentPhase);

  const mirrorSegment: MirrorSegment | null = (() => {
    const asrMarker = ring.markers.find((m) => m.id === 'asr');
    const ishaMarker = ring.markers.find((m) => m.id === 'isha');
    const fajrMarker = ring.markers.find((m) => m.id === 'fajr');
    if (!asrMarker || !ishaMarker || !fajrMarker) return null;
    const asrAngle = toD(asrMarker.angleDeg);
    const ishaAngle = toD(ishaMarker.angleDeg);
    const fajrAngle = toD(fajrMarker.angleDeg);
    const asrToIshaSpanDeg = (360 - asrAngle + ishaAngle + 360) % 360;
    return { startAngleDeg: fajrAngle, spanDeg: asrToIshaSpanDeg };
  })();

  const showJumuahGlow = isJumuahGlowWindow(now, snapshot.timeline, currentPhase);
  const duhaStartMarker = ring.markers.find((m) => m.id === 'duha_start');
  const asrMarker = ring.markers.find((m) => m.id === 'asr');
  const sunriseToDhuhrSeg = displaySegments.find((s) => s.id === 'sunrise_to_dhuhr');
  const dhuhrToAsrSeg = displaySegments.find((s) => s.id === 'dhuhr_to_asr');
  const jumuGradSunriseDhuhr =
    sunriseToDhuhrSeg != null ? 'grad-sunrise_to_dhuhr' : null;
  const jumuGradDhuhrAsr =
    dhuhrToAsrSeg != null ? 'grad-dhuhr_to_asr' : null;

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
          <feGaussianBlur stdDeviation={ISHA_GLOW.blur} result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
          </feMerge>
        </filter>
        <filter id="glow-last-third" filterUnits="userSpaceOnUse" x="0" y="0" width={size} height={size}>
          <feGaussianBlur stdDeviation={LAST_THIRD_GLOW.blur} result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
          </feMerge>
        </filter>
        <filter id="glow-jumu-base" filterUnits="userSpaceOnUse" x="0" y="0" width={size} height={size}>
          <feGaussianBlur stdDeviation={JUMU_GLOW.baseBlur} result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
          </feMerge>
        </filter>
        <filter id="glow-jumu-peak" filterUnits="userSpaceOnUse" x="0" y="0" width={size} height={size}>
          <feGaussianBlur stdDeviation={JUMU_GLOW.peakBlur} result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
          </feMerge>
        </filter>
        {/* Gradients for Jumu'ah glow + sun neon */}
        {displaySegments
          .filter((s) => s.id === 'sunrise_to_dhuhr' || s.id === 'dhuhr_to_asr' || s.id === 'asr_to_maghrib')
          .map((seg) => {
            const stops = getSegmentGradientStops(seg.id as IslamicPhaseId);
            const start = polarToXY(cx, cy, ringR, seg.startAngleDeg);
            const end = polarToXY(cx, cy, ringR, seg.endAngleDeg);
            return (
              <linearGradient
                key={`grad-${seg.id}`}
                id={`grad-${seg.id}`}
                x1={start.x}
                y1={start.y}
                x2={end.x}
                y2={end.y}
                gradientUnits="userSpaceOnUse"
              >
                {stops.map((s, i) => (
                  <stop key={i} offset={`${s.offset}%`} stopColor={s.color} />
                ))}
              </linearGradient>
            );
          })}
      </defs>

      {/* Last third: soft breathing halo when marker is in this sector */}
      {currentPhase === 'last_third_to_fajr' &&
        (() => {
          const seg = displaySegments.find((s) => s.id === 'last_third_to_fajr');
          if (!seg) return null;
          const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
          if (!path) return null;
          return (
            <g
              key="breathing-last-third"
              filter="url(#glow-last-third)"
              className="last-third-breathe"
              style={{ ['--last-third-breathe-duration' as string]: `${LAST_THIRD_BREATHE.duration}s` }}
            >
              <path
                d={path}
                fill="none"
                stroke={LAST_THIRD_BREATHE.color}
                strokeWidth={LAST_THIRD_BREATHE.strokeWidth}
                strokeLinecap="butt"
              />
            </g>
          );
        })()}

      {/* Isha glow only: keep ring bright, but add neon halo when marker is inside Isha sectors */}
      {inIshaSector &&
        displaySegments
          .filter((seg) => NIGHT_SECTORS_GROUP.has(seg.id))
          .map((seg) => {
            const path = describeArc(cx, cy, ringR, seg.startAngleDeg, seg.endAngleDeg);
            if (!path) return null;
            const isLastThird = seg.id === 'last_third_to_fajr';
            const markerInLastThird = currentPhase === 'last_third_to_fajr';
            if (isLastThird && markerInLastThird) {
              return (
                <g
                  key={`glow-ish-${seg.id}`}
                  className="last-third-glow-pulse"
                  style={{
                    ['--last-third-glow-pulse-duration' as string]: `${LAST_THIRD_GLOW_PULSE_DURATION}s`,
                    ['--last-third-glow-peak-opacity' as string]: String(LAST_THIRD_GLOW.peakOpacity ?? 0.7),
                  }}
                >
                  <g filter="url(#glow-ish)" opacity={ISHA_GLOW.opacity} className="last-third-glow-base">
                    <path d={path} fill="none" stroke={ISHA_GLOW.color} strokeWidth={ringStroke + ISHA_GLOW.strokeWidth} strokeLinecap="butt" />
                  </g>
                  <g filter="url(#glow-last-third)" className="last-third-glow-peak">
                    <path d={path} fill="none" stroke={LAST_THIRD_GLOW.color} strokeWidth={ringStroke + LAST_THIRD_GLOW.strokeWidth} strokeLinecap="butt" />
                  </g>
                </g>
              );
            }
            return (
              <g key={`glow-ish-${seg.id}`} filter="url(#glow-ish)" opacity={ISHA_GLOW.opacity}>
                <path d={path} fill="none" stroke={ISHA_GLOW.color} strokeWidth={ringStroke + ISHA_GLOW.strokeWidth} strokeLinecap="butt" />
              </g>
            );
          })}

      {/* Jumu'ah: три дуги визуально — только пт. и маркер в DUHA / MIDDAY / DHUHR */}
      {showJumuahGlow &&
        duhaStartMarker &&
        dhuhrMarker &&
        asrMarker &&
        jumuGradSunriseDhuhr &&
        jumuGradDhuhrAsr &&
        (() => {
          const pathDuhaToDhuhr = describeArc(
            cx,
            cy,
            ringR,
            toD(duhaStartMarker.angleDeg),
            toD(dhuhrMarker.angleDeg),
          );
          const pathDhuhrToAsr = describeArc(
            cx,
            cy,
            ringR,
            toD(dhuhrMarker.angleDeg),
            toD(asrMarker.angleDeg),
          );
          if (!pathDuhaToDhuhr || !pathDhuhrToAsr) return null;
          const wBase = ringStroke + JUMU_GLOW.baseStrokeExtra;
          const wPeak = ringStroke + JUMU_GLOW.peakStrokeExtra;
          return (
            <g
              key="jumuah-glow"
              className="last-third-glow-pulse"
              style={{
                ['--last-third-glow-pulse-duration' as string]: `${JUMU_GLOW.pulseDuration}s`,
                ['--last-third-glow-peak-opacity' as string]: String(JUMU_GLOW.peakOpacity),
              }}
            >
              <g filter="url(#glow-jumu-base)" opacity={JUMU_GLOW.baseOpacity} className="last-third-glow-base">
                <path
                  d={pathDuhaToDhuhr}
                  fill="none"
                  stroke={`url(#${jumuGradSunriseDhuhr})`}
                  strokeWidth={wBase}
                  strokeLinecap="butt"
                />
                <path
                  d={pathDhuhrToAsr}
                  fill="none"
                  stroke={`url(#${jumuGradDhuhrAsr})`}
                  strokeWidth={wBase}
                  strokeLinecap="butt"
                />
              </g>
              <g filter="url(#glow-jumu-peak)" className="last-third-glow-peak">
                <path
                  d={pathDuhaToDhuhr}
                  fill="none"
                  stroke={`url(#${jumuGradSunriseDhuhr})`}
                  strokeWidth={wPeak}
                  strokeLinecap="butt"
                />
                <path
                  d={pathDhuhrToAsr}
                  fill="none"
                  stroke={`url(#${jumuGradDhuhrAsr})`}
                  strokeWidth={wPeak}
                  strokeLinecap="butt"
                />
              </g>
            </g>
          );
        })()}

      {/* Sweep: sub-arcs with solid colors — follows the arc, no triangle, no seams */}
      {getSweepSubArcs(displaySegments, mirrorSegment).map((sub, i) => {
        const path = describeArc(cx, cy, ringR, sub.startAngleDeg, sub.endAngleDeg);
        if (!path) return null;
        return (
          <path
            key={`sweep-${i}`}
            d={path}
            fill="none"
            stroke={sub.color}
            strokeWidth={ringStroke}
            strokeLinecap="butt"
          />
        );
      })}

      {/* Markers — primary = short ticks, secondary = small dots; all from inner edge */}
      {ring.markers.map((m) => {
        const isPrimary = PRIMARY_MARKER_IDS.has(m.id);
        const isSecondary = SECONDARY_MARKER_IDS.has(m.id);
        const tickStrokeWidth = 1.2;
        const tickLen = size * 0.0125; // чуть короче, чтобы не "залезали" в сегменты
        const tickStartR = ringInner - tickStrokeWidth / 2; // начинаем строго внутри
        const tickEndR = tickStartR - tickLen;
        const angle = toD(m.angleDeg);
        const inner = polarToXY(cx, cy, tickStartR, angle);

        if (isPrimary || isSecondary) {
          const outer = polarToXY(cx, cy, tickEndR, angle);
          return (
            <line
              key={m.id}
              x1={inner.x}
              y1={inner.y}
              x2={outer.x}
              y2={outer.y}
              stroke={MARKER_STROKE}
              strokeWidth={tickStrokeWidth}
              strokeLinecap="butt"
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
        const sunriseMarker = ring.markers.find((m) => m.id === 'sunrise');
        const maghribMarker = ring.markers.find((m) => m.id === 'maghrib');
        const sunriseBoundary = sunriseMarker
          ? polarToXY(cx, cy, ringR, toD(sunriseMarker.angleDeg))
          : null;
        const maghribBoundary = maghribMarker
          ? polarToXY(cx, cy, ringR, toD(maghribMarker.angleDeg))
          : null;
        return (
          <CurrentMarker
            x={pos.x}
            y={pos.y}
            r={MARKER_R}
            size={size}
            state={markerState}
            currentPhase={currentPhase}
            progressAngle={progressAngle}
            sunriseAngleDeg={sunriseMarker ? toD(sunriseMarker.angleDeg) : 0}
            maghribAngleDeg={maghribMarker ? toD(maghribMarker.angleDeg) : 0}
            centerX={cx}
            centerY={cy}
            sunriseBoundary={sunriseBoundary}
            maghribBoundary={maghribBoundary}
          />
        );
      })()}
    </svg>
  );
}
