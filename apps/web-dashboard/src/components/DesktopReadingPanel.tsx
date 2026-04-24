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
import { DalilOrnamentalDivider } from './DalilOrnamentalDivider';
import {
  dalilSectionLabelAr,
  formatDalilSourceLine,
  groupReadingBlocksIntoDalilEntries,
} from '../lib/groupDalilEntries';

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
      <DesktopReadingContent
        key={selectedKey}
        content={content}
        onClear={onClear}
      />
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

  const dalilEntries = groupReadingBlocksIntoDalilEntries(content.blocks);

  return (
    <aside
      key={`reading-${content.title}-${showTechnical ? 'technical' : 'reading'}`}
      className="desktop-reading-panel desktop-reading-panel--content desktop-reading-panel--dalil panel-animate-in"
    >
      <div className="desktop-reading-panel-foreground desktop-dalil-foreground">
        <header className="desktop-dalil-top-bar">
          {showTechnical ? (
            <>
              <button
                type="button"
                className="desktop-dalil-back"
                onClick={() => setShowTechnical(false)}
                aria-label="Back to Dalil"
              >
                <span className="desktop-dalil-back-chevron" aria-hidden>
                  ‹
                </span>
              </button>
              <h1 className="desktop-dalil-title">Technical details</h1>
              <button
                type="button"
                className="desktop-dalil-back desktop-dalil-back--trailing"
                onClick={onClear}
                aria-label="Close panel"
              >
                <span className="desktop-dalil-close-text">Close</span>
              </button>
            </>
          ) : (
            <>
              <button type="button" className="desktop-dalil-back" onClick={onClear} aria-label="Close reading panel">
                <span className="desktop-dalil-back-chevron" aria-hidden>
                  ‹
                </span>
              </button>
              <h1 className="desktop-dalil-title">Dalil</h1>
              <span className="desktop-dalil-top-spacer" aria-hidden />
            </>
          )}
        </header>

        <div className={`desktop-panel-scroll desktop-dalil-scroll${showTechnical ? ' desktop-dalil-scroll--technical' : ''}`}>
          {showTechnical && content.technicalSections ? (
            <DesktopTechnicalSections sections={content.technicalSections} />
          ) : (
            <div className="desktop-dalil-entries">
              {dalilEntries.map((entry, entryIndex) => (
                <article key={`${content.title}-dalil-${entryIndex}`} className="desktop-dalil-entry">
                  <p className="desktop-dalil-section-label" dir="rtl" lang="ar">
                    <span className="desktop-dalil-section-ornament" aria-hidden />
                    <span>{dalilSectionLabelAr(entryIndex)}</span>
                    <span className="desktop-dalil-section-ornament" aria-hidden />
                  </p>
                  <p className="desktop-dalil-arabic" dir="rtl" lang="ar">
                    {entry.arabic}
                  </p>
                  <p
                    className={`desktop-dalil-english${entry.english.length >= 220 ? ' desktop-dalil-english--prose' : ''}`}
                    lang="en"
                  >
                    {entry.english}
                  </p>
                  {entry.source ? (
                    <p className="desktop-dalil-source" lang="en">
                      {formatDalilSourceLine(entry.source)}
                    </p>
                  ) : null}
                  {entryIndex < dalilEntries.length - 1 ? (
                    <div className="desktop-dalil-between-entries">
                      <DalilOrnamentalDivider />
                    </div>
                  ) : null}
                </article>
              ))}
              {hasTechnicalDetails ? (
                <button
                  type="button"
                  className="desktop-dalil-technical-link"
                  onClick={() => setShowTechnical(true)}
                >
                  Technical details
                </button>
              ) : null}
            </div>
          )}
        </div>
      </div>
    </aside>
  );
}

function DesktopTechnicalSections({ sections }: { sections: TechnicalSection[] }) {
  return (
    <div className="desktop-technical-entries">
      {sections.map((section, sectionIndex) => (
        <article key={section.heading} className="desktop-technical-entry">
          <h2 className="desktop-technical-section-heading">
            <span className="desktop-dalil-section-ornament" aria-hidden />
            <span className="desktop-technical-section-heading-text">{section.heading}</span>
            <span className="desktop-dalil-section-ornament" aria-hidden />
          </h2>
          <div className="desktop-technical-lines">
            {section.lines.map((line) => (
              <div key={`${section.heading}-${line.label}`} className="desktop-technical-block">
                <p className="desktop-technical-label-line">{line.label}</p>
                <p className="desktop-technical-detail-paragraph">{line.detail}</p>
              </div>
            ))}
          </div>
          {sectionIndex < sections.length - 1 ? (
            <div className="desktop-dalil-between-entries desktop-technical-between-sections">
              <DalilOrnamentalDivider />
            </div>
          ) : null}
        </article>
      ))}
    </div>
  );
}
