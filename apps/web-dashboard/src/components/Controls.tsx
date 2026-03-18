import { useState } from 'react';
import type { Location } from '@islamic-day-dial/core';
import type { TimeMode } from '../hooks/useIslamicDay';

const IS_DEMO = import.meta.env.VITE_DEMO_MODE === 'true';

const CURRENT_CITY = 'Current city';

type Props = {
  timeMode: TimeMode;
  selectedPreset: string;
  currentHijriDay: number;
  onLocationChange: (loc: Location) => void;
  onTimezoneChange: (tz: string) => void;
  onTimeModeChange: (mode: TimeMode) => void;
  onPresetSelect: (name: string) => void;
  onCurrentCity: () => void;
};

const PRESETS: Record<string, { location: Location; timezone: string }> = {
  // Major Muslim cities (one per country)
  Mecca: { location: { latitude: 21.4225, longitude: 39.8262 }, timezone: 'Asia/Riyadh' },
  Istanbul: { location: { latitude: 41.0082, longitude: 28.9784 }, timezone: 'Europe/Istanbul' },
  Kyiv: { location: { latitude: 50.4501, longitude: 30.5234 }, timezone: 'Europe/Kyiv' },
  Jakarta: { location: { latitude: -6.2088, longitude: 106.8456 }, timezone: 'Asia/Jakarta' },
  Cairo: { location: { latitude: 30.0444, longitude: 31.2357 }, timezone: 'Africa/Cairo' },
  Karachi: { location: { latitude: 24.8607, longitude: 67.0011 }, timezone: 'Asia/Karachi' },
  Dhaka: { location: { latitude: 23.8103, longitude: 90.4125 }, timezone: 'Asia/Dhaka' },
  Tehran: { location: { latitude: 35.6892, longitude: 51.389 }, timezone: 'Asia/Tehran' },
  Baghdad: { location: { latitude: 33.3152, longitude: 44.3661 }, timezone: 'Asia/Baghdad' },
  Casablanca: { location: { latitude: 33.5731, longitude: -7.5898 }, timezone: 'Africa/Casablanca' },
  Algiers: { location: { latitude: 36.7538, longitude: 3.0588 }, timezone: 'Africa/Algiers' },
  Khartoum: { location: { latitude: 15.5007, longitude: 32.5599 }, timezone: 'Africa/Khartoum' },
  'Kuala Lumpur': { location: { latitude: 3.139, longitude: 101.6869 }, timezone: 'Asia/Kuala_Lumpur' },
  Dubai: { location: { latitude: 25.2048, longitude: 55.2708 }, timezone: 'Asia/Dubai' },
  Kabul: { location: { latitude: 34.5553, longitude: 69.2075 }, timezone: 'Asia/Kabul' },
  Tashkent: { location: { latitude: 41.2995, longitude: 69.2401 }, timezone: 'Asia/Tashkent' },
  Tunis: { location: { latitude: 36.8065, longitude: 10.1815 }, timezone: 'Africa/Tunis' },
  Dakar: { location: { latitude: 14.7167, longitude: -17.4677 }, timezone: 'Africa/Dakar' },

  // Largest world cities
  Tokyo: { location: { latitude: 35.6762, longitude: 139.6503 }, timezone: 'Asia/Tokyo' },
  Delhi: { location: { latitude: 28.7041, longitude: 77.1025 }, timezone: 'Asia/Kolkata' },
  Shanghai: { location: { latitude: 31.2304, longitude: 121.4737 }, timezone: 'Asia/Shanghai' },
  'São Paulo': { location: { latitude: -23.5505, longitude: -46.6333 }, timezone: 'America/Sao_Paulo' },
  'Mexico City': { location: { latitude: 19.4326, longitude: -99.1332 }, timezone: 'America/Mexico_City' },
  Mumbai: { location: { latitude: 19.076, longitude: 72.8777 }, timezone: 'Asia/Kolkata' },
  Beijing: { location: { latitude: 39.9042, longitude: 116.4074 }, timezone: 'Asia/Shanghai' },
  Lagos: { location: { latitude: 6.5244, longitude: 3.3792 }, timezone: 'Africa/Lagos' },
  'New York': { location: { latitude: 40.7128, longitude: -74.006 }, timezone: 'America/New_York' },
  London: { location: { latitude: 51.5074, longitude: -0.1278 }, timezone: 'Europe/London' },
  Paris: { location: { latitude: 48.8566, longitude: 2.3522 }, timezone: 'Europe/Paris' },
  Moscow: { location: { latitude: 55.7558, longitude: 37.6173 }, timezone: 'Europe/Moscow' },
  Seoul: { location: { latitude: 37.5665, longitude: 126.978 }, timezone: 'Asia/Seoul' },
  Bangkok: { location: { latitude: 13.7563, longitude: 100.5018 }, timezone: 'Asia/Bangkok' },
  'Buenos Aires': { location: { latitude: -34.6037, longitude: -58.3816 }, timezone: 'America/Argentina/Buenos_Aires' },
  Manila: { location: { latitude: 14.5995, longitude: 120.9842 }, timezone: 'Asia/Manila' },
  'Ho Chi Minh': { location: { latitude: 10.8231, longitude: 106.6297 }, timezone: 'Asia/Ho_Chi_Minh' },
  'Hong Kong': { location: { latitude: 22.3193, longitude: 114.1694 }, timezone: 'Asia/Hong_Kong' },
  Singapore: { location: { latitude: 1.3521, longitude: 103.8198 }, timezone: 'Asia/Singapore' },
  Sydney: { location: { latitude: -33.8688, longitude: 151.2093 }, timezone: 'Australia/Sydney' },
  'Los Angeles': { location: { latitude: 34.0522, longitude: -118.2437 }, timezone: 'America/Los_Angeles' },
  Toronto: { location: { latitude: 43.6532, longitude: -79.3832 }, timezone: 'America/Toronto' },
  Berlin: { location: { latitude: 52.52, longitude: 13.405 }, timezone: 'Europe/Berlin' },
  Madrid: { location: { latitude: 40.4168, longitude: -3.7038 }, timezone: 'Europe/Madrid' },
  Rome: { location: { latitude: 41.9028, longitude: 12.4964 }, timezone: 'Europe/Rome' },
  Johannesburg: { location: { latitude: -26.2041, longitude: 28.0473 }, timezone: 'Africa/Johannesburg' },
  Nairobi: { location: { latitude: -1.2921, longitude: 36.8219 }, timezone: 'Africa/Nairobi' },
};

