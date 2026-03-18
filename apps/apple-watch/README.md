# Islamic Day Dial — Apple Watch

## Setup

1. **Xcode**: Install Xcode from the App Store. Ensure iOS and watchOS platforms are installed (Xcode → Settings → Platforms).

2. **Open project**:
   ```bash
   cd apps/apple-watch
   open IslamicDayDial.xcodeproj
   ```

3. **Run on device**:
   - Connect iPhone via USB
   - iPhone and Apple Watch must be paired
   - Mac and iPhone on same Wi‑Fi
   - In Xcode: Product → Destination → select your iPhone (watch appears as sub-option for IslamicDayDialWatch)
   - Product → Run (choose IslamicDayDialWatch scheme for the watch)

## Structure

- **IslamicDayDial** — iOS companion app (minimal)
- **IslamicDayDialWatch** — watchOS app with ring UI
- **IslamicDayCore/** — Swift port of `packages/core` (snapshot, prayer times, Hijri, phases, ring)

## Build from command line

```bash
# iOS Simulator
xcodebuild -scheme IslamicDayDial -destination 'platform=iOS Simulator,name=iPhone 16' build

# watchOS Simulator  
xcodebuild -scheme IslamicDayDialWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
```

## Regenerate project (after editing project.yml)

```bash
brew install xcodegen  # if needed
xcodegen generate
```
