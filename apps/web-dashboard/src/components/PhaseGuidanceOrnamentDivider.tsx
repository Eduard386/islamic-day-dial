/** Line · rosette · line — below the dial, above OBSERVE (see `DialPostRingGuidance`). */
export function PhaseGuidanceOrnamentDivider({ className = '' }: { className?: string }) {
  return (
    <div className={`phase-guidance-divider ${className}`.trim()} aria-hidden>
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
  );
}
