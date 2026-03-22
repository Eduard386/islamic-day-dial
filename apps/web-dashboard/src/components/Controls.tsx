import { useState } from 'react';
import type { Location } from '@islamic-day-dial/core';
import type { TimeMode } from '../hooks/useIslamicDay';
import {
  PRESETS_SORTED,
  PRESETS_BY_TITLE,
  MY_LOCATION_TITLE,
  MY_LOCATION_INSERT_INDEX,
} from '../data/locationPresets';

const IS_DEMO = import.meta.env.VITE_DEMO_MODE === 'true';

/** Debug mode = localhost. Show Time Travel only in dev */
const IS_DEBUG = typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1');
const SHOW_DEBUG_UI = IS_DEBUG;

const CURRENT_CITY = MY_LOCATION_TITLE;

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
  const [monthOffset, setMonthOffset] = useState(0);
  const [dayOffset, setDayOffset] = useState(0);
  const [hourOffset, setHourOffset] = useState(0);

  const MS_PER_HOUR = 3600000;
  const MS_PER_DAY = 24 * MS_PER_HOUR;

  const applyTimeOffset = (months: number, days: number, hours: number) => {
    const totalDays = months * 30 + days;
    const totalMs = totalDays * MS_PER_DAY + hours * MS_PER_HOUR;
    if (totalMs === 0) {
      onTimeModeChange({ kind: 'live' });
    } else {
      onTimeModeChange({ kind: 'offset', offsetMs: totalMs });
    }
  };

  const displayedHijriDay = currentHijriDay;

  const presetsByTitle = PRESETS_BY_TITLE;

  const applyPreset = (name: string) => {
    if (name === CURRENT_CITY) {
      onCurrentCity();
      return;
    }
    const p = presetsByTitle[name];
    if (!p) return;
    onLocationChange(p.location);
    onTimezoneChange(p.timezone);
    onPresetSelect(name);
  };

  const presetsLeft = PRESETS_SORTED.slice(0, MY_LOCATION_INSERT_INDEX);
  const presetsRight = PRESETS_SORTED.slice(MY_LOCATION_INSERT_INDEX);

  return (
    <div className="controls">
      {SHOW_DEBUG_UI && (
      <section>
        <h4>Time Travel</h4>
        <div className="input-row">
          <label>
            Months
            <input
              type="range"
              min={-6}
              max={6}
              value={monthOffset}
              onChange={e => {
                const m = parseInt(e.target.value, 10);
                setMonthOffset(m);
                applyTimeOffset(m, dayOffset, hourOffset);
              }}
            />
            <span className="offset-value">
              {monthOffset === 0 ? '0' : `${monthOffset > 0 ? '+' : ''}${monthOffset}m`}
            </span>
          </label>
        </div>
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
                applyTimeOffset(monthOffset, d, hourOffset);
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
                applyTimeOffset(monthOffset, dayOffset, h);
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
              setMonthOffset(0);
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
      <section>
        <h4>Location</h4>
        <div className="preset-buttons">
          {presetsLeft.map((p) => (
            <button
              key={p.id}
              className={selectedPreset === p.title ? 'active' : ''}
              onClick={() => applyPreset(p.title)}
            >
              {p.title}
            </button>
          ))}
          <button
            key={CURRENT_CITY}
            className={selectedPreset === CURRENT_CITY ? 'active' : ''}
            onClick={() => applyPreset(CURRENT_CITY)}
          >
            {CURRENT_CITY}
          </button>
          {presetsRight.map((p) => (
            <button
              key={p.id}
              className={selectedPreset === p.title ? 'active' : ''}
              onClick={() => applyPreset(p.title)}
            >
              {p.title}
            </button>
          ))}
        </div>
      </section>
    </div>
  );
}
