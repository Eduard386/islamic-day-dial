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
  /** true = сектор "Sunrise" (первые 20 мин): солнце оранжевое */
  isInSunriseSubPeriod?: boolean;
  /** Уникальный ID для defs при двух кольцах (maghrib/midday) — иначе mask берётся от другого кольца */
  instanceId?: string;
};

/** Зона перехода в градусах (маска, reveal) */
const ROLL_ZONE_DEG = 10;
/** Красное солнце: когда визуально касается/пересекает Maghrib (последние N градусов) */
const RED_SUN_ZONE_DEG = 8;
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

/** Оранжевое/красное солнце: усиленный ореол */
const SUN_GLOW_SPECIAL = {
  stdDeviation: 22,
  filterSize: 750,
  peakOpacity: 1.7,
};

/** Наружный glow как у last third: толстый stroke + blur */
const SUN_OUTER_GLOW = {
  strokeWidth: 24,
  blur: 8,
  orange: 'rgba(255, 111, 0, 0.85)',
  red: 'rgba(198, 40, 40, 0.9)',
};

/** Лёгкий glow для обычного жёлтого солнца */
const SUN_OUTER_GLOW_NORMAL = {
  strokeWidth: 16,
  blur: 5,
  yellow: 'rgba(255, 202, 40, 0.35)',
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
): { reveal: number; boundaryAngle: number; isRollIn: boolean; isInRedZone: boolean } {
  const norm = (a: number) => ((a % 360) + 360) % 360;
  const pa = norm(progressAngle);
  const sun = norm(sunriseAngleDeg);
  const mag = norm(maghribAngleDeg);

  /* В Fajr — только луна, без чёрного фона. Солнце появляется только в sunrise_to_dhuhr */
  if (isMoonOnlySector) {
    return { reveal: 0, boundaryAngle: 0, isRollIn: false, isInRedZone: false };
  }

  const rollOutEndRaw = sun + ROLL_ZONE_DEG;
  if (rollOutEndRaw <= 360) {
    if (pa >= sun && pa <= rollOutEndRaw) {
      const raw = (pa - sun) / ROLL_ZONE_DEG;
      return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: sun, isRollIn: false, isInRedZone: false };
    }
  } else {
    if (pa >= sun) {
      const raw = (pa - sun) / ROLL_ZONE_DEG;
      return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: sun, isRollIn: false, isInRedZone: false };
    }
    if (pa <= rollOutEndRaw - 360) {
      const raw = (pa + 360 - sun) / ROLL_ZONE_DEG;
      return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: sun, isRollIn: false, isInRedZone: false };
    }
  }
  const rollInStart = norm(mag - ROLL_ZONE_DEG);
  const distToMag = norm(mag - pa);
  const inRedZone = distToMag <= RED_SUN_ZONE_DEG;
  if (rollInStart > mag && pa >= rollInStart) {
    const raw = (360 - pa) / ROLL_ZONE_DEG;
    return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: mag, isRollIn: true, isInRedZone: inRedZone };
  }
  if (rollInStart <= mag && pa >= rollInStart && pa <= mag) {
    const raw = (mag - pa) / ROLL_ZONE_DEG;
    return { reveal: Math.max(MIN_REVEAL, Math.min(1, raw)), boundaryAngle: mag, isRollIn: true, isInRedZone: inRedZone };
  }
  return { reveal: 1, boundaryAngle: 0, isRollIn: false, isInRedZone: false };
}


const idSuffix = (id?: string) => (id ? `-${id}` : '');

