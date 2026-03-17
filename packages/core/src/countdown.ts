/**
 * Milliseconds remaining until the next transition.
 * Returns 0 if the transition is in the past (shouldn't happen in normal flow).
 */
export function getCountdown(now: Date, nextTransitionAt: Date): number {
  return Math.max(0, nextTransitionAt.getTime() - now.getTime());
}
