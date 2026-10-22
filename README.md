# Current

A small iPhone network monitor with a Dynamic Island Live Activity. Built with SwiftUI, ActivityKit and the network interface counters already exposed by iOS. No jailbreak, VPN, tracking server or active speed test.

Designed for iPhone 17 on iOS 27, with iOS 18 as the minimum deployment target.

## What it does

- **Upload and download speeds** from kernel-maintained Wi-Fi (`en*`) and cellular (`pdp_ip*`) interface byte counters, sampled every second while the app is running.
- **Live Activity** in the Dynamic Island and on the Lock Screen, with compact and expanded upload/download readouts.
- **One-minute chart** of observed transfer rates and data transferred during the current foreground monitoring session.
- **Bytes or bits** display settings. No user account or network permissions required.
- **Privacy-first**: all calculations happen on the phone; the app makes no network requests of its own.

## The iOS background limit

Current is intentionally honest about the operating system's restrictions:

1. The measurement is live while Current is in the foreground.
2. The app attempts a Live Activity update every five seconds while it can execute. iOS may coalesce or throttle those updates.
3. Once iOS suspends the app, it cannot keep sampling the device's traffic every second. The Live Activity marks the values **Paused** or replaces them with `--` when its last update is stale.
4. This version does **not** claim 24/7 live monitoring across other apps. Achieving ongoing background monitoring would require a separate legitimately entitled background execution mechanism. A VPN packet tunnel would also change the device's network path and is not silently enabled here.

Interface totals are device-wide and include other apps' network traffic, but exclude tunnel and loopback interfaces to avoid common double-counting. VPN traffic, Wi-Fi Assist, tethering and some devices' interface naming can affect totals. The counters are not a substitute for carrier billing records.

## Setup

1. Download the latest `.ipa` from [Releases](https://github.com/soum91/current/releases).
2. Install it on your non-jailbroken iPhone through a sideloading tool that supports app extensions (AltStore, SideStore, Sideloadly or FlareStore). Keep `CurrentWidget.appex` in the package.
3. Open Current, allow Live Activities if iOS asks, and tap **Show in Dynamic Island**.
4. Switch to other apps to see the Live Activity's last available reading, which will be labeled paused once updates stop.

The source is provided for personal use and testing. The IPA published by GitHub Actions is ad-hoc signed and will need signing compatible with your install method.

## Build

Every push to `main` builds `Current-<version>-build-<N>.ipa` on GitHub Actions and publishes it as `build-N` in Releases. The app and its ActivityKit widget extension are included.

For a local Mac build:

```sh
brew install xcodegen
xcodegen generate
open Current.xcodeproj
```

In Xcode, use your own signing team for the app and widget target. Both targets must have unique bundle IDs and the widget extension must remain embedded.

## Implementation

| Component | Purpose |
| --- | --- |
| `Current/Model/InterfaceSampler.swift` | Read `getifaddrs` kernel interface counters and compute safe byte deltas |
| `Current/Model/SpeedStore.swift` | One-second polling, chart history and ActivityKit lifecycle |
| `Shared/SpeedActivityAttributes.swift` | Shared, codable speed values and formatting |
| `CurrentWidget/CurrentWidget.swift` | Lock Screen, compact/expanded/minimal Dynamic Island layouts |
| `Current/Views` | Dark glass-like SwiftUI dashboard and settings |

## Platform notes

- Uses public Apple APIs (`getifaddrs`, ActivityKit, WidgetKit and Swift Charts).
- No private frameworks or jailbreak injection.
- No dedicated background capability is requested. Live Activities themselves do not grant arbitrary background execution time.

Independent project. Not affiliated with Apple.

## Artwork

The Current icon is original artwork made specifically for this project. It depicts two contrasting flows for upload and download, using the same dark, atmospheric color direction as the app interface. No third-party icon or stock artwork is used.
