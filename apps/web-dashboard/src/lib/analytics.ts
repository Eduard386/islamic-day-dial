import { createClient } from '@supabase/supabase-js';
import { resolveGeo } from './geo.js';

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

export async function trackVisit(): Promise<void> {
  checkUrlForOwner();
  
  if (!supabase || isOwner()) return;

  try {
    const ua = navigator.userAgent;
    const geo = await resolveGeo();
    
    const { error } = await supabase.from('visits').insert({
      visitor_id: getVisitorId(),
      platform: 'web',
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
      geo_source: geo.source,
    });

    if (error && import.meta.env.DEV) {
      console.error('[Analytics]', error.message);
    }
  } catch {
    if (import.meta.env.DEV) console.error('[Analytics] Failed');
  }
}

