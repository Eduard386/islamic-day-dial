import { describe, it, expect, beforeEach, vi } from 'vitest';
import { resolveGeo, clearGeoCache } from '../geo.js';

describe('resolveGeo', () => {
  const MECCA = { latitude: 21.4225, longitude: 39.8262 };

  function mockGeolocation(impl: Partial<Geolocation>) {
    Object.defineProperty(navigator, 'geolocation', { value: impl, writable: true, configurable: true });
  }

  beforeEach(() => {
    clearGeoCache();
    if (typeof navigator !== 'undefined') {
      Object.defineProperty(navigator, 'onLine', { value: true, writable: true, configurable: true });
      mockGeolocation({
        getCurrentPosition: vi.fn((_s, err) => err?.()),
        watchPosition: vi.fn(),
        clearWatch: vi.fn(),
      } as unknown as Geolocation);
    }
  });

  it('returns GPS location when geolocation succeeds', async () => {
    mockGeolocation({
      getCurrentPosition: vi.fn((success) => success({ coords: { latitude: 50.45, longitude: 30.52 } })),
      watchPosition: vi.fn(),
      clearWatch: vi.fn(),
    } as unknown as Geolocation);
    const geo = await resolveGeo();
    expect(geo.location).toEqual({ latitude: 50.45, longitude: 30.52 });
    expect(geo.source).toBe('gps');
    vi.unstubAllGlobals();
  });

  it('returns IP location when fetch succeeds (GPS unavailable)', async () => {
    const browserTz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () =>
          Promise.resolve({
            latitude: 50.45,
            longitude: 30.52,
            timezone: browserTz,
            country_name: 'Ukraine',
            city: 'Kyiv',
          }),
      }),
    );
    const geo = await resolveGeo();
    expect(geo.location).toEqual({ latitude: 50.45, longitude: 30.52 });
    expect(geo.timezone).toBe(browserTz);
    expect(geo.source).toBe('ip');
    vi.unstubAllGlobals();
  });

  it('falls back to timezone when fetch fails (network error)', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network error')));
    const geo = await resolveGeo();
    expect(geo.location).toBeDefined();
    expect(geo.timezone).toBe(Intl.DateTimeFormat().resolvedOptions().timeZone);
    expect(['timezone', 'default']).toContain(geo.source);
    vi.unstubAllGlobals();
  });

  it('falls back when response is not ok', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false }));
    const geo = await resolveGeo();
    expect(geo.location).toBeDefined();
    expect(['timezone', 'default']).toContain(geo.source);
    vi.unstubAllGlobals();
  });

  it('falls back when IP returns invalid lat/lng', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () =>
          Promise.resolve({
            latitude: null,
            longitude: null,
            timezone: 'Europe/Kyiv',
          }),
      }),
    );
    const geo = await resolveGeo();
    expect(geo.location).toBeDefined();
    expect(['timezone', 'default']).toContain(geo.source);
    vi.unstubAllGlobals();
  });

  it('skips fetch and uses timezone when navigator.onLine is false', async () => {
    Object.defineProperty(navigator, 'onLine', { value: false, writable: true, configurable: true });
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const geo = await resolveGeo();
    expect(fetchSpy).not.toHaveBeenCalled();
    expect(geo.source).toMatch(/timezone|default/);
    vi.unstubAllGlobals();
  });

  it('uses Mecca when timezone unknown (default fallback)', async () => {
    const originalResolvedOptions = Intl.DateTimeFormat.prototype.resolvedOptions;
    vi.spyOn(Intl.DateTimeFormat.prototype, 'resolvedOptions').mockReturnValue({
      ...originalResolvedOptions.call(new Intl.DateTimeFormat()),
      timeZone: 'Antarctica/South_Pole', // unlikely to be in our map
    });
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
    const geo = await resolveGeo();
    expect(geo.location).toEqual(MECCA);
    expect(geo.source).toBe('default');
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('clears cache when clearGeoCache is called', async () => {
    const browserTz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () =>
          Promise.resolve({
            latitude: 50,
            longitude: 30,
            timezone: browserTz,
          }),
      }),
    );
    const geo1 = await resolveGeo();
    clearGeoCache();
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () =>
          Promise.resolve({
            latitude: 41,
            longitude: 29,
            timezone: browserTz,
          }),
      }),
    );
    const geo2 = await resolveGeo();
    expect(geo1.location.latitude).toBe(50);
    expect(geo2.location.latitude).toBe(41);
    vi.unstubAllGlobals();
  });
});
