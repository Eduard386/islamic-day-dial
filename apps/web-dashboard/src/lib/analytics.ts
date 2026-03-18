import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

const supabase = SUPABASE_URL && SUPABASE_ANON_KEY
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;

function getVisitorId(): string {
  const key = '__visitor_id__';
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

const OWNER_KEY = '__owner__';
const OWNER_SECRET = 'idd2026';

function checkUrlForOwner(): void {
  const params = new URLSearchParams(window.location.search);
  if (params.get('owner') === OWNER_SECRET) {
    localStorage.setItem(OWNER_KEY, 'true');
    const url = new URL(window.location.href);
    url.searchParams.delete('owner');
    window.history.replaceState({}, '', url.toString());
    console.log('✅ You are now marked as owner');
  }
}

function isOwner(): boolean {
  return localStorage.getItem(OWNER_KEY) === 'true';
}

function detectOS(ua: string): string {
  if (/Windows/.test(ua)) return 'Windows';
  if (/iPhone|iPad|iPod/.test(ua)) return 'iOS';
  if (/Mac OS X/.test(ua)) return 'macOS';
  if (/Android/.test(ua)) return 'Android';
  if (/Linux/.test(ua)) return 'Linux';
  if (/CrOS/.test(ua)) return 'ChromeOS';
  return 'Unknown';
}

function detectBrowser(ua: string): string {
  if (/Edg\//.test(ua)) return 'Edge';
  if (/OPR\/|Opera/.test(ua)) return 'Opera';
  if (/Chrome\//.test(ua) && !/Edg\//.test(ua)) return 'Chrome';
  if (/Safari\//.test(ua) && !/Chrome\//.test(ua)) return 'Safari';
  if (/Firefox\//.test(ua)) return 'Firefox';
  if (/MSIE|Trident/.test(ua)) return 'IE';
  return 'Unknown';
}

function detectDeviceType(ua: string): string {
  if (/iPad/.test(ua)) return 'tablet';
  if (/Mobile|iPhone|iPod|Android.*Mobile/.test(ua)) return 'mobile';
  if (/Android/.test(ua)) return 'tablet';
  return 'desktop';
}

interface GeoData {
  country?: string;
  city?: string;
  region?: string;
  timezone?: string;
}

async function getGeoData(): Promise<GeoData> {
  try {
    const res = await fetch('https://ipapi.co/json/', { signal: AbortSignal.timeout(3000) });
    if (!res.ok) return {};
    const data = await res.json();
    return {
      country: data.country_name || data.country,
      city: data.city,
      region: data.region,
      timezone: data.timezone,
    };
  } catch {
    return {};
  }
}

export async function trackVisit(): Promise<void> {
  checkUrlForOwner();
  
  if (!supabase) {
    console.log('[Analytics] Supabase not configured');
    return;
  }

  if (isOwner()) {
    console.log('[Analytics] Owner excluded');
    return;
  }

  try {
    const ua = navigator.userAgent;
    const geo = await getGeoData();
    
    const { error } = await supabase.from('visits').insert({
      visitor_id: getVisitorId(),
      path: window.location.pathname,
      referrer: document.referrer || null,
      user_agent: ua,
      screen_width: window.screen.width,
      screen_height: window.screen.height,
      language: navigator.language,
      os: detectOS(ua),
      browser: detectBrowser(ua),
      device_type: detectDeviceType(ua),
      country: geo.country || null,
      city: geo.city || null,
      region: geo.region || null,
      timezone: geo.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone,
    });

    if (error) {
      console.error('[Analytics] Error:', error.message);
    } else {
      console.log('[Analytics] Visit tracked');
    }
  } catch (err) {
    console.error('[Analytics] Failed:', err);
  }
}

