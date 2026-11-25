import { getSectorDisplayName } from '@islamic-day-dial/core';
import { useEffect, useLayoutEffect, useMemo, useRef, useState, type CSSProperties } from 'react';
import { useIslamicDay } from './hooks/useIslamicDay';
import { IslamicRing } from './components/IslamicRing';
import { DialFootnotes } from './components/DialFootnotes';
import { CenterInfo } from './components/CenterInfo';
import { Controls } from './components/Controls';
import { DesktopMonthsRail } from './components/DesktopMonthsRail';
import { DesktopReadingPanel } from './components/DesktopReadingPanel';
import {
  getReadingKeyForFootnoteId,
  getReadingKeyForSectorDisplayName,
  getWebObservationalCue,
  shouldHidePhaseGuidanceObserveOverline,
  webPhaseGuidanceJumuahOverline,
  type ReadingKey,
} from './content/desktopContent';
import { currentLanguage, t } from './lib/locale';
import { DialBelowRingAyah } from './components/DialBelowRingAyah';
import { DialPostRingGuidance } from './components/DialPostRingGuidance';
import { trackVisit } from './lib/analytics';
import './App.css';

const DESKTOP_MEDIA_QUERY = '(min-width: 1180px)';

function useIsDesktop() {
  const getCurrentValue = () =>
    typeof window !== 'undefined' && window.matchMedia(DESKTOP_MEDIA_QUERY).matches;

  const [isDesktop, setIsDesktop] = useState(getCurrentValue);

  useEffect(() => {
    if (typeof window === 'undefined') return undefined;
    const media = window.matchMedia(DESKTOP_MEDIA_QUERY);
    const onChange = () => setIsDesktop(media.matches);
    onChange();
    media.addEventListener('change', onChange);
    return () => media.removeEventListener('change', onChange);
  }, []);

  return isDesktop;
}

