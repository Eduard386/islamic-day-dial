# Islamic Day Dial — Apple Platforms

This Xcode project now ships three Apple surfaces in one product:

- `IslamicDayDial` — the main iPhone app with the full dial, location presets, status cards, and prayer times
- `IslamicDayDialWatch` — the watchOS companion app
- `IslamicDayDialWidget` — an iPhone Home Screen widget

The web dashboard in `apps/web-dashboard` remains the visual source of truth.

## Setup

1. Install the latest Xcode available for your macOS and make sure both `iOS` and `watchOS` platforms are installed in `Xcode -> Settings -> Platforms`.
2. Open the project:

   ```bash
   cd apps/apple-watch
   open IslamicDayDial.xcodeproj
   ```

3. If you change `project.yml`, regenerate the Xcode project:

   ```bash
   xcodegen generate
   ```

## Targets

### `IslamicDayDial`

The main iPhone app. This is the primary product surface and should be the default target when iterating on the iPhone UI.

What it includes:

- full ring UI rendered natively in SwiftUI
- current period / Hijri date / countdown center overlay
- location presets with automatic fallback
- prayer times list
- **local notifications** for Fajr, Dhuhr, Asr, Maghrib, Isha (rescheduled on app launch and when returning from background)
- embedded watch companion and widget extension

### `IslamicDayDialWatch`

The companion watchOS app. It reuses the same dial logic and rendering files that power the iPhone app.

### Prayer notifications (iOS)

`PrayerNotificationScheduler` schedules local notifications for Fajr, Dhuhr, Asr, Maghrib, Isha. Title: Hijri date (day month year). Body: prayer name + Quran 4:103. Rescheduled on app launch and when returning from background (handles travel).

### `IslamicDayDialWidget`

The iPhone widget extension. It uses the same snapshot and ring logic to show the current phase, countdown, and mini dial from the Home Screen.

## Shared Swift logic

The following Swift files are compiled into multiple targets through `project.yml`:

- `IslamicDayDialWatch/IslamicDayCore/` — Swift port of `packages/core`
- `IslamicDayDialWatch/RingView.swift`
- `IslamicDayDialWatch/Geometry.swift`
- `IslamicDayDialWatch/Colors.swift`

This keeps the ring math and display behavior aligned across iPhone, widget, and watch without duplicating algorithms.

## Run on device

### iPhone app

- Connect the iPhone to the Mac
- Choose the `IslamicDayDial` scheme
- Select the physical iPhone as the run destination
- Run the app

### Watch app

- Pair the iPhone with Xcode first
- Make sure the Apple Watch appears in `Window -> Devices and Simulators`
- Choose the `IslamicDayDialWatch` scheme
- Select the physical watch as the run destination
- Run the app

If you only run the iPhone app, the watch companion is also embedded inside the iPhone app bundle and can be installed through the Watch app when available.

### Widget

- Run the `IslamicDayDial` iPhone app once
- Long-press the iPhone Home Screen
- Tap `Edit` / `Add Widget`
- Search for `Islamic Day Dial`

## Testing

Run unit tests:

```bash
npm run test:ios
```

Tests cover: duha sector start (4° solar altitude), countdown, glow windows, prayer notification content format, geometry, geo resolution.

## Build from command line

```bash
# iPhone app (also builds the widget extension)
xcodebuild -scheme IslamicDayDial -destination 'platform=iOS Simulator,name=iPhone 16' build

# watchOS app
xcodebuild -scheme IslamicDayDialWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
```

## Porting from web

`apps/web-dashboard` defines the visual source of truth. When porting changes:

1. Update the web implementation first.
2. Keep ring colors and gradients aligned with `src/lib/segment-gradients.ts`.
3. Keep current marker behavior aligned with `src/components/CurrentMarker.tsx`.
4. Keep sub-period labels aligned with `packages/core` and `CORE_SPEC.md`.
