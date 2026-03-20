import type { IslamicPhaseId } from '@islamic-day-dial/core';
import type { CurrentMarkerState } from '../lib/current-marker';

type Props = {
  x: number;
  y: number;
  r: number;
  state: CurrentMarkerState;
  currentPhase: IslamicPhaseId;
};

/** Absolutely black — blends with night segments; only moon visible Maghrib→Fajr */
const DISK_FILL = '#000000';
const DISK_STROKE = '#000000';
const MOON_FILL = '#e8dcc8';
/** Lunar: bluish-yellowish, muted, full-moon glow — Maghrib, Isha, Last Third */
const MOON_LUNAR_FILL = '#B0B0A8';
const MOON_INNER_R = 0.82; /** Moon circles radius as fraction of disk r */

/** Sectors where only moon is visible, ring background shows through */
const MOON_ONLY_PHASES = new Set<IslamicPhaseId>([
  'maghrib_to_isha',
  'isha_to_midnight',
  'last_third_to_fajr',
  'fajr_to_sunrise',
]);

export function CurrentMarker({ x, y, r, state, currentPhase }: Props) {
  const { isNight, moonPhase, hijriDayUsed } = state;
  const innerR = r * MOON_INNER_R;
  const isMoonOnlySector = MOON_ONLY_PHASES.has(currentPhase);
  const crescentMaskId = `crescent-mask-${hijriDayUsed}`;

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
        {/* Base disk — skip at night so ring gradient shows through */}
        {!isMoonOnlySector && (
          <circle
            r={r}
            fill={DISK_FILL}
            stroke={DISK_STROKE}
            strokeWidth={1}
          />
        )}
        {/* Night: moon phase from hijri day */}
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
      <clipPath id="marker-disk-clip" clipPathUnits="userSpaceOnUse">
        <circle cx={0} cy={0} r={r} />
      </clipPath>
    </>
  );
}
