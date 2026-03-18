import { useIslamicDay } from './hooks/useIslamicDay';
import { IslamicRing } from './components/IslamicRing';
import { CenterInfo } from './components/CenterInfo';
import { Controls } from './components/Controls';
import './App.css';

export default function App() {
  const state = useIslamicDay();
  const { snapshot, timezone, timeMode, selectedPreset, effectiveNow } = state;

  return (
    <div className="app">
      <header className="app-header">
        <h1>Islamic Day Dial</h1>
        <p className="subtitle">Islamic day visualizer — Maghrib to Maghrib</p>
      </header>

      <main className="app-main">
        <div className="dial-section">
          <div className="dial-wrapper">
            <IslamicRing snapshot={snapshot} size={420} />
            <div className="center-overlay">
              <CenterInfo snapshot={snapshot} now={effectiveNow} timezone={timezone} />
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
