# Islamic Day Dial — Core Specification

**Source of truth for visual behavior**: `apps/web-dashboard` (Vite + React). Android (Wear OS) and iOS (Apple Watch) apps should match the web dashboard. When changing core logic or ring visuals, update web first, then sync to other platforms.

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
  - Fajr → до появления надписи DUHA (sunrise + 20 min)
  - Sunrise_to_dhuhr, до DUHA → до появления DUHA
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

## Dependencies

- **Prayer times**: Umm al-Qura method (Adhan)
  - **Isha**: по исчезновению вечерней зари (хадис) — угол 15°, Shafaq.Ahmer (красная заря), не фиксированный интервал
- **Hijri calendar**: Umm al-Qura (Swift: `Calendar.islamicUmmAlQura`)

## Checklist

When changing core:

1. [ ] Update `packages/core` (TypeScript)
2. [ ] Update `apps/apple-watch/IslamicDayDialWatch/IslamicDayCore` (Swift)
3. [ ] Run `npm test` (web)
4. [ ] Build and verify watch app in Xcode
5. [ ] Update this spec if formulas/phases changed
