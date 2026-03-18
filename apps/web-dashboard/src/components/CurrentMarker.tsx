import type { CurrentMarkerState } from '../lib/current-marker';

type Props = {
  x: number;
  y: number;
  r: number;
  state: CurrentMarkerState;
};

/** Minimal colors: muted, no heavy 3D */
const DISK_FILL = '#1a1a2e';
const DISK_STROKE = '#2a2a4a';
const MOON_FILL = '#e8dcc8';
const MOON_INNER_R = 0.82; /** Moon circles radius as fraction of disk r */

export function CurrentMarker({ x, y, r, state }: Props) {
  const { isNight, moonPhase } = state;
  const innerR = r * MOON_INNER_R;

  return (
    <g transform={`translate(${x}, ${y})`} clipPath="url(#marker-disk-clip)">
      {/* Base disk — always one circle, outer contour */}
      <circle
        r={r}
        fill={DISK_FILL}
        stroke={DISK_STROKE}
        strokeWidth={1}
      />
      {/* Night: moon phase from hijri day — lit + shadow, both clipped inside disk */}
      {isNight && moonPhase && (
        <g>
          {/* Glow: subtle halo around lit moon, behind */}
          <circle r={innerR} fill={MOON_FILL} filter="url(#moon-glow)" opacity={1} />
          {/* Lit part: ivory circle (partially covered by shadow to form crescent) */}
          <circle r={innerR} fill={MOON_FILL} />
          {/* Shadow: dark circle overlapping → creates phase; offset 0 = full moon */}
          {moonPhase.shadowOffset !== 0 && (
            <circle
              r={innerR}
              cx={moonPhase.shadowOffset * innerR}
              cy={0}
              fill={DISK_FILL}
            />
          )}
        </g>
      )}
    </g>
  );
}

/** ClipPath and glow filter for marker */
export function CurrentMarkerDefs({ r }: { r: number }) {
  return (
    <>
      <filter id="moon-glow" x="-80%" y="-80%" width="260%" height="260%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
        </feMerge>
      </filter>
      <clipPath id="marker-disk-clip" clipPathUnits="userSpaceOnUse">
        <circle cx={0} cy={0} r={r} />
      </clipPath>
    </>
  );
}
