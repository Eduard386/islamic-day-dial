import type { IslamicPhaseId } from '@islamic-day-dial/core';
import type { CurrentMarkerState } from '../lib/current-marker';

type Props = {
  x: number;
  y: number;
  r: number;
  size: number;
  state: CurrentMarkerState;
  currentPhase: IslamicPhaseId;
  /** Угол маркера (0–360). Для roll-out/roll-in у границ Sunrise и Maghrib */
  progressAngle: number;
  sunriseAngleDeg: number;
  maghribAngleDeg: number;
  /** Центр циферблата — чтобы срез маски шёл по radial (риска Sunrise/Maghrib) */
  centerX: number;
  centerY: number;
  /** Точка границы на кольце — отрез по уровню риски */
  sunriseBoundary?: { x: number; y: number } | null;
  maghribBoundary?: { x: number; y: number } | null;
};

/** Зона перехода в градусах */
const ROLL_ZONE_DEG = 10;
/** Минимальная видимая доля — чтобы маркер не исчезал полностью на границе */
const MIN_REVEAL = 0.12;

/** Absolutely black — blends with night segments; only moon visible Maghrib→Fajr */
const DISK_FILL = '#000000';
const DISK_STROKE = '#000000';
const MOON_FILL = '#e8dcc8';
/** Lunar: bluish-yellowish, muted, full-moon glow — Maghrib, Isha, Last Third */
const MOON_LUNAR_FILL = '#B0B0A8';
const MOON_INNER_R = 0.82; /** Moon circles radius as fraction of disk r */

/** Солнце: glow — здесь настраивать силу и охват свечения */
const SUN_GLOW = {
  stdDeviation: 14,    /** размытие (↑ = шире/мягче ореол) */
  filterSize: 700,    /** % относительно маркера (x/y/width/height) */
};

/** = JUMU_GLOW (IslamicRing) — неон солнца идентичен дню джума */
const SUN_NEON = {
  pulseDuration: 3,
  baseBlur: 3,
  peakBlur: 5,
  baseOpacity: 0.35,
  peakOpacity: 1.4,
  baseStrokeExtra: 6,
  peakStrokeExtra: 7,
};

/** Sectors where only moon is visible, ring background shows through */
const MOON_ONLY_PHASES = new Set<IslamicPhaseId>([
  'maghrib_to_isha',
  'isha_to_midnight',
  'last_third_to_fajr',
  'fajr_to_sunrise',
]);

/** Sunrise, Duha, Midday, Dhuhr, Asr — яркое солнце с пульсирующей волной */
const SUN_PHASES = new Set<IslamicPhaseId>([
  'sunrise_to_dhuhr',
  'dhuhr_to_asr',
  'asr_to_maghrib',
]);

/**
 * Маркер = солнце: вылазит в начале Sunrise, залазит в конце Asr (Maghrib).
 * reveal, boundaryAngle, isRollIn (направление градиента).
 *
 * ⚠️ ASR (roll-in, isRollIn=true): НЕ МЕНЯТЬ. Отрез по уровню риски (maghribBoundary),
 * исчезает часть за риской. GradStops: white 0..reveal. Сдвиг градиента через bound.
 */
function getBlackDiskReveal(
  progressAngle: number,
  sunriseAngleDeg: number,
  maghribAngleDeg: number,
  isMoonOnlySector: boolean,
): { reveal: number; boundaryAngle: number; isRollIn: boolean } {
  const norm = (a: number) => ((a % 360) + 360) % 360;
  const pa = norm(progressAngle);
  const sun = norm(sunriseAngleDeg);
  const mag = norm(maghribAngleDeg);

  /* В Fajr — только луна, без чёрного фона. Солнце появляется только в sunrise_to_dhuhr */
  if (isMoonOnlySector) {
    return { reveal: 0, boundaryAngle: 0, isRollIn: false };
  }

  const rollOutEndRaw = sun + ROLL_ZONE_DEG;
  if (rollOutEndRaw <= 360) {
    if (pa >= sun && pa <= rollOutEndRaw) {
      const raw = (pa - sun) / ROLL_ZONE_DEG;
      return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: sun, isRollIn: false };
    }
  } else {
    if (pa >= sun) {
      const raw = (pa - sun) / ROLL_ZONE_DEG;
      return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: sun, isRollIn: false };
    }
    if (pa <= rollOutEndRaw - 360) {
      const raw = (pa + 360 - sun) / ROLL_ZONE_DEG;
      return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: sun, isRollIn: false };
    }
  }
  const rollInStart = norm(mag - ROLL_ZONE_DEG);
  if (rollInStart > mag && pa >= rollInStart) {
    const raw = (360 - pa) / ROLL_ZONE_DEG;
    return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: mag, isRollIn: true };
  }
  if (rollInStart <= mag && pa >= rollInStart && pa <= mag) {
    const raw = (mag - pa) / ROLL_ZONE_DEG;
    return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: mag, isRollIn: true };
  }
  return { reveal: 1, boundaryAngle: 0, isRollIn: false };
}


