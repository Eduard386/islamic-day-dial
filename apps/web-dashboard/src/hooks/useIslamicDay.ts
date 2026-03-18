import { useState, useEffect, useCallback } from 'react';
import {
  computeIslamicDaySnapshot,
  type UserContext,
  type ComputedIslamicDay,
  type Location,
} from '@islamic-day-dial/core';

export type TimeMode =
  | { kind: 'live' }
  | { kind: 'fixed'; date: Date }
  | { kind: 'offset'; offsetMs: number };

export type DashboardState = {
  snapshot: ComputedIslamicDay;
  location: Location;
  timezone: string;
  timeMode: TimeMode;
  selectedPreset: string;
  setLocation: (loc: Location) => void;
  setTimezone: (tz: string) => void;
  setTimeMode: (mode: TimeMode) => void;
  setSelectedPreset: (name: string) => void;
  applyCurrentCity: () => void;
  effectiveNow: Date;
};

function getEffectiveNow(mode: TimeMode): Date {
  switch (mode.kind) {
    case 'live':
      return new Date();
    case 'fixed':
      return mode.date;
    case 'offset':
      return new Date(Date.now() + mode.offsetMs);
  }
}

const FALLBACK_LOCATION: Location = { latitude: 21.4225, longitude: 39.8262 }; // Mecca
const CURRENT_CITY = 'Current city';
const DEFAULT_PRESET = 'Mecca';

/** Fallback when geolocation fails: use location of a city in user's timezone */
const TIMEZONE_TO_LOCATION: Record<string, Location> = {
  'Europe/Istanbul': { latitude: 41.0082, longitude: 28.9784 },
  'Europe/London': { latitude: 51.5074, longitude: -0.1278 },
  'Europe/Paris': { latitude: 48.8566, longitude: 2.3522 },
  'Europe/Berlin': { latitude: 52.52, longitude: 13.405 },
  'Asia/Riyadh': { latitude: 21.4225, longitude: 39.8262 },
  'Asia/Dubai': { latitude: 25.2048, longitude: 55.2708 },
  'America/New_York': { latitude: 40.7128, longitude: -74.006 },
  'America/Los_Angeles': { latitude: 34.0522, longitude: -118.2437 },
  'Asia/Jakarta': { latitude: -6.2088, longitude: 106.8456 },
  'Asia/Tokyo': { latitude: 35.6762, longitude: 139.6503 },
  'Africa/Cairo': { latitude: 30.0444, longitude: 31.2357 },
  'Australia/Sydney': { latitude: -33.8688, longitude: 151.2093 },
  'America/Sao_Paulo': { latitude: -23.5505, longitude: -46.6333 },
  'Asia/Kolkata': { latitude: 19.076, longitude: 72.8777 },
};

const SNAPSHOT_INTERVAL_MS = 60_000;
const TICK_INTERVAL_MS = 1_000;

export function useIslamicDay(): DashboardState {
  const [location, setLocation] = useState<Location>(FALLBACK_LOCATION);
  const [timezone, setTimezone] = useState(() => Intl.DateTimeFormat().resolvedOptions().timeZone);
  const [timeMode, setTimeMode] = useState<TimeMode>({ kind: 'live' });
  const [selectedPreset, setSelectedPreset] = useState(DEFAULT_PRESET);

  const applyCurrentCity = useCallback(() => {
    setSelectedPreset(CURRENT_CITY);
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    setTimezone(tz);
    const fallbackFromTz = TIMEZONE_TO_LOCATION[tz] ?? FALLBACK_LOCATION;
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setLocation({ latitude: pos.coords.latitude, longitude: pos.coords.longitude }),
        () => setLocation(fallbackFromTz),
        { timeout: 5000, enableHighAccuracy: false },
      );
    } else {
      setLocation(fallbackFromTz);
    }
  }, []);

  useEffect(() => {
    if (selectedPreset === CURRENT_CITY && navigator.geolocation) {
      const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
      const fallbackFromTz = TIMEZONE_TO_LOCATION[tz] ?? FALLBACK_LOCATION;
      navigator.geolocation.getCurrentPosition(
        (pos) => setLocation({ latitude: pos.coords.latitude, longitude: pos.coords.longitude }),
        () => setLocation(fallbackFromTz),
        { timeout: 5000, enableHighAccuracy: false },
      );
    }
  }, [selectedPreset]);

  const computeSnapshot = useCallback((): ComputedIslamicDay => {
    const now = getEffectiveNow(timeMode);
    const ctx: UserContext = { now, location, timezone };
    return computeIslamicDaySnapshot(ctx);
  }, [location, timezone, timeMode]);

  const [snapshot, setSnapshot] = useState(computeSnapshot);
  const [liveNow, setLiveNow] = useState(() => getEffectiveNow(timeMode));

  // Full snapshot recompute every 60s (prayer times via adhan are the heavy part)
  useEffect(() => {
    setSnapshot(computeSnapshot());
    const timer = setInterval(() => setSnapshot(computeSnapshot()), SNAPSHOT_INTERVAL_MS);
    return () => clearInterval(timer);
  }, [computeSnapshot]);

  // Lightweight tick every 1s — only updates the clock and countdown
  useEffect(() => {
    const tick = () => setLiveNow(getEffectiveNow(timeMode));
    tick();
    const timer = setInterval(tick, TICK_INTERVAL_MS);
    return () => clearInterval(timer);
  }, [timeMode]);

  const liveCountdownMs = Math.max(
    0,
    snapshot.nextTransition.at.getTime() - liveNow.getTime(),
  );

  return {
    snapshot: { ...snapshot, countdownMs: liveCountdownMs },
    location,
    timezone,
    timeMode,
    selectedPreset,
    setLocation,
    setTimezone,
    setTimeMode,
    setSelectedPreset,
    applyCurrentCity,
    effectiveNow: liveNow,
  };
}
