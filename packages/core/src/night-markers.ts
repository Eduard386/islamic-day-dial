/**
 * Islamic midnight = midpoint between lastMaghrib and Fajr.
 * Reference: Isha time extends until the middle of the night.
 */
export function getIslamicMidnight(lastMaghrib: Date, fajr: Date): Date {
  const mid = (lastMaghrib.getTime() + fajr.getTime()) / 2;
  return new Date(mid);
}

/**
 * Last third of the night starts at fajr − (nightDuration / 3).
 * nightDuration = fajr − lastMaghrib (handles crossing civil midnight).
 */
export function getLastThirdStart(lastMaghrib: Date, fajr: Date): Date {
  const nightDuration = fajr.getTime() - lastMaghrib.getTime();
  return new Date(fajr.getTime() - nightDuration / 3);
}
