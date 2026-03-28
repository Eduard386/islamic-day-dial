import {
  getJumuahGlowStrength,
  getSunriseToDhuhrSubPeriod,
  isJumuahGlowWindow,
  NIGHT_SECTORS_GROUP,
  type ComputedIslamicDay,
  type IslamicPhaseId,
  type RingSegment,
} from '@islamic-day-dial/core';
import { describeArc, polarToXY } from '../lib/geometry';
import { getSegmentGradientStops, getConicGradientCss, type MirrorSegment } from '../lib/segment-gradients';
import { getCurrentMarkerVisualState } from '../lib/current-marker';
import { CurrentMarker, CurrentMarkerDefs } from './CurrentMarker';

type Props = {
  snapshot: ComputedIslamicDay;
  /** Для джума-подсветки (пятница) и границ времени */
  now?: Date;
  size?: number;
};

/** Primary: Fajr, Dhuhr, Asr, Maghrib, Isha — short ticks */
const PRIMARY_MARKER_IDS = new Set<string>(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);

/** Secondary: Sunrise, Last 3rd, Duha boundaries — tick marks */
const SECONDARY_MARKER_IDS = new Set<string>(['sunrise', 'last_third_start', 'duha_start', 'duha_end']);

const MARKER_STROKE = '#fbeccb';

/** Gap segments + Isha group: all use same dark color */
const GAP_SEGMENT_IDS = new Set<string>(['last_third_to_fajr']);

/** Both Isha arcs use same dark color (ringGap) */
const ISHA_DARK_SEGMENT_IDS = new Set<string>(['isha_to_last_third', 'last_third_to_fajr']);

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
 * Джума (пятница): glow идёт от начала DUHA до конца DHUHR,
 * при этом интенсивность плавно растёт от слабой к полной.
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

