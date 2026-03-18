import { useState } from 'react';
import { useIslamicDay } from './hooks/useIslamicDay';
import { IslamicRing } from './components/IslamicRing';
import { CenterInfo } from './components/CenterInfo';
import { DebugPanel } from './components/DebugPanel';
import { Controls } from './components/Controls';
import './App.css';

const IS_DEMO = import.meta.env.VITE_DEMO_MODE === 'true';

export default function App() {
  const state = useIslamicDay();
  const { snapshot, location, timezone, timeMode, selectedPreset, effectiveNow } = state;
  const [debugHijriDay, setDebugHijriDay] = useState<number | undefined>();

  return (
    <div className="app">
      <header className="app-header">
        <h1>Islamic Day Dial</h1>
        <p className="subtitle">Islamic day visualizer — Maghrib to Maghrib</p>
      </header>

      <main className="app-main">
        <div className="dial-section">
          <div className="dial-wrapper">
            <IslamicRing snapshot={snapshot} size={420} debugHijriDay={!IS_DEMO ? debugHijriDay : undefined} />
            <div className="center-overlay">
              <CenterInfo snapshot={snapshot} now={effectiveNow} timezone={timezone} />
            </div>
          </div>
        </div>

        <div className="controls-section">
          <Controls
            location={location}
            timezone={timezone}
            timeMode={timeMode}
            selectedPreset={selectedPreset}
            onLocationChange={state.setLocation}
            onTimezoneChange={state.setTimezone}
            onTimeModeChange={state.setTimeMode}
            onPresetSelect={state.setSelectedPreset}
            onCurrentCity={state.applyCurrentCity}
            debugHijriDay={!IS_DEMO ? debugHijriDay : undefined}
            onDebugHijriDayChange={!IS_DEMO ? setDebugHijriDay : undefined}
          />
          {!IS_DEMO && (
            <DebugPanel
              snapshot={snapshot}
              location={location}
              timezone={timezone}
              now={effectiveNow}
              debugHijriDay={debugHijriDay}
              onDebugHijriDayChange={setDebugHijriDay}
            />
          )}
        </div>
      </main>
    </div>
  );
}
