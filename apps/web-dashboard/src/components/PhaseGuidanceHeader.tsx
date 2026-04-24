type PhaseGuidanceHeaderProps = {
  /** Quiet rubric above the guidance line (e.g. OBSERVE). Empty string hides it (e.g. Jumu’ah). */
  modeLabel?: string;
  /** Observational phrase for the current sector; keep sentence case. */
  guidanceText: string;
  className?: string;
};

/**
 * Ceremonial block above the dial: overline, editorial guidance, delicate divider.
 * Matches the iOS home treatment (warm sand gold, no “dashboard” chrome).
 */
export function PhaseGuidanceHeader({
  modeLabel = 'OBSERVE',
  guidanceText,
  className = '',
}: PhaseGuidanceHeaderProps) {
  const showOverline = modeLabel.trim().length > 0;
  return (
    <div className={`phase-guidance-header ${className}`.trim()}>
      {showOverline ? <p className="phase-guidance-overline">{modeLabel.toUpperCase()}</p> : null}
      <p
        className={`phase-guidance-main${showOverline ? '' : ' phase-guidance-main--flush'}`}
        key={guidanceText}
      >
        {guidanceText}
      </p>
      <div className="phase-guidance-divider" aria-hidden>
        <span className="phase-guidance-divider-line" />
        <span className="phase-guidance-divider-ornament">
          <svg
            className="phase-guidance-ornament-svg"
            width="12"
            height="12"
            viewBox="0 0 12 12"
            focusable="false"
          >
            <circle cx="6" cy="6" r="3.6" fill="none" stroke="currentColor" strokeWidth="0.45" />
            <path d="M6 3.3 L8.7 6 6 8.7 3.3 6Z" fill="currentColor" />
          </svg>
        </span>
        <span className="phase-guidance-divider-line" />
      </div>
    </div>
  );
}
