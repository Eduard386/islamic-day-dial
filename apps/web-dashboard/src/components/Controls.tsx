import { useState } from 'react';
import type { Location } from '@islamic-day-dial/core';
import type { TimeMode } from '../hooks/useIslamicDay';

const IS_DEMO = import.meta.env.VITE_DEMO_MODE === 'true';

const CURRENT_CITY = 'Current city';

type Props = {
  location: Location;
  timezone: string;
  timeMode: TimeMode;
  selectedPreset: string;
  onLocationChange: (loc: Location) => void;
  onTimezoneChange: (tz: string) => void;
  onTimeModeChange: (mode: TimeMode) => void;
  onPresetSelect: (name: string) => void;
  onCurrentCity: () => void;
  /** Debug: override hijri day (1–30) for moon phase */
  debugHijriDay?: number;
  onDebugHijriDayChange?: (day: number | undefined) => void;
};

const PRESETS: Record<string, { location: Location; timezone: string }> = {
  Istanbul: { location: { latitude: 41.0082, longitude: 28.9784 }, timezone: 'Europe/Istanbul' },
  Mecca: { location: { latitude: 21.4225, longitude: 39.8262 }, timezone: 'Asia/Riyadh' },
  London: { location: { latitude: 51.5074, longitude: -0.1278 }, timezone: 'Europe/London' },
  'New York': { location: { latitude: 40.7128, longitude: -74.006 }, timezone: 'America/New_York' },
  Jakarta: { location: { latitude: -6.2088, longitude: 106.8456 }, timezone: 'Asia/Jakarta' },
  Tokyo: { location: { latitude: 35.6762, longitude: 139.6503 }, timezone: 'Asia/Tokyo' },
  Cairo: { location: { latitude: 30.0444, longitude: 31.2357 }, timezone: 'Africa/Cairo' },
  Sydney: { location: { latitude: -33.8688, longitude: 151.2093 }, timezone: 'Australia/Sydney' },
  'São Paulo': { location: { latitude: -23.5505, longitude: -46.6333 }, timezone: 'America/Sao_Paulo' },
  Mumbai: { location: { latitude: 19.076, longitude: 72.8777 }, timezone: 'Asia/Kolkata' },
};

export function Controls({
  location,
  timezone,
  timeMode,
  selectedPreset,
  onLocationChange,
  onTimezoneChange,
  onTimeModeChange,
  onPresetSelect,
  onCurrentCity,
  debugHijriDay,
  onDebugHijriDayChange,
}: Props) {
  const [latInput, setLatInput] = useState(String(location.latitude));
  const [lonInput, setLonInput] = useState(String(location.longitude));
  const [tzInput, setTzInput] = useState(timezone);
  const [offsetHours, setOffsetHours] = useState(0);

  const applyManualLocation = () => {
    const lat = parseFloat(latInput);
    const lon = parseFloat(lonInput);
    if (!isNaN(lat) && !isNaN(lon)) {
      onLocationChange({ latitude: lat, longitude: lon });
    }
    if (tzInput) onTimezoneChange(tzInput);
  };

  const applyPreset = (name: string) => {
    if (name === CURRENT_CITY) {
      onCurrentCity();
      return;
    }
    const p = PRESETS[name];
    if (!p) return;
    onLocationChange(p.location);
    onTimezoneChange(p.timezone);
    onPresetSelect(name);
    setLatInput(String(p.location.latitude));
    setLonInput(String(p.location.longitude));
    setTzInput(p.timezone);
  };

  return (
    <div className="controls">
      <h3>Controls</h3>

      <section>
        <h4>Location Presets</h4>
        <div className="preset-buttons">
          <button
            key={CURRENT_CITY}
            className={selectedPreset === CURRENT_CITY ? 'active' : ''}
            onClick={() => applyPreset(CURRENT_CITY)}
          >
            {CURRENT_CITY}
          </button>
          {Object.keys(PRESETS).map((name) => (
            <button
              key={name}
              className={selectedPreset === name ? 'active' : ''}
              onClick={() => applyPreset(name)}
            >
              {name}
            </button>
          ))}
        </div>
      </section>

      {!IS_DEMO && (
      <section>
        <h4>Manual Location</h4>
        <div className="input-row">
          <label>Lat<input value={latInput} onChange={e => setLatInput(e.target.value)} /></label>
          <label>Lon<input value={lonInput} onChange={e => setLonInput(e.target.value)} /></label>
        </div>
        <div className="input-row">
          <label>TZ<input value={tzInput} onChange={e => setTzInput(e.target.value)} /></label>
          <button onClick={applyManualLocation}>Apply</button>
        </div>
      </section>
      )}

      {!IS_DEMO && (
      <section>
        <h4>Time Control</h4>
        <div className="time-buttons">
          <button
            className={timeMode.kind === 'live' ? 'active' : ''}
            onClick={() => onTimeModeChange({ kind: 'live' })}
          >
            Live
          </button>
          <button onClick={() => {
            const off = offsetHours * 3600000;
            onTimeModeChange({ kind: 'offset', offsetMs: off });
          }}>
            Apply Offset
          </button>
        </div>
        <div className="input-row">
          <label>
            Offset (hours)
            <input
              type="range"
              min={-24}
              max={24}
              step={0.25}
              value={offsetHours}
              onChange={e => {
                const h = parseFloat(e.target.value);
                setOffsetHours(h);
                if (timeMode.kind === 'offset') {
                  onTimeModeChange({ kind: 'offset', offsetMs: h * 3600000 });
                }
              }}
            />
            <span className="offset-value">{offsetHours >= 0 ? '+' : ''}{offsetHours}h</span>
          </label>
        </div>
      </section>
      )}

      {!IS_DEMO && onDebugHijriDayChange && (
      <section>
        <h4>Debug: Date</h4>
        <p className="hint">Override Hijri day (1–30) for moon phase</p>
        <div className="input-row">
          <label>
            Hijri day (1–30)
            <input
              type="range"
              min={1}
              max={30}
              value={debugHijriDay ?? 15}
              onChange={e => onDebugHijriDayChange(parseInt(e.target.value, 10))}
            />
            <span className="offset-value">{debugHijriDay ?? 'auto'}</span>
          </label>
          <button onClick={() => onDebugHijriDayChange(undefined)}>Auto</button>
        </div>
      </section>
      )}
    </div>
  );
}