export function CurrentMarker({ x, y, r, size, state, currentPhase, progressAngle, sunriseAngleDeg, maghribAngleDeg, centerX, centerY, sunriseBoundary, maghribBoundary, isInSunriseSubPeriod, instanceId }: Props) {
  const { isNight, moonPhase, hijriDayUsed } = state;
  const suffix = idSuffix(instanceId);
  const innerR = r * MOON_INNER_R;
  const isMoonOnlySector = MOON_ONLY_PHASES.has(currentPhase);
  const crescentMaskId = `crescent-mask-${hijriDayUsed}${suffix}`;
  const { reveal, boundaryAngle, isRollIn, isInRedZone } = getBlackDiskReveal(progressAngle, sunriseAngleDeg, maghribAngleDeg, isMoonOnlySector);

  const isBrightSun = reveal > 0 && SUN_PHASES.has(currentPhase);
  const useOrange = isBrightSun && !isRollIn && !!isInSunriseSubPeriod;
  const useRed = isBrightSun && isInRedZone;

  return (
    <g transform={`translate(${x}, ${y})`}>
      {/* Наружный glow — до clipPath, чтобы не обрезался */}
      {isBrightSun && (useOrange || useRed) && (
        <g filter={`url(#sun-outer-glow-${useOrange ? 'orange' : 'red'}${suffix})`}>
          <circle
            r={r}
            fill="none"
            stroke={useOrange ? SUN_OUTER_GLOW.orange : SUN_OUTER_GLOW.red}
            strokeWidth={SUN_OUTER_GLOW.strokeWidth}
          />
        </g>
      )}
      {isBrightSun && !useOrange && !useRed && (
        <g filter={`url(#sun-outer-glow-normal${suffix})`}>
          <circle
            r={r}
            fill="none"
            stroke={SUN_OUTER_GLOW_NORMAL.yellow}
            strokeWidth={SUN_OUTER_GLOW_NORMAL.strokeWidth}
          />
        </g>
      )}
      {isMoonOnlySector && moonPhase && moonPhase.shadowOffset !== 0 && (
        <defs>
          <mask id={crescentMaskId}>
            <circle r={innerR} fill="white" />
            <circle r={innerR} cx={moonPhase.shadowOffset * innerR} cy={0} fill="black" />
          </mask>
        </defs>
      )}
      <g clipPath={`url(#marker-disk-clip${suffix})`}>
        {/* Base disk: пред-roll-out, roll-out, roll-in — солнце с самого начала Sunrise */}
        {reveal > 0 && (
          (() => {
            const isBrightSun = SUN_PHASES.has(currentPhase);
            if (reveal >= 1) {
              const useOrange = isBrightSun && !!isInSunriseSubPeriod;
              const useRed = false; // full disk: no red zone
              const diskFill = isBrightSun ? (useOrange ? `url(#sun-fill-sunrise${suffix})` : `url(#sun-fill${suffix})`) : DISK_FILL;
              const diskStroke = isBrightSun ? (useOrange ? '#ff6f00' : '#ffa000') : DISK_STROKE;
              const diskFilter = isBrightSun
                ? (useOrange ? `url(#sun-effect-sunrise${suffix})` : useRed ? `url(#sun-effect-maghrib${suffix})` : `url(#sun-glow${suffix})`)
                : undefined;
              const gradId = useOrange ? 'grad-sunrise-neon' : useRed ? 'grad-maghrib-neon' : `grad-${currentPhase}${suffix}`;
              const peakOpacity = useOrange || useRed ? SUN_GLOW_SPECIAL.peakOpacity : SUN_NEON.peakOpacity;
              return (
                <>
                  {isBrightSun && (() => {
                    const ringStroke = size * 0.081;
                    const wBase = ringStroke + SUN_NEON.baseStrokeExtra;
                    const wPeak = ringStroke + SUN_NEON.peakStrokeExtra;
                    return (
                      <g
                        className="last-third-glow-pulse"
                        style={{
                          ['--last-third-glow-pulse-duration' as string]: `${SUN_NEON.pulseDuration}s`,
                          ['--last-third-glow-peak-opacity' as string]: String(peakOpacity),
                        }}
                      >
                        <g filter={`url(#glow-jumu-base${suffix})`} opacity={SUN_NEON.baseOpacity} className="last-third-glow-base">
                          <circle r={r} fill="none" stroke={`url(#${gradId})`} strokeWidth={wBase} />
                        </g>
                        <g filter={`url(#glow-jumu-peak${suffix})`} className="last-third-glow-peak">
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
            const maskId = `black-disk-mask-${hijriDayUsed}-${reveal.toFixed(2)}${suffix}`;
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
            const useRed = isBrightSun && isInRedZone;
            const useOrange = isBrightSun && !isRollIn && !!isInSunriseSubPeriod;
            const diskFill = isBrightSun
              ? (useRed ? `url(#sun-fill-maghrib${suffix})` : useOrange ? `url(#sun-fill-sunrise${suffix})` : `url(#sun-fill${suffix})`)
              : DISK_FILL;
            const diskStroke = isBrightSun ? (useRed ? '#c62828' : useOrange ? '#ff6f00' : '#ffa000') : DISK_STROKE;
            const diskFilter = isBrightSun
              ? (useOrange ? `url(#sun-effect-sunrise${suffix})` : useRed ? `url(#sun-effect-maghrib${suffix})` : `url(#sun-glow${suffix})`)
              : undefined;
            const gradId = useOrange ? 'grad-sunrise-neon' : useRed ? 'grad-maghrib-neon' : `grad-${currentPhase}${suffix}`;
            const peakOpacity = useOrange || useRed ? SUN_GLOW_SPECIAL.peakOpacity : SUN_NEON.peakOpacity;
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
                  return (
                    <g
                      className="last-third-glow-pulse"
                      style={{
                        ['--last-third-glow-pulse-duration' as string]: `${SUN_NEON.pulseDuration}s`,
                        ['--last-third-glow-peak-opacity' as string]: String(peakOpacity),
                      }}
                    >
                      <g filter={`url(#glow-jumu-base${suffix})`} opacity={SUN_NEON.baseOpacity} className="last-third-glow-base">
                        <circle r={r} fill="none" stroke={`url(#${gradId})`} strokeWidth={wBase} mask={`url(#${maskId})`} />
                      </g>
                      <g filter={`url(#glow-jumu-peak${suffix})`} className="last-third-glow-peak">
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
                  <circle r={innerR} fill={MOON_LUNAR_FILL} filter={`url(#moon-lunar-glow${suffix})`} opacity={0.85} />
                  <circle r={innerR} fill={MOON_LUNAR_FILL} />
                </>
              ) : (
                <>
                  {/* Glow + crescent: both masked so shadow area shows ring, not moon */}
                  <circle r={innerR} fill={MOON_LUNAR_FILL} filter={`url(#moon-lunar-glow${suffix})`} opacity={0.85} mask={`url(#${crescentMaskId})`} />
                  <circle r={innerR} fill={MOON_LUNAR_FILL} mask={`url(#${crescentMaskId})`} />
                </>
              )
            ) : (
              /* Fallback: lit + shadow (black disk behind) */
              <>
                <circle r={innerR} fill={MOON_FILL} filter={`url(#moon-glow${suffix})`} opacity={1} />
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
export function CurrentMarkerDefs({ r, instanceId }: { r: number; instanceId?: string }) {
  const suffix = idSuffix(instanceId);
  return (
    <>
      <filter id={`moon-glow${suffix}`} x="-80%" y="-80%" width="260%" height="260%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
        </feMerge>
      </filter>
      <filter id={`moon-lunar-glow${suffix}`} x="-100%" y="-100%" width="300%" height="300%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="3.5" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>
      <filter
        id={`sun-glow${suffix}`}
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
      {/* Orange sun: glow + colored drop shadow */}
      <filter
        id={`sun-effect-sunrise${suffix}`}
        x="-40%"
        y="-40%"
        width="180%"
        height="180%"
      >
        <feOffset in="SourceGraphic" dx="4" dy="4" result="offset" />
        <feGaussianBlur in="offset" stdDeviation="8" result="shadowBlur" />
        <feFlood floodColor="#ff6f00" floodOpacity="0.45" result="shadowColor" />
        <feComposite in="shadowBlur" in2="shadowColor" operator="in" result="shadow" />
        <feGaussianBlur in="SourceGraphic" stdDeviation={SUN_GLOW_SPECIAL.stdDeviation} result="glow" />
        <feMerge>
          <feMergeNode in="shadow" />
          <feMergeNode in="glow" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>
      {/* Red sun: glow + colored drop shadow */}
      <filter
        id={`sun-effect-maghrib${suffix}`}
        x="-40%"
        y="-40%"
        width="180%"
        height="180%"
      >
        <feOffset in="SourceGraphic" dx="4" dy="4" result="offset" />
        <feGaussianBlur in="offset" stdDeviation="8" result="shadowBlur" />
        <feFlood floodColor="#c62828" floodOpacity="0.45" result="shadowColor" />
        <feComposite in="shadowBlur" in2="shadowColor" operator="in" result="shadow" />
        <feGaussianBlur in="SourceGraphic" stdDeviation={SUN_GLOW_SPECIAL.stdDeviation} result="glow" />
        <feMerge>
          <feMergeNode in="shadow" />
          <feMergeNode in="glow" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>
      <radialGradient id={`sun-fill${suffix}`} cx="0.5" cy="0.5" r="0.5">
        <stop offset="0" stopColor="#ffffff" />
        <stop offset="0.3" stopColor="#fffde7" />
        <stop offset="0.6" stopColor="#fff59d" />
        <stop offset="1" stopColor="#ffca28" />
      </radialGradient>
      {/* Sunrise: насыщенный оранжевый */}
      <radialGradient id={`sun-fill-sunrise${suffix}`} cx="0.5" cy="0.5" r="0.5">
        <stop offset="0" stopColor="#ffffff" />
        <stop offset="0.15" stopColor="#ffeed9" />
        <stop offset="0.45" stopColor="#ffb74d" />
        <stop offset="1" stopColor="#ff6f00" />
      </radialGradient>
      {/* Maghrib: насыщенный красный */}
      <radialGradient id={`sun-fill-maghrib${suffix}`} cx="0.5" cy="0.5" r="0.5">
        <stop offset="0" stopColor="#ffffff" />
        <stop offset="0.15" stopColor="#ffd5d5" />
        <stop offset="0.45" stopColor="#ff6b6b" />
        <stop offset="1" stopColor="#c62828" />
      </radialGradient>
      {/* Наружный glow (как last third): толстый stroke + blur */}
      <filter
        id={`sun-outer-glow-orange${suffix}`}
        x="-150%"
        y="-150%"
        width="400%"
        height="400%"
      >
        <feGaussianBlur in="SourceGraphic" stdDeviation={SUN_OUTER_GLOW.blur} result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
        </feMerge>
      </filter>
      <filter
        id={`sun-outer-glow-red${suffix}`}
        x="-150%"
        y="-150%"
        width="400%"
        height="400%"
      >
        <feGaussianBlur in="SourceGraphic" stdDeviation={SUN_OUTER_GLOW.blur} result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
        </feMerge>
      </filter>
      <filter
        id={`sun-outer-glow-normal${suffix}`}
        x="-120%"
        y="-120%"
        width="340%"
        height="340%"
      >
        <feGaussianBlur in="SourceGraphic" stdDeviation={SUN_OUTER_GLOW_NORMAL.blur} result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
        </feMerge>
      </filter>
      <clipPath id={`marker-disk-clip${suffix}`} clipPathUnits="objectBoundingBox">
        <circle cx="0.5" cy="0.5" r="0.5" />
      </clipPath>
    </>
  );
}