export default function App() {
  const state = useIslamicDay();
  const isDesktop = useIsDesktop();
  const monthsRailRef = useRef<HTMLElement | null>(null);
  const [monthsRailHeightPx, setMonthsRailHeightPx] = useState<number | null>(null);
  const [selectedReading, setSelectedReading] = useState<{ key: ReadingKey; emphasisId?: string } | null>(null);

  useEffect(() => {
    document.documentElement.lang = currentLanguage();
    trackVisit();
  }, []);

  useEffect(() => {
    if (isDesktop || !selectedReading) return undefined;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setSelectedReading(null);
    };
    window.addEventListener('keydown', onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [isDesktop, selectedReading]);

  useLayoutEffect(() => {
    if (!isDesktop) {
      setMonthsRailHeightPx(null);
      return undefined;
    }
    const el = monthsRailRef.current;
    if (!el) return undefined;
    const apply = () => setMonthsRailHeightPx(Math.round(el.getBoundingClientRect().height));
    apply();
    const ro = new ResizeObserver(apply);
    ro.observe(el);
    return () => ro.disconnect();
  }, [isDesktop]);

  const { snapshot, timezone, timeMode, selectedPreset, effectiveNow } = state;

  const currentPeriodLabel = useMemo(
    () =>
      getSectorDisplayName(
        effectiveNow,
        snapshot.currentPhase,
        { duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr },
      ),
    [effectiveNow, snapshot.currentPhase, snapshot.timeline.duhaStart, snapshot.timeline.dhuhr],
  );

  const currentReadableKey = getReadingKeyForSectorDisplayName(currentPeriodLabel);

  const observationalCue = useMemo(
    () => getWebObservationalCue(snapshot, effectiveNow),
    [snapshot, effectiveNow],
  );

  const phaseGuidanceOverline = shouldHidePhaseGuidanceObserveOverline(observationalCue)
    ? ''
    : currentPeriodLabel === "Jumu'ah"
      ? webPhaseGuidanceJumuahOverline()
      : t('observe');

  const openCurrentReading = () => {
    if (!currentReadableKey) return;
    setSelectedReading({ key: currentReadableKey, emphasisId: 'center' });
  };

  const openFootnoteReading = (id: string) => {
    if (!isDesktop) return;
    const readingKey = getReadingKeyForFootnoteId(id);
    if (!readingKey) return;
    setSelectedReading({ key: readingKey, emphasisId: id });
  };

  const clearReading = () => {
    setSelectedReading(null);
  };

  const renderDial = (dialSize: number, sidePad: number, interactive: boolean) => (
    <div className="dial-footnotes-shell" style={{ ['--dial' as string]: `${dialSize}px`, ['--footnote-side' as string]: `${sidePad}px` }}>
      <DialFootnotes
        snapshot={snapshot}
        dialSize={dialSize}
        sidePad={sidePad}
        activeLabelId={selectedReading?.emphasisId && selectedReading.emphasisId !== 'center' ? selectedReading.emphasisId : null}
        onSelect={interactive ? openFootnoteReading : undefined}
      />
      <div className="dial-core">
        <div
          className={`dial-wrapper${interactive ? ' dial-wrapper--interactive' : ''}`}
          onClick={interactive && selectedReading ? clearReading : undefined}
          role={interactive && selectedReading ? 'button' : undefined}
          tabIndex={interactive && selectedReading ? 0 : undefined}
          onKeyDown={
            interactive && selectedReading
              ? (event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    clearReading();
                  }
                }
              : undefined
          }
        >
          <IslamicRing snapshot={snapshot} now={effectiveNow} size={dialSize} />
          <div className={`center-overlay${currentReadableKey ? ' center-overlay--interactive' : ''}`}>
            <CenterInfo
              snapshot={snapshot}
              now={effectiveNow}
              timezone={timezone}
              onPeriodSelect={currentReadableKey ? openCurrentReading : undefined}
              isPeriodSelected={selectedReading?.emphasisId === 'center'}
            />
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className={`app${isDesktop ? ' app--desktop' : ''}`}>
      {!isDesktop && (
        <header className="app-header">
          <div className="dial-ceremony-block dial-ceremony-block--mobile dial-ceremony-block--ayah-only">
            <DialBelowRingAyah />
          </div>
        </header>
      )}

      <main className="app-main">
        {isDesktop ? (
          <div
            className="desktop-shell"
            style={
              monthsRailHeightPx != null
                ? ({ ['--desktop-reading-panel-height' as string]: `${monthsRailHeightPx}px` } as CSSProperties)
                : undefined
            }
          >
            <DesktopMonthsRail ref={monthsRailRef} snapshot={snapshot} />

            <section className="desktop-stage">
              <div className="dial-ceremony-block dial-ceremony-block--desktop dial-ceremony-block--ayah-only">
                <DialBelowRingAyah />
              </div>
              <div className="desktop-stage-ring">
                {renderDial(420, 132, true)}
              </div>
              <DialPostRingGuidance
                modeLabel={phaseGuidanceOverline}
                guidanceText={observationalCue}
                variant="desktop"
              />
            </section>

            <DesktopReadingPanel
              snapshot={snapshot}
              now={effectiveNow}
              selectedKey={selectedReading?.key ?? null}
              onClear={clearReading}
            />
          </div>
        ) : (
          <div className="dial-section dial-section--balanced">
            <div className="dial-stack dial-stack--balanced">
              <div className="dial-stack-middle">
                <div className="dial-stack-spring" aria-hidden />
                {renderDial(420, 92, false)}
                {selectedReading ? (
                  <div className="mobile-dalil-sheet" role="dialog" aria-modal="true" aria-label={t('dalil')}>
                    <DesktopReadingPanel
                      snapshot={snapshot}
                      now={effectiveNow}
                      selectedKey={selectedReading.key}
                      onClear={clearReading}
                    />
                  </div>
                ) : null}
                <DialPostRingGuidance
                  modeLabel={phaseGuidanceOverline}
                  guidanceText={observationalCue}
                  variant="mobile"
                />
                <div className="dial-stack-spring" aria-hidden />
              </div>
            </div>
          </div>
        )}

        <div className="controls-section">
          <Controls
            timeMode={timeMode}
            selectedPreset={selectedPreset}
            currentHijriDay={snapshot.hijriDate.day}
            onLocationChange={state.setLocation}
            onTimezoneChange={state.setTimezone}
            onTimeModeChange={state.setTimeMode}
            onPresetSelect={state.setSelectedPreset}
            onCurrentCity={state.applyCurrentCity}
          />
          <section className="site-meta-card" id="app" aria-labelledby="app-title">
            <h2 id="app-title">{t('theApp')}</h2>
            <p className="site-meta-card__body" dir="auto" lang={currentLanguage()}>{t('appBody')}</p>
            <p>
              <a href="https://apps.apple.com/app/islamic-day-dial/id6836356917">{t('download')}</a>
            </p>
          </section>
          <section className="site-meta-card" id="support" aria-labelledby="support-title">
            <h2 id="support-title">{t('support')}</h2>
            <p dir="auto" lang={currentLanguage()}>
              {t('supportBeforeEmail')}<a href="mailto:islamicdaydial@gmail.com">islamicdaydial@gmail.com</a>.
            </p>
          </section>
          <section className="site-meta-card" id="privacy" aria-labelledby="privacy-title">
            <h2 id="privacy-title">{t('privacy')}</h2>
            <p dir="auto" lang={currentLanguage()}>{t('privacyBody')}</p>
            <p dir="auto" lang={currentLanguage()}>
              {t('privacyBeforeEmail')}<a href="mailto:islamicdaydial@gmail.com">islamicdaydial@gmail.com</a>.
            </p>
          </section>
        </div>
      </main>
    </div>
  );
}
