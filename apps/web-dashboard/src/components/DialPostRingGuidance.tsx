import { PhaseGuidanceHeader } from './PhaseGuidanceHeader';
import { PhaseGuidanceOrnamentDivider } from './PhaseGuidanceOrnamentDivider';

type Props = {
  modeLabel: string;
  guidanceText: string;
  variant: 'desktop' | 'mobile';
};

/** Ornament divider → OBSERVE + sector cue (below the dial). */
export function DialPostRingGuidance({ modeLabel, guidanceText, variant }: Props) {
  return (
    <div className={`dial-post-ring-guidance dial-post-ring-guidance--${variant}`}>
      <PhaseGuidanceOrnamentDivider className="phase-guidance-divider--post-ring" />
      <PhaseGuidanceHeader
        modeLabel={modeLabel}
        guidanceText={guidanceText}
        className={variant === 'desktop' ? 'phase-guidance-header--desktop' : 'phase-guidance-header--mobile'}
      />
    </div>
  );
}