export function IslamicRing({ snapshot, now = new Date(), size = 420 }: Props) {
  const cx = size / 2;
  const cy = size / 2;
  const ringStroke = size * 0.081;
  const ringInner = size * 0.25125;
  const ringR = ringInner + ringStroke / 2;

  const { ring, currentPhase } = snapshot;
  const progressAngle = ring.progress * 360;
  const displaySegments = getDisplaySegments(ring.segments, currentPhase);
  const inIshaSector = NIGHT_SECTORS_GROUP.has(currentPhase);

  const mirrorSegment: MirrorSegment | null = (() => {
    const asrMarker = ring.markers.find((m) => m.id === 'asr');
    const ishaMarker = ring.markers.find((m) => m.id === 'isha');
    const fajrMarker = ring.markers.find((m) => m.id === 'fajr');
    if (!asrMarker || !ishaMarker || !fajrMarker) return null;
    const asrAngle = asrMarker.angleDeg;
    const ishaAngle = ishaMarker.angleDeg;
    const fajrAngle = fajrMarker.angleDeg;
    const asrToIshaSpanDeg = (360 - asrAngle) + ishaAngle;
    return { startAngleDeg: fajrAngle, spanDeg: asrToIshaSpanDeg };
  })();

  const jumuahGlowStrength = getJumuahGlowStrength(now, snapshot.timeline, currentPhase, snapshot.hijriDate);
  const showJumuahGlow = isJumuahGlowWindow(now, snapshot.timeline, currentPhase, snapshot.hijriDate);
  const duhaStartMarker = ring.markers.find((m) => m.id === 'duha_start');
  const dhuhrMarker = ring.markers.find((m) => m.id === 'dhuhr');
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
      style={{ display: 'block', overflow: 'visible' }}
    >
      <defs>
        <CurrentMarkerDefs r={MARKER_R} />
        <mask id="ring-sweep-mask">
          <rect width={size} height={size} fill="black" />
          <circle cx={cx} cy={cy} r={ringInner + ringStroke} fill="white" />
          <circle cx={cx} cy={cy} r={ringInner} fill="black" />
        </mask>
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
        {/* Orange/red neon gradients for sunrise and maghrib sun */}
        {sunriseToDhuhrSeg && (
          <linearGradient
            key="grad-sunrise-neon"
            id="grad-sunrise-neon"
            x1={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.startAngleDeg).x}
            y1={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.startAngleDeg).y}
            x2={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.endAngleDeg).x}
            y2={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.endAngleDeg).y}
            gradientUnits="userSpaceOnUse"
          >
            <stop offset="0%" stopColor="#ffb74d" />
            <stop offset="100%" stopColor="#ff6f00" />
          </linearGradient>
        )}
        {(() => {
          const asrSeg = displaySegments.find((s) => s.id === 'asr_to_maghrib');
          return asrSeg ? (
            <linearGradient
              key="grad-maghrib-neon"
              id="grad-maghrib-neon"
              x1={polarToXY(cx, cy, ringR, asrSeg.startAngleDeg).x}
              y1={polarToXY(cx, cy, ringR, asrSeg.startAngleDeg).y}
              x2={polarToXY(cx, cy, ringR, asrSeg.endAngleDeg).x}
              y2={polarToXY(cx, cy, ringR, asrSeg.endAngleDeg).y}
              gradientUnits="userSpaceOnUse"
            >
              <stop offset="0%" stopColor="#ff6b6b" />
              <stop offset="100%" stopColor="#c62828" />
            </linearGradient>
          ) : null;
        })()}
        {sunriseToDhuhrSeg && (
          <linearGradient
            key="grad-midday-neon"
            id="grad-midday-neon"
            x1={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.startAngleDeg).x}
            y1={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.startAngleDeg).y}
            x2={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.endAngleDeg).x}
            y2={polarToXY(cx, cy, ringR, sunriseToDhuhrSeg.endAngleDeg).y}
            gradientUnits="userSpaceOnUse"
          >
            <stop offset="0%" stopColor="#ffd54f" />
            <stop offset="100%" stopColor="#d4a017" />
          </linearGradient>
        )}
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
          const s1 = duhaStartMarker.angleDeg;
          const e1 = dhuhrMarker.angleDeg;
          const s2 = dhuhrMarker.angleDeg;
          const e2 = asrMarker.angleDeg;
          const pathDuhaToDhuhr = describeArc(cx, cy, ringR, s1, e1);
          const pathDhuhrToAsr = describeArc(cx, cy, ringR, s2, e2);
          if (!pathDuhaToDhuhr || !pathDhuhrToAsr) return null;
          const wBase = ringStroke + JUMU_GLOW.baseStrokeExtra;
          const wPeak = ringStroke + JUMU_GLOW.peakStrokeExtra;
          return (
            <g
              key="jumuah-glow"
              className="last-third-glow-pulse"
              style={{
                ['--last-third-glow-pulse-duration' as string]: `${JUMU_GLOW.pulseDuration}s`,
                ['--last-third-glow-peak-opacity' as string]: String(JUMU_GLOW.peakOpacity * jumuahGlowStrength),
              }}
            >
              <g filter="url(#glow-jumu-base)" opacity={JUMU_GLOW.baseOpacity * jumuahGlowStrength} className="last-third-glow-base">
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

      {/* Sweep: conic gradient via foreignObject — smooth, no banding or moiré */}
      <foreignObject
        x={0}
        y={0}
        width={size}
        height={size}
        mask="url(#ring-sweep-mask)"
        style={{ overflow: 'hidden' }}
      >
        <div
          style={{
            width: size,
            height: size,
            background: getConicGradientCss(displaySegments, mirrorSegment),
          }}
        />
      </foreignObject>

      {/* Markers — короткие риски только внутрь от внутреннего края кольца (не пересекают цветную полосу) */}
      {ring.markers.map((m) => {
        const isPrimary = PRIMARY_MARKER_IDS.has(m.id);
        const isSecondary = SECONDARY_MARKER_IDS.has(m.id);
        const tickStrokeWidth = 1.2;
        const tickLen = size * 0.0125;
        const tickStartR = ringInner - tickStrokeWidth / 2;
        const tickEndR = tickStartR - tickLen;
        const angle = m.angleDeg;
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
          ? polarToXY(cx, cy, ringR, sunriseMarker.angleDeg)
          : null;
        const maghribBoundary = maghribMarker
          ? polarToXY(cx, cy, ringR, maghribMarker.angleDeg)
          : null;
        const sunriseToDhuhrSubPeriod =
          currentPhase === 'sunrise_to_dhuhr' && snapshot.timeline
            ? getSunriseToDhuhrSubPeriod(
                now ?? new Date(),
                snapshot.timeline.duhaStart,
                snapshot.timeline.dhuhr,
              )
            : null;
        const isInSunriseSubPeriod = sunriseToDhuhrSubPeriod === 'sunrise';
        const isInMiddaySubPeriod = sunriseToDhuhrSubPeriod === 'midday';
        return (
          <CurrentMarker
            x={pos.x}
            y={pos.y}
            r={MARKER_R}
            size={size}
            state={markerState}
            currentPhase={currentPhase}
            progressAngle={progressAngle}
            sunriseAngleDeg={sunriseMarker ? sunriseMarker.angleDeg : 0}
            maghribAngleDeg={maghribMarker ? maghribMarker.angleDeg : 0}
            centerX={cx}
            centerY={cy}
            sunriseBoundary={sunriseBoundary}
            maghribBoundary={maghribBoundary}
            isInSunriseSubPeriod={isInSunriseSubPeriod}
            isInMiddaySubPeriod={isInMiddaySubPeriod}
          />
        );
      })()}
    </svg>
  );
}
