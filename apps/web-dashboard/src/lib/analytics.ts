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

function isOwner(): boolean {
  return localStorage.getItem('__owner__') === 'true';
}

export async function trackVisit(): Promise<void> {
  if (!supabase) {
    console.log('[Analytics] Supabase not configured');
    return;
  }

  if (isOwner()) {
    console.log('[Analytics] Owner excluded');
    return;
  }

  try {
    const { error } = await supabase.from('visits').insert({
      visitor_id: getVisitorId(),
      path: window.location.pathname,
      referrer: document.referrer || null,
      user_agent: navigator.userAgent,
      screen_width: window.screen.width,
      screen_height: window.screen.height,
      language: navigator.language,
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

/** Call this in browser console to exclude yourself */
export function markAsOwner(): void {
  localStorage.setItem('__owner__', 'true');
  console.log('✅ You are now marked as owner. Refresh to apply.');
}

/** Expose to window for easy console access */
if (typeof window !== 'undefined') {
  (window as unknown as Record<string, unknown>).__markAsOwner = markAsOwner;
}
