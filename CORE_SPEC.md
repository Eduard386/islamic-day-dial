# Islamic Day Dial — Core Specification

**Source of truth for visual behavior**: `apps/web-dashboard` (Vite + React). Apple platforms (iPhone app, iPhone widget, watch app, watch complication/widget) and Android surfaces should match the web dashboard. When changing core logic or ring visuals, update web first, then sync to other platforms.

## Phases (Islamic Day Segments)

| ID | Start | End | Label |
|----|-------|-----|-------|
| maghrib_to_isha | lastMaghrib | isha | Maghrib |
| isha_to_midnight | isha | lastThirdStart | Isha |
| last_third_to_fajr | lastThirdStart | fajr | Isha (neon blue) |
| fajr_to_sunrise | fajr | sunrise | Fajr |
| sunrise_to_dhuhr | sunrise | dhuhr | Duha |
| dhuhr_to_asr | dhuhr | asr | Dhuhr |
| asr_to_maghrib | asr | nextMaghrib | Asr |

## Formulas

- **Islamic midnight**: `(lastMaghrib + fajr) / 2`
- **Last third start**: `fajr - (nightDuration / 3)` where `nightDuration = fajr - lastMaghrib`
- **Progress**: `(now - lastMaghrib) / (nextMaghrib - lastMaghrib)`, clamped 0–1
- **Angle**: `progress * 360` (0° = top = lastMaghrib, clockwise)
- **Countdown** (вместо текущего времени): целевое время зависит от фазы:
  - Fajr → до duhaStart (солнце 4° над горизонтом)
  - Sunrise_to_dhuhr, до DUHA → до duhaStart
  - Sunrise_to_dhuhr, DUHA видна → до Dhuhr
  - Dhuhr → до Asr
  - Asr → до Maghrib
  - Maghrib → до Isha
  - Isha → до Fajr

## Mirror Segment (Web)

From Fajr, a segment of the same **angular span** as Asr→Isha uses a mirrored gradient: black → yellow → blue. This creates visual symmetry: evening (Asr→Isha) fades red→black; morning (Fajr→Fajr+span) fades black→yellow→blue. Span in degrees: `(360 - asrAngle) + ishaAngle`.

## Special Dates (Eid)

- **1 Shawwal (10/1)**: display "EID AL-FITR"
- **10 Dhul Hijjah (12/10)**: display "EID AL-ADHA"

## Ring Colors (Web Dashboard — Source of Truth)

Defined in `apps/web-dashboard/src/lib/segment-gradients.ts`.

- **Night** (isha_to_midnight, last_third_to_fajr): `#000000`
- **Maghrib → Isha**: red sunset `#C84A3A` → black (smooth gradient)
- **Asr → Maghrib**: blue `#7CB8E8` → red sunset
- **Mirror segment** (from Fajr, same angular span as Asr→Isha): black → yellow → blue (smooth fade out of night)
- **Fajr → Sunrise** (fallback when outside mirror): black → dark blue → `#7CB8E8`
- **Sunrise → Dhuhr**: flat blue `#7CB8E8`
- **Dhuhr → Asr**: flat blue `#7CB8E8`

## Sun Marker Visual States (Web Dashboard — Source of Truth)

Defined in `apps/web-dashboard/src/components/CurrentMarker.tsx`. Implement on Apple platforms to match.

### Sub-periods within sunrise_to_dhuhr

`getSunriseToDhuhrSubPeriod(now, duhaStart, dhuhr)` → `'sunrise' | 'duha' | 'midday'` (from `packages/core`):
- **sunrise**: from sunrise until **duhaStart** (sun at 4° altitude) — sun is **orange**
- **duha**: from duhaStart until 5 min before Dhuhr — sun is **normal** (yellow)
- **midday**: last 5 min before Dhuhr — sun is normal

**duhaStart** is computed dynamically (solar altitude 4°, per hadith “высота копья”): `getDuhaStart(sunrise, dhuhr, location)` in `packages/core/src/day-bounds.ts`. Varies by latitude and season.

### Sun color by state

| Condition | Sun color | Outer glow |
|-----------|-----------|------------|
| `currentPhase === 'sunrise_to_dhuhr'` and sub-period `'sunrise'` | Orange (#ff6f00) | Orange halo |
| `asr_to_maghrib` and sun within 8° of Maghrib boundary | Red (#c62828) | Red halo |
| Otherwise | Normal yellow (#ffca28) | Light yellow halo |

### Roll zones (degrees)

- **ROLL_ZONE_DEG** = 10 — mask/reveal zone at Sunrise (roll-out) and Maghrib (roll-in)
- **RED_SUN_ZONE_DEG** = 8 — sun turns red only when within 8° of Maghrib (visually touching)

### Outer glow

**Orange/red sun:**
- strokeWidth: 24, blur: 8
- Colors: orange `rgba(255, 111, 0, 0.85)`, red `rgba(198, 40, 40, 0.9)`

**Normal yellow sun** (light glow):
- strokeWidth: 16, blur: 5
- Color: `rgba(255, 202, 40, 0.35)`

Rendered as separate circle with thick stroke, blurred (like last third glow)

### Neon ring (all day phases)

- Orange/red sun: use `grad-sunrise-neon` / `grad-maghrib-neon` gradients
- Normal sun: use segment gradient (`grad-${currentPhase}`)

## Dependencies

- **Prayer times**: Umm al-Qura method (Adhan)
  - **Isha**: по исчезновению вечерней зари (хадис) — угол 15°, Shafaq.Ahmer (красная заря), не фиксированный интервал
- **Hijri calendar**: Umm al-Qura (Swift: `Calendar.islamicUmmAlQura`)

## Checklist

When changing core:

1. [ ] Update `packages/core` (TypeScript)
2. [ ] Update the shared Swift implementation used by `IslamicDayDial`, `IslamicDayDialWidget`, `IslamicDayDialWatch`, and the watch WidgetKit complication surface
3. [ ] Run `npm test` (web)
4. [ ] Build and verify iPhone app / widget / watch app / watch complication in Xcode
5. [ ] Update this spec if formulas/phases changed
6. [ ] When porting visuals: `apps/web-dashboard` is source of truth — match sun marker colors, roll zones, outer glow
