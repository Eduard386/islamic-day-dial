# Islamic Day Dial — Apple Platforms

This Xcode project now ships four Apple surfaces in one product:

- `IslamicDayDial` — the main iPhone app with the full dial, location presets, status cards, and prayer times
- `IslamicDayDialWatch` — the watchOS companion app
- `IslamicDayDialWidget` — an iPhone Home Screen widget
- `IslamicDayDialWatchWidget` — a watchOS WidgetKit extension for complications and Smart Stack widgets

The web dashboard in `apps/web-dashboard` remains the visual source of truth.

Important product note:

- this is not a custom watch face
- users install one app bundle, then manually add the complication/widget to an Apple Watch face or to Smart Stack

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

### Visit analytics (Supabase)

The iPhone and watch apps POST to `visits` on launch (after geo resolves). Values come from **Info.plist** keys `SupabaseURL` / `SupabaseAnonKey`, which are filled from build settings `SUPABASE_URL` / `SUPABASE_ANON_KEY`.

1. Copy `IslamicDayDial/Config.xcconfig.example` → `IslamicDayDial/Config.xcconfig` (the real file is gitignored).
2. Put your project URL and anon key in **double quotes**. In `.xcconfig` files, `//` starts a comment, so an unquoted `https://…` is truncated to `https:` and **no rows appear in Supabase** with no obvious error in the UI.
3. `project.yml` attaches `Config.xcconfig` to the **iOS app** and **watch app** targets; after changing secrets, **Clean Build Folder** and run again.
4. In **Debug**, open the **Console** app (or Xcode console) and filter for `com.islamicdaydial.analytics` — `VisitTracker` logs skips (missing config) and non-2xx HTTP responses.

### Watch install fails: free Apple Developer account (MIInstallerErrorDomain 111)

If **Console.app** / **appconduitd** shows (often after a full payload transfer):

```text
MIInstallerErrorDomain Code=111
The bundle being installed with bundle ID com.islamicdaydial.ios.watch is authorized by a free provisioning profile,
but apps validated by those are not allowed to be installed from this source.
```

then **Apple is blocking** installation of the watchOS app onto a **physical** Apple Watch when it is signed with a **free (Personal Team)** provisioning profile. The iPhone app may install and run; the **watch companion will always fail** at “install done” on the watch. This is **not** a bug in this repository — it is an **account / signing** limitation.

**What to do:**

1. Enroll in the **Apple Developer Program** (paid membership).
2. In Xcode **Signing & Capabilities** for **both** `IslamicDayDial` and `IslamicDayDialWatch` (and the watch widget extension if signing issues appear), select the **paid team** (not “Personal Team”).
3. **Xcode → Settings → Accounts** → your Apple ID → **Download Manual Profiles** (or let automatic signing refresh).
4. **Product → Clean Build Folder**, then **Run** the iOS app on the device again so the watch app is re-embedded and reinstalled.

Until then, you can still develop the **iOS** app and run **watchOS Simulator** builds if needed; physical-watch install from Xcode requires a profile Apple accepts for that install path.

### Xcode: Apple Watch “tunnel” / disconnected

If **Devices and Simulators** shows the watch under **Disconnected** with *“Timed out while attempting to establish tunnel using negotiated network parameters”*, Xcode cannot talk to the watch — **watch app install/run will fail or hang** even when the iPhone app works.

- Connect the **iPhone with a USB cable**, unlock it, keep the watch on wrist and awake.
- Toggle **Wi‑Fi** and **Bluetooth** on iPhone and Watch; restart both devices; restart Xcode.
- Ensure **Developer Mode** is on for iPhone and Watch.
- If it persists: disconnect other devices, try another USB port/cable, or temporarily **forget this Mac** on the iPhone and reconnect (re-trust).

### Watch app size and install time (real device)

From a typical **appconduitd** log while Xcode / Bridge pushes the companion:

- **Transfer size:** on the order of **3–4 MB compressed** over the phone ↔ watch link (example: ~3.7 MB in ~85 s at ~40 KiB/s). The **installed size on the Watch** is larger (uncompressed binary, embedded widget extension, assets). Check **Watch → Settings → General → Storage** for the real number.
- **Duration:** often **tens of seconds to a few minutes**, strongly dependent on **Bluetooth/Wi‑Fi**, radio congestion, watch model, and whether the phone is busy. It is **not** a fixed “bug” if one run is much slower.
- **Dropped link:** yes, the transport can stall or retry; keep **iPhone and Watch unlocked/awake**, **USB** to the phone for Xcode deploy, and follow the tunnel tips above. System-side detail appears under process **appconduitd** (transfer progress, install start).

