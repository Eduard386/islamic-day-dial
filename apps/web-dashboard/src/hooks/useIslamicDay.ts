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
  setLocation: (loc: Location) => void;
  setTimezone: (tz: string) => void;
  setTimeMode: (mode: TimeMode) => void;
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

const DEFAULT_LOCATION: Location = { latitude: 41.0082, longitude: 28.9784 }; // Istanbul
const DEFAULT_TIMEZONE = Intl.DateTimeFormat().resolvedOptions().timeZone;

const SNAPSHOT_INTERVAL_MS = 60_000;
const TICK_INTERVAL_MS = 1_000;

export function useIslamicDay(): DashboardState {
  const [location, setLocation] = useState<Location>(DEFAULT_LOCATION);
  const [timezone, setTimezone] = useState(DEFAULT_TIMEZONE);
  const [timeMode, setTimeMode] = useState<TimeMode>({ kind: 'live' });

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
    setLocation,
    setTimezone,
    setTimeMode,
    effectiveNow: liveNow,
  };
}
