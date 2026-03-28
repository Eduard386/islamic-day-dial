import { getSectorDisplayName } from '@islamic-day-dial/core';
import { useEffect, useMemo, useState } from 'react';
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
  WEB_INSIGHT_AYAH_AR,
  type ReadingKey,
} from './content/desktopContent';
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
  const [selectedReading, setSelectedReading] = useState<{ key: ReadingKey; emphasisId?: string } | null>(null);

  useEffect(() => {
    trackVisit();
  }, []);

  useEffect(() => {
    if (!isDesktop && selectedReading) {
      setSelectedReading(null);
    }
  }, [isDesktop, selectedReading]);

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
          <p className="header-ayah" dir="rtl" lang="ar">
            {WEB_INSIGHT_AYAH_AR}
          </p>
          <div className="header-titles">
            <h1>Islamic Day Dial</h1>
          </div>
        </header>
      )}

      <main className="app-main">
        {isDesktop ? (
          <div className="desktop-shell">
            <DesktopMonthsRail snapshot={snapshot} />

            <section className="desktop-stage">
              <h1 className="desktop-shell-title">Islamic Day Dial</h1>
              <p className="subtitle desktop-stage-subtitle">Maghrib to Maghrib</p>
              <div className="desktop-stage-ring">
                {renderDial(420, 92, true)}
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
              <p className="subtitle dial-stack-subtitle">Maghrib to Maghrib</p>
              <div className="dial-stack-middle">
                <div className="dial-stack-spring" aria-hidden />
                {renderDial(420, 92, false)}
                <div className="dial-stack-spring" aria-hidden />
              </div>
              <p className="dial-ayah-translation" lang="en">
                &quot;Indeed, the number of months ordained by Allah is twelve&quot; [9:36]
              </p>
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
        </div>
      </main>
    </div>
  );
}