export function Controls({
  timeMode,
  selectedPreset,
  currentHijriDay,
  onLocationChange,
  onTimezoneChange,
  onTimeModeChange,
  onPresetSelect,
  onCurrentCity,
}: Props) {
  const [dayOffset, setDayOffset] = useState(0);
  const [hourOffset, setHourOffset] = useState(0);

  const MS_PER_HOUR = 3600000;
  const MS_PER_DAY = 24 * MS_PER_HOUR;

  const applyTimeOffset = (days: number, hours: number) => {
    const totalMs = days * MS_PER_DAY + hours * MS_PER_HOUR;
    if (totalMs === 0) {
      onTimeModeChange({ kind: 'live' });
    } else {
      onTimeModeChange({ kind: 'offset', offsetMs: totalMs });
    }
  };

  const displayedHijriDay = currentHijriDay;

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
  };

  return (
    <div className="controls">
      <section>
        <h4>Location</h4>
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
        <h4>Time Travel</h4>
        <div className="input-row">
          <label>
            Days
            <input
              type="range"
              min={-15}
              max={15}
              value={dayOffset}
              onChange={e => {
                const d = parseInt(e.target.value, 10);
                setDayOffset(d);
                applyTimeOffset(d, hourOffset);
              }}
            />
            <span className="offset-value">
              {dayOffset === 0 ? '0' : `${dayOffset > 0 ? '+' : ''}${dayOffset}d`}
            </span>
          </label>
        </div>
        <div className="input-row">
          <label>
            Hours
            <input
              type="range"
              min={-12}
              max={12}
              step={0.5}
              value={hourOffset}
              onChange={e => {
                const h = parseFloat(e.target.value);
                setHourOffset(h);
                applyTimeOffset(dayOffset, h);
              }}
            />
            <span className="offset-value">
              {hourOffset === 0 ? '0' : `${hourOffset > 0 ? '+' : ''}${hourOffset}h`}
            </span>
          </label>
        </div>
        <div className="input-row">
          <span className="hijri-day-display">Day {displayedHijriDay}</span>
          <button
            className={timeMode.kind === 'live' ? 'active' : ''}
            onClick={() => {
              setDayOffset(0);
              setHourOffset(0);
              onTimeModeChange({ kind: 'live' });
            }}
          >
            Now
          </button>
        </div>
      </section>
      )}
    </div>
  );
}
