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
        <p className="header-ayah" dir="rtl" lang="ar">
          إِنَّ عِدَّةَ الشُّهُورِ عِندَ اللَّهِ اثْنَا عَشَرَ شَهْرًا
        </p>
        <div className="header-titles">
          <h1>Islamic Day Dial</h1>
          <p className="subtitle">Maghrib to Maghrib</p>
        </div>
      </header>

      <main className="app-main">
        <div className="dial-section">
          <div className="dial-stack">
            <div className="dial-wrapper">
              <IslamicRing snapshot={snapshot} now={effectiveNow} size={420} />
              <div className="center-overlay">
                <CenterInfo snapshot={snapshot} now={effectiveNow} timezone={timezone} />
              </div>
            </div>
            <p className="dial-ayah-translation" lang="en">
              &quot;Indeed, the number of months ordained by Allah is twelve&quot; [9:36]
            </p>
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
