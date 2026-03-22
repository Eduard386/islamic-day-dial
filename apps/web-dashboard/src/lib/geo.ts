/**
 * Geo resolution: IP-based first, timezone fallback.
 * Single cached fetch shared by location and analytics.
 */

import type { Location } from '@islamic-day-dial/core';

export type GeoResult = {
  location: Location;
  timezone: string;
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
  return {
    location: loc,
    timezone: tz,
  };
}

let geoPromise: Promise<GeoResult> | null = null;

/**
 * Resolve location: try IP (ipapi.co), fallback to timezone mapping.
 * When IP timezone conflicts with browser timezone (e.g. VPN, proxy),
 * prefer browser — user is physically in browser's timezone.
 */
export async function resolveGeo(): Promise<GeoResult> {
  if (geoPromise) return geoPromise;
  const browserTz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  geoPromise = (async () => {
    try {
      const res = await fetch('https://ipapi.co/json/', {
        signal: AbortSignal.timeout(3000),
      });
      if (!res.ok) return getTimezoneFallback();
      const data = await res.json();
      const lat = data.latitude;
      const lng = data.longitude;
      if (typeof lat !== 'number' || typeof lng !== 'number') {
        return getTimezoneFallback();
      }
      const ipTimezone = data.timezone || browserTz;
      const browserLoc = TIMEZONE_TO_LOCATION[browserTz];
      // IP timezone ≠ browser → VPN/proxy; use browser location if we have it
      if (ipTimezone !== browserTz && browserLoc) {
        return {
          location: browserLoc,
          timezone: browserTz,
          country: data.country_name || data.country,
          city: data.city,
          region: data.region,
        };
      }
      return {
        location: { latitude: lat, longitude: lng },
        timezone: ipTimezone,
        country: data.country_name || data.country,
        city: data.city,
        region: data.region,
      };
    } catch {
      return getTimezoneFallback();
    }
  })();
  return geoPromise;
}

/** Clear cache (e.g. for manual refresh) */
export function clearGeoCache(): void {
  geoPromise = null;
}
