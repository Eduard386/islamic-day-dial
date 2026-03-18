# Islamic Day Dial — Core Specification

Single source of truth for `packages/core` (TypeScript) and `apps/apple-watch` (Swift). When changing core logic, update both and verify web + watch.

## Phases (Islamic Day Segments)

| ID | Start | End | Label |
|----|-------|-----|-------|
| maghrib_to_isha | lastMaghrib | isha | Maghrib |
| isha_to_midnight | isha | islamicMidnight | Isha |
| midnight_to_last_third | islamicMidnight | lastThirdStart | Isha 1/2 |
| last_third_to_fajr | lastThirdStart | fajr | Isha 2/3 |
| fajr_to_sunrise | fajr | sunrise | Fajr |
| sunrise_to_dhuhr | sunrise | dhuhr | Duha |
| dhuhr_to_asr | dhuhr | asr | Dhuhr |
| asr_to_maghrib | asr | nextMaghrib | Asr |

## Formulas

- **Islamic midnight**: `(lastMaghrib + fajr) / 2`
- **Last third start**: `fajr - (nightDuration / 3)` where `nightDuration = fajr - lastMaghrib`
- **Progress**: `(now - lastMaghrib) / (nextMaghrib - lastMaghrib)`, clamped 0–1
- **Angle**: `progress * 360` (0° = top = lastMaghrib, clockwise)

## Special Dates (Eid)

- **1 Shawwal (10/1)**: display "EID AL-FITR"
- **10 Dhul Hijjah (12/10)**: display "EID AL-ADHA"

## Colors (Web)

- Gap segments: `#0a0a18`
- Night: `#0a0a12`
- Blue mid: `#3b82a8` / active `#5ba3d4`
- Yellow: `#eab308` / active `#fde047`

## Dependencies

- **Prayer times**: Umm al-Qura method (Adhan)
- **Hijri calendar**: Umm al-Qura (Swift: `Calendar.islamicUmmAlQura`)

## Checklist

When changing core:

1. [ ] Update `packages/core` (TypeScript)
2. [ ] Update `apps/apple-watch/IslamicDayDialWatch/IslamicDayCore` (Swift)
3. [ ] Run `npm test` (web)
4. [ ] Build and verify watch app in Xcode
5. [ ] Update this spec if formulas/phases changed
