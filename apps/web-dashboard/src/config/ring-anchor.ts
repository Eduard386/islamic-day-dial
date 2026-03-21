/**
 * 12 o'clock variants: 'maghrib' (Islamic day start) or 'midday' (Dhuhr).
 * Pass via IslamicRing clock12Anchor prop.
 */
export function toDisplayAngle(angleDeg: number, offsetDeg: number): number {
  if (offsetDeg === 0) return angleDeg;
  return (angleDeg + offsetDeg + 360) % 360;
}
