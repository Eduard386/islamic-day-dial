import { getSectorDisplayName, type ComputedIslamicDay } from '@islamic-day-dial/core';
import {
  getReadingPanelContent,
  type ReadingKey,
} from '../content/desktopContent';
import {
  getLoadingStillKey,
  LOADING_STILL_SOURCES,
} from '../content/loadingStills';

type Props = {
  snapshot: ComputedIslamicDay;
  now: Date;
  selectedKey: ReadingKey | null;
  onClear: () => void;
};

export function DesktopReadingPanel({ snapshot, now, selectedKey, onClear }: Props) {
  if (selectedKey) {
    const content = getReadingPanelContent(selectedKey);

    return (
      <aside key={`reading-${selectedKey}`} className="desktop-reading-panel desktop-reading-panel--content panel-animate-in">
        <div className="desktop-panel-header">
          <div>
            <p className="desktop-panel-kicker">Reading</p>
            <h2 className="desktop-panel-title">{content.title}</h2>
          </div>
          <button
            type="button"
            className="desktop-panel-close"
            onClick={onClear}
            aria-label="Close reading panel"
          >
            Close
          </button>
        </div>

        <div className="desktop-panel-scroll">
          {content.blocks.map((block, index) => (
            <p
              key={`${selectedKey}-${block.kind}-${index}`}
              className={`desktop-reading-block desktop-reading-block--${block.kind}`}
              dir={block.kind === 'arabic' ? 'rtl' : undefined}
              lang={block.kind === 'arabic' ? 'ar' : 'en'}
            >
              {block.text}
            </p>
          ))}
        </div>
      </aside>
    );
  }

  const stillKey = getLoadingStillKey(snapshot, now);
  const currentLabel = getSectorDisplayName(
    now,
    snapshot.currentPhase,
    { duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr },
  );

  return (
    <aside key={`empty-${stillKey}`} className="desktop-reading-panel desktop-reading-panel--empty panel-animate-in">
      <div className="desktop-still-shell">
        <img
          src={LOADING_STILL_SOURCES[stillKey]}
          alt=""
          className="desktop-still-image"
        />
        <div className="desktop-still-scrim" aria-hidden />
        <div className="desktop-still-caption">
          <p className="desktop-panel-kicker">Current Sign</p>
          <h2 className="desktop-panel-title">{currentLabel}</h2>
          <p className="desktop-panel-empty-copy">
            Select a sector label or the title inside the ring to read the related texts.
          </p>
        </div>
      </div>
    </aside>
  );
}