**Debug logs in this repo (search Xcode console for `IDD_WATCH`, subsystem `com.islamicdaydial.watchlink`, Debug builds only):**

- **iPhone:** `WatchInstallDiagnostics` activates `WCSession`, logs **every ~12s** (heartbeat + snapshot on change), **foreground/background** (`didBecomeActive` / `willResignActive`), `reachabilityDidChange`, and `sessionWatchStateDidChange`. Each line includes `paired`, `watchAppInstalled`, `reachable`, `hasContentPending`, and counts of outstanding WC transfers.
- **watchOS:** logs when the watch **process starts** and when **`scenePhase`** changes (only after the watch app is actually running — not during the system install spinner).

**If the Watch shows an install spinner forever *and* Xcode periodically shows the watch as Disconnected:** that is almost always **Core Device tunnel + Bluetooth** dropping, not Swift code in this repo. The iPhone app may still show `watchAppInstalled=false` for a long time while **appconduitd** retries. Mitigations: **USB** to the iPhone, keep **phone unlocked** and app in **foreground** during deploy, **restart** iPhone + Watch + Mac, **pairing** stable in **Watch** app on iPhone, try another **cable/port**, beta **iOS/watchOS** is flakier.

**System logs during payload/install (not from your app binary):** open **Console.app** on the Mac, select the **iPhone**, filter process **`appconduitd`** (bytes transferred / install start / errors) and **`Bridge`** if needed.

Your app code does **not** run during the actual install payload transfer; correlate **IDD_WATCH** lines (phone) with **appconduitd** (system) timestamps.

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

### `IslamicDayDialWatchWidget`

The watch WidgetKit extension. It reuses the shared Swift core and ring renderer for:

- `.accessoryCircular`
- `.accessoryRectangular`
- `.accessoryInline`

Use this target for Apple Watch complications and Smart Stack widgets. It is embedded in the watch app, not the iPhone app.

### Prayer notifications (iOS)

`PrayerNotificationScheduler` schedules local notifications for Fajr, Dhuhr, Asr, Maghrib, Isha. Title: Hijri date (day month year). Body: prayer name + Quran 4:103. Rescheduled on app launch and when returning from background (handles travel).

Apple Watch complications/widgets do not replace prayer notifications. Phase 1 keeps notification scheduling on iPhone and relies on normal iPhone-to-Watch mirroring behavior when system settings allow it.

### `IslamicDayDialWidget`

The iPhone widget extension. It uses the same snapshot and ring logic to show the current phase, countdown, and mini dial from the Home Screen.

## Shared Swift logic

The following Swift files are compiled into multiple targets through `project.yml`:

- `IslamicDayDialWatch/IslamicDayCore/` — Swift port of `packages/core`
- `IslamicDayDialWatch/RingView.swift`
- `IslamicDayDialWatch/Geometry.swift`
- `IslamicDayDialWatch/Colors.swift`

This keeps the ring math and display behavior aligned across iPhone, iPhone widget, watch app, and watch complication/widget surfaces without duplicating algorithms.

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

#### Troubleshooting: Watch app icon appears but install spins / “could not be installed” / tap does nothing

This usually means a **partial companion install**: the iPhone `Watch` app started pushing the embedded `Watch/IslamicDayDialWatch.app` to the watch, but the transfer or verification did not finish. Tapping the grid icon then shows **“Unable to install” / «Не удается установить приложение»** because the payload is incomplete. **Stopping install in the iPhone Watch app removes that placeholder** — that is expected.

If **Xcode → Devices and Simulators → your watch → Installed Apps** shows **“No apps installed”**, the watch never received a **complete** developer install; fixing connectivity and reinstalling usually resolves it.

**Do this in order:**