export function CurrentMarker({ x, y, r, size, state, currentPhase, progressAngle, sunriseAngleDeg, maghribAngleDeg, centerX, centerY, sunriseBoundary, maghribBoundary }: Props) {
  const { isNight, moonPhase, hijriDayUsed } = state;
  const innerR = r * MOON_INNER_R;
  const isMoonOnlySector = MOON_ONLY_PHASES.has(currentPhase);
  const crescentMaskId = `crescent-mask-${hijriDayUsed}`;
  const { reveal, boundaryAngle, isRollIn } = getBlackDiskReveal(progressAngle, sunriseAngleDeg, maghribAngleDeg, isMoonOnlySector);

  return (
    <g transform={`translate(${x}, ${y})`}>
      {isMoonOnlySector && moonPhase && moonPhase.shadowOffset !== 0 && (
        <defs>
          <mask id={crescentMaskId}>
            <circle r={innerR} fill="white" />
            <circle r={innerR} cx={moonPhase.shadowOffset * innerR} cy={0} fill="black" />
          </mask>
        </defs>
      )}
      <g clipPath="url(#marker-disk-clip)">
        {/* Base disk: пред-roll-out, roll-out, roll-in — солнце с самого начала Sunrise */}
        {reveal > 0 && (
          (() => {
            const isBrightSun = SUN_PHASES.has(currentPhase);
            if (reveal >= 1) {
              const diskFill = isBrightSun ? 'url(#sun-fill)' : DISK_FILL;
              const diskStroke = isBrightSun ? '#ffa000' : DISK_STROKE;
              const diskFilter = isBrightSun ? 'url(#sun-glow)' : undefined;
              return (
                <>
                  {isBrightSun && (() => {
                    const ringStroke = size * 0.081;
                    const wBase = ringStroke + SUN_NEON.baseStrokeExtra;
                    const wPeak = ringStroke + SUN_NEON.peakStrokeExtra;
                    const gradId = `grad-${currentPhase}`;
                    return (
                      <g
                        className="last-third-glow-pulse"
                        style={{
                          ['--last-third-glow-pulse-duration' as string]: `${SUN_NEON.pulseDuration}s`,
                          ['--last-third-glow-peak-opacity' as string]: String(SUN_NEON.peakOpacity),
                        }}
                      >
                        <g filter="url(#glow-jumu-base)" opacity={SUN_NEON.baseOpacity} className="last-third-glow-base">
                          <circle r={r} fill="none" stroke={`url(#${gradId})`} strokeWidth={wBase} />
                        </g>
                        <g filter="url(#glow-jumu-peak)" className="last-third-glow-peak">
                          <circle r={r} fill="none" stroke={`url(#${gradId})`} strokeWidth={wPeak} />
                        </g>
                      </g>
                    );
                  })()}
                  <circle r={r} fill={diskFill} stroke={diskStroke} strokeWidth={isBrightSun ? 0.5 : 1} filter={diskFilter} />
                </>
              );
            }
            const degToRad = (d: number) => ((d - 90) * Math.PI) / 180;
            /* Градиент по boundaryAngle — отрез по уровню риски. Asr: без flip. Sunrise: поменять видимый/невидимый */
            const tangentDeg = boundaryAngle + 90;
            const tanX = Math.cos(degToRad(tangentDeg));
            const tanY = Math.sin(degToRad(tangentDeg));
            const k = r * 2;
            const maskId = `black-disk-mask-${hijriDayUsed}-${reveal.toFixed(2)}`;
            const gradStops = isRollIn
              ? /* ASR: не менять — откус по риске, скрывается часть за Maghrib */
                [
                  <stop key="0" offset={0} stopColor="white" />,
                  <stop key="1" offset={reveal} stopColor="white" />,
                  <stop key="2" offset={reveal} stopColor="black" />,
                  <stop key="3" offset={1} stopColor="black" />,
                ]
              : /* SUNRISE roll-out: НЕ МЕНЯТЬ — откус по риске, видна часть за ней */
                [
                  <stop key="0" offset={0} stopColor="black" />,
                  <stop key="1" offset={1 - reveal} stopColor="black" />,
                  <stop key="2" offset={1 - reveal} stopColor="white" />,
                  <stop key="3" offset={1} stopColor="white" />,
                ];
            /* SUNRISE roll-out: НЕ МЕНЯТЬ. Срез через центр циферблата (локальные coord маркера).
             * Видна только та часть маркера, которая визуально пересекла риску Sunrise по часовой. */
            const bound = isRollIn ? maghribBoundary : null;
            const lenSq = tanX * tanX + tanY * tanY;
            const shift = lenSq > 0.001
              ? isRollIn && bound
                ? (tanX * (bound.x - x) + tanY * (bound.y - y) - k * (2 * reveal - 1)) / lenSq
                : (tanX * (centerX - x) + tanY * (centerY - y)) / lenSq - k * (1 - 2 * reveal)
              : 0;
            const dx = shift * tanX;
            const dy = shift * tanY;
            const diskFill = isBrightSun ? 'url(#sun-fill)' : DISK_FILL;
            const diskStroke = isBrightSun ? '#ffa000' : DISK_STROKE;
            const diskFilter = isBrightSun ? 'url(#sun-glow)' : undefined;
            return (
              <>
                <defs>
                  <mask id={maskId} maskContentUnits="userSpaceOnUse">
                    <linearGradient
                      id={`${maskId}-grad`}
                      x1={-tanX * k + dx}
                      y1={-tanY * k + dy}
                      x2={tanX * k + dx}
                      y2={tanY * k + dy}
                      gradientUnits="userSpaceOnUse"
                    >
                      {gradStops}
                    </linearGradient>
                    <rect x={-k} y={-k} width={k * 2} height={k * 2} fill={`url(#${maskId}-grad)`} />
                  </mask>
                </defs>
                {isBrightSun && (() => {
                  const ringStroke = size * 0.081;
                  const wBase = ringStroke + SUN_NEON.baseStrokeExtra;
                  const wPeak = ringStroke + SUN_NEON.peakStrokeExtra;
                  const gradId = `grad-${currentPhase}`;
                  return (
                    <g
                      className="last-third-glow-pulse"
                      style={{
                        ['--last-third-glow-pulse-duration' as string]: `${SUN_NEON.pulseDuration}s`,
                        ['--last-third-glow-peak-opacity' as string]: String(SUN_NEON.peakOpacity),
                      }}
                    >
                      <g filter="url(#glow-jumu-base)" opacity={SUN_NEON.baseOpacity} className="last-third-glow-base">
                        <circle r={r} fill="none" stroke={`url(#${gradId})`} strokeWidth={wBase} mask={`url(#${maskId})`} />
                      </g>
                      <g filter="url(#glow-jumu-peak)" className="last-third-glow-peak">
                        <circle r={r} fill="none" stroke={`url(#${gradId})`} strokeWidth={wPeak} mask={`url(#${maskId})`} />
                      </g>
                    </g>
                  );
                })()}
                <circle r={r} fill={diskFill} stroke={diskStroke} strokeWidth={isBrightSun ? 0.5 : 1} mask={`url(#${maskId})`} filter={diskFilter} />
              </>
            );
          })()
        )}
        {/* Night: луна всегда, даже если торчит за риску Sunrise */}
        {isNight && moonPhase && (
          <g>
            {isMoonOnlySector ? (
              /* Night: lunar silver-blue, ring background shows through where shadow was */
              moonPhase.shadowOffset === 0 ? (
                <>
                  <circle r={innerR} fill={MOON_LUNAR_FILL} filter="url(#moon-lunar-glow)" opacity={0.85} />
                  <circle r={innerR} fill={MOON_LUNAR_FILL} />
                </>
              ) : (
                <>
                  {/* Glow + crescent: both masked so shadow area shows ring, not moon */}
                  <circle r={innerR} fill={MOON_LUNAR_FILL} filter="url(#moon-lunar-glow)" opacity={0.85} mask={`url(#${crescentMaskId})`} />
                  <circle r={innerR} fill={MOON_LUNAR_FILL} mask={`url(#${crescentMaskId})`} />
                </>
              )
            ) : (
              /* Fallback: lit + shadow (black disk behind) */
              <>
                <circle r={innerR} fill={MOON_FILL} filter="url(#moon-glow)" opacity={1} />
                <circle r={innerR} fill={MOON_FILL} />
                {moonPhase.shadowOffset !== 0 && (
                  <circle
                    r={innerR}
                    cx={moonPhase.shadowOffset * innerR}
                    cy={0}
                    fill={DISK_FILL}
                  />
                )}
              </>
            )}
          </g>
        )}
      </g>
    </g>
  );
}

