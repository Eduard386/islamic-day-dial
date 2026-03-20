/**
 * Convert angle (0° = top, clockwise) to SVG coordinates.
 */
export function polarToXY(
  cx: number,
  cy: number,
  r: number,
  angleDeg: number,
): { x: number; y: number } {
  const rad = ((angleDeg - 90) * Math.PI) / 180;
  return {
    x: cx + r * Math.cos(rad),
    y: cy + r * Math.sin(rad),
  };
}


/**
 * SVG arc path for a segment of a circle (used with stroke, no fill).
 */
export function describeArc(
  cx: number,
  cy: number,
  r: number,
  startDeg: number,
  endDeg: number,
): string {
  const span = endDeg - startDeg;
  if (span <= 0) return '';
  if (span >= 360) {
    const top = polarToXY(cx, cy, r, 0);
    const bottom = polarToXY(cx, cy, r, 180);
    return (
      `M ${top.x} ${top.y} ` +
      `A ${r} ${r} 0 1 1 ${bottom.x} ${bottom.y} ` +
      `A ${r} ${r} 0 1 1 ${top.x} ${top.y}`
    );
  }
  const start = polarToXY(cx, cy, r, startDeg);
  const end = polarToXY(cx, cy, r, endDeg);
  const largeArc = span > 180 ? 1 : 0;
  return `M ${start.x} ${start.y} A ${r} ${r} 0 ${largeArc} 1 ${end.x} ${end.y}`;
}
