/**
 * Geo resolution: GPS first, IP (ipapi) fallback, timezone fallback, Mecca default.
 * Single cached fetch shared by location and analytics.
 */

import type { Location } from '@islamic-day-dial/core';

export type GeoSource = 'gps' | 'ip' | 'timezone' | 'default';

export type GeoResult = {
  location: Location;
  timezone: string;
  source: GeoSource;
  country?: string;
  city?: string;
  region?: string;
};

const TIMEZONE_TO_LOCATION: Record<string, Location> = {
  'Europe/Istanbul': { latitude: 41.0082, longitude: 28.9784 },
  'Europe/London': { latitude: 51.5074, longitude: -0.1278 },
  'Europe/Paris': { latitude: 48.8566, longitude: 2.3522 },
  'Europe/Berlin': { latitude: 52.52, longitude: 13.405 },
  'Europe/Kyiv': { latitude: 50.4501, longitude: 30.5234 },
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
  'America/Mexico_City': { latitude: 19.4326, longitude: -99.1332 },
  'Asia/Shanghai': { latitude: 31.2304, longitude: 121.4737 },
  'Asia/Seoul': { latitude: 37.5665, longitude: 126.978 },
  'Africa/Lagos': { latitude: 6.5244, longitude: 3.3792 },
  'Europe/Moscow': { latitude: 55.7558, longitude: 37.6173 },
  'America/Toronto': { latitude: 43.6532, longitude: -79.3832 },
  'America/Argentina/Buenos_Aires': { latitude: -34.6037, longitude: -58.3816 },
};

const FALLBACK_LOCATION: Location = { latitude: 21.4225, longitude: 39.8262 }; // Mecca

function getTimezoneFallback(): GeoResult {
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const loc = TIMEZONE_TO_LOCATION[tz] ?? FALLBACK_LOCATION;
  const source: GeoSource = TIMEZONE_TO_LOCATION[tz] ? 'timezone' : 'default';
  return { location: loc, timezone: tz, source };
}

function getLocationFromGPS(): Promise<GeoResult | null> {
  if (typeof navigator === 'undefined' || !navigator.geolocation) return Promise.resolve(null);
  return new Promise((resolve) => {
    const timeout = setTimeout(() => resolve(null), 5000);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        clearTimeout(timeout);
        resolve({
          location: { latitude: pos.coords.latitude, longitude: pos.coords.longitude },
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          source: 'gps',
        });
      },
      () => {
        clearTimeout(timeout);
        resolve(null);
      },
      { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 },
    );
  });
}

async function fetchFromIP(): Promise<GeoResult | null> {
  if (typeof navigator !== 'undefined' && !navigator.onLine) return null;
  try {
    const res = await fetch('https://ipapi.co/json/', { signal: AbortSignal.timeout(3000) });
    if (!res.ok) return null;
    const data = await res.json();
    const lat = data.latitude;
    const lng = data.longitude;
    if (typeof lat !== 'number' || typeof lng !== 'number') return null;
    const browserTz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const ipTimezone = data.timezone || browserTz;
    const browserLoc = TIMEZONE_TO_LOCATION[browserTz];
    if (ipTimezone !== browserTz && browserLoc) {
      return {
        location: browserLoc,
        timezone: browserTz,
        source: 'ip',
        country: data.country_name || data.country,
        city: data.city,
        region: data.region,
      };
    }
    return {
      location: { latitude: lat, longitude: lng },
      timezone: ipTimezone,
      source: 'ip',
      country: data.country_name || data.country,
      city: data.city,
      region: data.region,
    };
  } catch {
    return null;
  }
}

let geoPromise: Promise<GeoResult> | null = null;

/** GPS first, then IP (ipapi.co), then timezone, Mecca default. */
export async function resolveGeo(): Promise<GeoResult> {
  if (geoPromise) return geoPromise;
  geoPromise = (async () => {
    const gps = await getLocationFromGPS();
    if (gps) return gps;
    const ip = await fetchFromIP();
    if (ip) return ip;
    return getTimezoneFallback();
  })();
  return geoPromise;
}

/** Clear cache (e.g. for manual refresh) */
export function clearGeoCache(): void {
  geoPromise = null;
}