/** ClipPath and glow filters for marker */
export function CurrentMarkerDefs({ r }: { r: number }) {
  return (
    <>
      <filter id="moon-glow" x="-80%" y="-80%" width="260%" height="260%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
        </feMerge>
      </filter>
      <filter id="moon-lunar-glow" x="-100%" y="-100%" width="300%" height="300%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="3.5" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>
      <filter
        id="sun-glow"
        x={`-${(SUN_GLOW.filterSize - 100) / 2}%`}
        y={`-${(SUN_GLOW.filterSize - 100) / 2}%`}
        width={`${SUN_GLOW.filterSize}%`}
        height={`${SUN_GLOW.filterSize}%`}
      >
        <feGaussianBlur in="SourceGraphic" stdDeviation={SUN_GLOW.stdDeviation} result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>
      <radialGradient id="sun-fill" cx="0.5" cy="0.5" r="0.5">
        <stop offset="0" stopColor="#ffffff" />
        <stop offset="0.3" stopColor="#fffde7" />
        <stop offset="0.6" stopColor="#fff59d" />
        <stop offset="1" stopColor="#ffca28" />
      </radialGradient>
      <clipPath id="marker-disk-clip" clipPathUnits="objectBoundingBox">
        <circle cx="0.5" cy="0.5" r="0.5" />
      </clipPath>
    </>
  );
}
