# Islamic Day Dial — Web Dashboard

**Source of truth** for ring visuals, sun marker, and phase display. The iPhone app, iPhone widget, Apple Watch app, and Wear OS app should match this implementation.

## Run

```bash
npm run dev
```

## Key files

- `src/components/IslamicRing.tsx` — ring, segments, glow
- `src/components/CurrentMarker.tsx` — sun/moon marker, roll-out/roll-in, orange/red sun, outer glow
- `src/lib/segment-gradients.ts` — ring colors (source of truth)
- `src/lib/current-marker.ts` — night/moon phase logic

## Spec

See root `CORE_SPEC.md` for formulas, phases, ring colors, and **Sun Marker Visual States** (orange sunrise, red Maghrib, outer glow).
