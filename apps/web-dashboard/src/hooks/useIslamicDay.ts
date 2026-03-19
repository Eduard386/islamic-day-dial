import { useState, useEffect, useCallback } from 'react';
import {
  computeIslamicDaySnapshot,
  getCountdown,
  getCountdownTarget,
  getCurrentPhase,
  getNextTransition,
  getIslamicDayProgress,
  type UserContext,
  type ComputedIslamicDay,
  type Location,
} from '@islamic-day-dial/core';
import { resolveGeo, clearGeoCache } from '../lib/geo';

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
const DEFAULT_PRESET = CURRENT_CITY;

const SNAPSHOT_INTERVAL_MS = 60_000;
const TICK_INTERVAL_MS = 60_000;

export function useIslamicDay(): DashboardState {
  const [location, setLocation] = useState<Location>(FALLBACK_LOCATION);
  const [timezone, setTimezone] = useState(() => Intl.DateTimeFormat().resolvedOptions().timeZone);
  const [timeMode, setTimeMode] = useState<TimeMode>({ kind: 'live' });
  const [selectedPreset, setSelectedPreset] = useState(DEFAULT_PRESET);

  const applyCurrentCity = useCallback(async () => {
    setSelectedPreset(CURRENT_CITY);
    clearGeoCache();
    const geo = await resolveGeo();
    setLocation(geo.location);
    setTimezone(geo.timezone);
  }, []);

  // Resolve location on mount: IP first, timezone fallback. No permission prompt.
  useEffect(() => {
    let cancelled = false;
    resolveGeo().then((geo) => {
      if (!cancelled) {
        setLocation(geo.location);
        setTimezone(geo.timezone);
      }
    });
    return () => { cancelled = true; };
  }, []);

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

  // Lightweight tick every 1s — updates phase, marker, countdown
  useEffect(() => {
    const tick = () => setLiveNow(getEffectiveNow(timeMode));
    tick();
    const timer = setInterval(tick, TICK_INTERVAL_MS);
    return () => clearInterval(timer);
  }, [timeMode]);

  // Safari iOS: when returning to tab (after lock/switch), timers may have been throttled — force refresh
  useEffect(() => {
    const tick = () => setLiveNow(getEffectiveNow(timeMode));
    const onVisibilityChange = () => {
      if (document.visibilityState === 'visible') tick();
    };
    const onPageshow = (e: PageTransitionEvent) => {
      if (e.persisted) tick();
    };
    document.addEventListener('visibilitychange', onVisibilityChange);
    window.addEventListener('pageshow', onPageshow);
    return () => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
      window.removeEventListener('pageshow', onPageshow);
    };
  }, [timeMode]);

  const liveCountdownMs = getCountdown(
    liveNow,
    getCountdownTarget(liveNow, snapshot.timeline),
  );

  const liveSnapshot: ComputedIslamicDay = {
    ...snapshot,
    currentPhase: getCurrentPhase(liveNow, snapshot.timeline),
    nextTransition: getNextTransition(liveNow, snapshot.timeline),
    countdownMs: liveCountdownMs,
    ring: {
      ...snapshot.ring,
      progress: getIslamicDayProgress(
        liveNow,
        snapshot.timeline.lastMaghrib,
        snapshot.timeline.nextMaghrib,
      ),
    },
  };

  return {
    snapshot: liveSnapshot,
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
