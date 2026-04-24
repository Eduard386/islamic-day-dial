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
        <span className="phase-guidance-divider-dot" />
        <span className="phase-guidance-divider-ornament">
          <img
            className="phase-guidance-ornament-img"
            src={`${import.meta.env.BASE_URL}hijri-ornament-divider.png`}
            alt=""
            width={28}
            height={28}
            decoding="async"
          />
        </span>
        <span className="phase-guidance-divider-dot" />
        <span className="phase-guidance-divider-line" />
      </div>
    </div>
  );
}
