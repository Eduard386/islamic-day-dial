import { getSectorDisplayName, type ComputedIslamicDay } from '@islamic-day-dial/core';
import { useEffect, useState } from 'react';
import {
  getReadingPanelContent,
  type TechnicalSection,
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
    return <DesktopReadingContent key={selectedKey} content={content} onClear={onClear} />;
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

function DesktopReadingContent({
  content,
  onClear,
}: {
  content: ReturnType<typeof getReadingPanelContent>;
  onClear: () => void;
}) {
  const [showTechnical, setShowTechnical] = useState(false);

  useEffect(() => {
    setShowTechnical(false);
  }, [content.title]);

  const hasTechnicalDetails = Boolean(content.technicalSections?.length);

  return (
    <aside key={`reading-${content.title}-${showTechnical ? 'technical' : 'reading'}`} className="desktop-reading-panel desktop-reading-panel--content panel-animate-in">
      <div className="desktop-panel-header">
        <div>
          <p className="desktop-panel-kicker">{showTechnical ? 'Technical details' : 'Reading'}</p>
          <h2 className="desktop-panel-title">{content.title}</h2>
        </div>
        <div className="desktop-panel-actions">
          {showTechnical && (
            <button
              type="button"
              className="desktop-panel-close"
              onClick={() => setShowTechnical(false)}
            >
              Back to reading
            </button>
          )}
          <button
            type="button"
            className="desktop-panel-close"
            onClick={onClear}
            aria-label="Close reading panel"
          >
            Close
          </button>
        </div>
      </div>

      <div className="desktop-panel-scroll">
        {showTechnical && content.technicalSections ? (
          <DesktopTechnicalSections sections={content.technicalSections} />
        ) : (
          <>
          {content.blocks.map((block, index) => (
            <p
              key={`${content.title}-${block.kind}-${index}`}
              className={`desktop-reading-block desktop-reading-block--${block.kind}`}
              dir={block.kind === 'arabic' ? 'rtl' : undefined}
              lang={block.kind === 'arabic' ? 'ar' : 'en'}
            >
              {block.text}
            </p>
          ))}
          {hasTechnicalDetails && (
            <button
              type="button"
              className="desktop-technical-link"
              onClick={() => setShowTechnical(true)}
            >
              Technical details
            </button>
          )}
          </>
        )}
      </div>
    </aside>
  );
}

function DesktopTechnicalSections({ sections }: { sections: TechnicalSection[] }) {
  return (
    <div className="desktop-technical-stack">
      {sections.map((section) => (
        <section key={section.heading} className="desktop-technical-section">
          <h3 className="desktop-technical-heading">{section.heading}</h3>
          <div className="desktop-technical-lines">
            {section.lines.map((line) => (
              <p key={`${section.heading}-${line.label}`} className="desktop-technical-line">
                <span className="desktop-technical-label">{line.label}:</span>{' '}
                <span className="desktop-technical-detail">{line.detail}</span>
              </p>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