1. **iPhone connected to the Mac with a USB cable** (not only Wi‑Fi). Companion install is much more reliable when Xcode sideloads over USB; the watch can still show a “network” icon next to the Mac — that is normal if the watch talks to the phone over Bluetooth/Wi‑Fi.
2. Use the **same iPhone** that is paired with the watch as the run destination (avoid mixing a second “iPhone (2)” for install).
3. **Developer Mode** enabled on **iPhone and Apple Watch** (Settings → Privacy & Security → Developer Mode), both restarted after enabling if you just turned it on.
4. Delete `Islamic Day Dial` from **iPhone**, from **Watch grid** (long-press → remove), and in **Watch app → My Watch → Islamic Day Dial** if it appears; in Xcode **Devices → watch → Installed Apps**, remove the app if listed.
5. **Product → Clean Build Folder**, then `xcodegen generate` if you changed `project.yml`.
6. Run scheme **`IslamicDayDial`** onto the physical **iPhone** (builds the embedded watch app). After the iOS app is on the phone, open the iPhone **Watch** app and wait for the watch app install to finish (keep phone and watch unlocked and close together).
7. **Prefer installing the watch app from Xcode once**: scheme **`IslamicDayDialWatch`**, destination **your Apple Watch** (it appears when the paired iPhone is the host and the watch is reachable). If the watch is missing from the run menu, enable **Product → Destination → Show All Destinations** and pick the watch under the iPhone.
8. If it still fails, collect logs using **“Which logs to copy”** below.

The iOS host target sets **`EMBEDDED_CONTENT_CONTAINS_SWIFT`** and **`ENABLE_DEBUG_DYLIB: NO`** to reduce flaky debug companion installs; bump **`CURRENT_PROJECT_VERSION`** for **all** targets together when you need to force a full re-sync after a bad state.

##### Which logs to copy (Watch install / “could not be installed”)

**Important:** The macOS **Console** app defaults to showing your **Mac**. Logs full of `TrustEvaluationAgent`, `mdworker`, `Xcode` on **MacBook** are usually **not** the reason the watch app failed — you need the **iPhone** (and if possible **Apple Watch**) stream.

**A. Live stream from the iPhone (best first step)**

1. Open **Console** (macOS `/Applications/Utilities/Console.app`).
2. In the left sidebar under **Devices**, click **iPhone Step** (your phone) — **not** “Eduard’s Mac…”.
3. Click **Start** / ensure streaming is on.
4. In the search bar, try one filter at a time: `installd`, `MobileInstallation`, `Watch`, `appconduit`, `SpringBoard`, `pkd`, `verification`, `signature`.
5. On the **iPhone**: open the **Watch** app and start installing **Islamic Day Dial** (or tap the icon on the watch). Wait until the error appears.
6. Select the relevant lines (roughly **30–80 lines** around the time of the failure), copy, paste into a text file or message.

**B. Xcode Devices window**

1. **Window → Devices and Simulators**.
2. Select **iPhone Step** → **Open Console** (streams the phone; same idea as A).
3. If the watch shows as connected (not disconnected), select **Apple Watch — Ira** → **Open Console**, repeat the install, filter as above.

**C. “Open Recent Logs” vs live console**

- **Open Recent Logs** opens a **file picker** of **exported** `.log`/crash-style dumps. If **Other Logs** is empty, nothing was exported for that day — use **Open Console** instead for a **live** stream.

**D. Crash / diagnostic reports**

1. In **Console**, with **iPhone** selected, check **Crash Reports** or **Diagnostic Reports** for anything named like `IslamicDayDial`, `installd`, `SpringBoard` around the failure time.
2. On the **iPhone**: **Settings → Privacy & Security → Analytics & Improvements → Analytics Data** — look for entries containing your app or `Watch` / `installd`; open one and use Share to AirDrop/copy relevant text.

**E. Mac `TrustEvaluationAgent` / “Operation not permitted”**

If Xcode’s deploy or signing seems broken on the Mac, grant **Full Disk Access** to **Xcode** (and optionally **Terminal**) in **System Settings → Privacy & Security → Full Disk Access**, then restart Xcode. Those messages can appear on **beta** macOS/iOS builds even when the real failure is elsewhere — still collect **iPhone** logs first.

**F. iOS and watchOS versions**

The **iPhone** and **paired Apple Watch** should be on **compatible** OS generations (same major release track, e.g. both current stable or both same beta). A very new **iPhone** OS with an old **watchOS** (or the opposite) often causes **companion install** failures that show only as generic errors on the watch.

### Watch complication / Smart Stack widget

- Run the `IslamicDayDialWatch` scheme once so the watch app bundle installs
- On Apple Watch, edit the current watch face or open Smart Stack widget editing
- Add `Islamic Day Dial`

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

Tests cover: duha sector start (4° solar altitude), countdown, glow windows, prayer notification content format, geometry, geo resolution, and widget presentation / refresh helpers.

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
