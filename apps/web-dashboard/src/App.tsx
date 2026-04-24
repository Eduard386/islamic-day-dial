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
  type ReadingKey,
} from './content/desktopContent';
import { PhaseGuidanceHeader } from './components/PhaseGuidanceHeader';
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
    trackVisit();
  }, []);

  useEffect(() => {
    if (!isDesktop && selectedReading) {
      setSelectedReading(null);
    }
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

  const phaseGuidanceOverline =
    currentPeriodLabel === "Jumu'ah" || shouldHidePhaseGuidanceObserveOverline(observationalCue)
      ? ''
      : 'OBSERVE';

  const openCurrentReading = () => {
    if (!isDesktop || !currentReadableKey) return;
    setSelectedReading({ key: currentReadableKey, emphasisId: 'center' });
  };

  const openFootnoteReading = (id: string) => {
    if (!isDesktop) return;
    const readingKey = getReadingKeyForFootnoteId(id);
    if (!readingKey) return;
    setSelectedReading({ key: readingKey, emphasisId: id });
  };

  const clearReading = () => {
    if (!isDesktop) return;
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
          <div className={`center-overlay${interactive && currentReadableKey ? ' center-overlay--interactive' : ''}`}>
            <CenterInfo
              snapshot={snapshot}
              now={effectiveNow}
              timezone={timezone}
              onPeriodSelect={interactive && currentReadableKey ? openCurrentReading : undefined}
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
          <PhaseGuidanceHeader
            modeLabel={phaseGuidanceOverline}
            guidanceText={observationalCue}
            className="phase-guidance-header--mobile"
          />
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
              <PhaseGuidanceHeader
                modeLabel={phaseGuidanceOverline}
                guidanceText={observationalCue}
                className="phase-guidance-header--desktop"
              />
              <div className="desktop-stage-ring">
                {renderDial(420, 132, true)}
              </div>
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
          <section className="site-meta-card" id="support" aria-labelledby="support-title">
            <h2 id="support-title">Support</h2>
            <p>
              Islamic Day Dial is designed for iPhone, Apple Watch companion use, and the iPhone widget.
              If you need help, contact <a href="mailto:islamicdaydial@gmail.com">islamicdaydial@gmail.com</a>.
            </p>
          </section>
          <section className="site-meta-card" id="privacy" aria-labelledby="privacy-title">
            <h2 id="privacy-title">Privacy</h2>
            <p>
              Location access is recommended for the most accurate prayer times and phase transitions.
              On Apple platforms, analytics rely on App Store Connect / App Analytics rather than direct
              third-party tracking from the app.
            </p>
            <p>
              The public web dashboard may use separate website analytics. The Apple app does not require
              account creation to work. For privacy questions, contact <a href="mailto:islamicdaydial@gmail.com">islamicdaydial@gmail.com</a>.
            </p>
          </section>
        </div>
      </main>
    </div>
  );
}
