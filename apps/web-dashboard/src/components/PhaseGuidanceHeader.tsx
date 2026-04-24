type PhaseGuidanceHeaderProps = {
  /** Quiet rubric above the guidance line (e.g. OBSERVE, or Prepare for Jumu'ah). Empty hides it (e.g. Eid Taqabbal). */
  modeLabel?: string;
  /** Observational phrase for the current sector; keep sentence case. */
  guidanceText: string;
  className?: string;
};

/** First line is Arabic (e.g. Taqabbal) — render it slightly larger than Latin lines below. */
const ARABIC_SCRIPT_RE = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/;

function splitGuidanceForArabicLead(guidanceText: string): { arabic: string; latin: string } | null {
  const lines = guidanceText.split('\n');
  if (lines.length < 2) return null;
  const first = lines[0] ?? '';
  if (!ARABIC_SCRIPT_RE.test(first)) return null;
  const latin = lines.slice(1).join('\n');
  return { arabic: first, latin };
}

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
  const arabicLead = splitGuidanceForArabicLead(guidanceText);
  return (
    <div className={`phase-guidance-header ${className}`.trim()}>
      {showOverline ? <p className="phase-guidance-overline">{modeLabel.toUpperCase()}</p> : null}
      <p
        className={`phase-guidance-main${showOverline ? '' : ' phase-guidance-main--flush'}${arabicLead ? ' phase-guidance-main--arabic-lead' : ''}`}
        key={guidanceText}
      >
        {arabicLead ? (
          <>
            <span className="phase-guidance-arabic-line" dir="rtl">
              {arabicLead.arabic}
            </span>
            <span className="phase-guidance-latin-lines">{arabicLead.latin}</span>
          </>
        ) : (
          guidanceText
        )}
      </p>
    </div>
  );
}
