import { useEffect } from 'react';
import { useIslamicDay } from './hooks/useIslamicDay';
import { IslamicRing } from './components/IslamicRing';
import { CenterInfo } from './components/CenterInfo';
import { Controls } from './components/Controls';
import { trackVisit } from './lib/analytics';
import './App.css';

export default function App() {
  const state = useIslamicDay();

  useEffect(() => {
    trackVisit();
  }, []);
  const { snapshot, timezone, timeMode, selectedPreset, effectiveNow } = state;

  return (
    <div className="app">
      <header className="app-header">
        <h1>Islamic Day Dial</h1>
        <p className="subtitle">Maghrib to Maghrib</p>
      </header>

      <main className="app-main">
        <div className="dial-section">
          <div className="dials-row">
            <div className="dial-cell">
              <div className="dial-wrapper">
                <IslamicRing snapshot={snapshot} now={effectiveNow} size={420} clock12Anchor="maghrib" />
                <div className="center-overlay">
                  <CenterInfo snapshot={snapshot} now={effectiveNow} timezone={timezone} />
                </div>
              </div>
              <span className="dial-label">12h = Maghrib</span>
            </div>
            <div className="dial-cell">
              <div className="dial-wrapper">
                <IslamicRing snapshot={snapshot} now={effectiveNow} size={420} clock12Anchor="midday" />
                <div className="center-overlay">
                  <CenterInfo snapshot={snapshot} now={effectiveNow} timezone={timezone} />
                </div>
              </div>
              <span className="dial-label">12h = Midday</span>
            </div>
          </div>
        </div>

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
