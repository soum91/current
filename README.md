# Current

A small iPhone network monitor with a Dynamic Island Live Activity. Built with SwiftUI, ActivityKit and the network interface counters already exposed by iOS. No jailbreak, VPN, tracking server or active speed test.

Designed for iPhone 17 on iOS 27, with iOS 18 as the minimum deployment target.

## What it does

- **Upload and download speeds** from kernel-maintained Wi-Fi (`en*`) and cellular (`pdp_ip*`) interface byte counters. Set sampling to 0.25, 0.5, 1 or 2 seconds (0.5 seconds by default).
- **Live Activity** in the Dynamic Island and on the Lock Screen, with compact and expanded upload/download readouts and a minimal download-speed bubble when iOS chooses the secondary presentation. Set Live Activity update attempts to 0.5, 1, 2 or 5 seconds (1 second by default).
- **Home Screen widgets** in small and medium sizes, showing the latest stored measurements. WidgetKit chooses when to refresh them.
- **Experimental background monitoring** via an optional low-accuracy location session. The session is never enabled without the user's choice, and Current never stores or uploads location coordinates.
- **One-minute chart** of observed transfer rates and data transferred during the current foreground monitoring session.
- **Connection type** from the active Network framework path rather than treating every present Wi-Fi and cellular interface as currently carrying traffic.
- **Bytes or bits** display settings. No user account or network permissions required.
- **Privacy-first**: all calculations happen on the phone; the app makes no network requests of its own.

## The iOS background limit

Current is intentionally honest about the operating system's restrictions:

1. The measurement is live while Current is in the foreground.
2. The app attempts Live Activity updates at the chosen interval while it can execute. iOS may coalesce or throttle those updates; the chosen interval is not a guaranteed screen refresh rate.
3. Experimental mode uses Core Location's standard, low-accuracy background updates (`UIBackgroundModes=location`, `allowsBackgroundLocationUpdates=true`) to *attempt* continued execution while other apps are open. It requires When In Use location permission, shows the system location indicator and may consume extra battery. It may not keep running forever; iOS remains in control.
4. Once iOS suspends the app, it cannot sample traffic. The Live Activity marks the values **Paused** or replaces them with `--` when its last update is stale.
5. A Home Screen widget is a last-sample display, not a keep-alive mechanism. It is refreshed on WidgetKit's schedule, not per second.
6. This version does **not** guarantee 24/7 system-wide throughput monitoring. A VPN packet tunnel would also change the device's network path and is not silently enabled here.

When another app also starts a Live Activity, iOS may render Current as the smaller, detached minimal bubble. Apps cannot force the secondary position, and a second fake activity is not started to manipulate this layout.
The small Island view uses a four-character download-rate abbreviation to fit inside Apple's most restrictive minimal presentation. Open the expanded view to see both upload and download rates.

The background location option is experimental and intended for private sideload testing. Apple's App Store rules permit background services only for their intended purposes, so using location solely for network monitoring is not appropriate for App Store distribution.

Interface totals are device-wide and include other apps' network traffic, but exclude tunnel and loopback interfaces to avoid common double-counting. VPN traffic, Wi-Fi Assist, tethering and some devices' interface naming can affect totals. The counters are not a substitute for carrier billing records.

## AltStore / FlareStore source

Add this URL as a source in FlareStore, AltStore Classic or SideStore:

```text
https://raw.githubusercontent.com/soum91/current/main/source.json
```

This source lists the real Current IPA from GitHub Releases, including its matching bundle ID, version and download size. The build workflow updates `source.json` after every successful release so the newest build appears first. The source is for classic IPA sideloading, not AltStore PAL marketplace notarization.

## Setup

1. Add the source URL above in FlareStore, AltStore Classic or SideStore, then choose **Current**. Alternatively download the latest `.ipa` from [Releases](https://github.com/soum91/current/releases).
2. Install it with a sideloading tool that supports app extensions. Keep `CurrentWidget.appex` in the package.
3. Open Current, allow Live Activities if iOS asks, and tap **Show in Dynamic Island**.
4. Optionally enable **Experimental background monitoring** in Settings, approve When In Use location permission and test switching to other apps. Without it, Current stops sampling in the background.
5. To add a Home Screen widget, long-press your Home Screen, choose Add Widget, search for Current and select the small or medium layout.

The widget shares data through App Group `group.com.soum91.current`. Both `Current.app` and `CurrentWidget.appex` must be signed with compatible App Group entitlements. Some free sideloading profiles or signing tools remove unsupported entitlements; in that case the widget may show **Open app** instead of the latest speed.

The source is provided for personal use and testing. The IPA published by GitHub Actions is ad-hoc signed and will need signing compatible with your install method.

## Build

Every push to `main` builds `Current-<version>-build-<N>.ipa` on GitHub Actions and publishes it as `build-N` in Releases. The app and its ActivityKit widget extension are included.

After a successful release, the workflow updates the app version, download URL and file size in `source.json` and commits the refreshed source back to `main`.

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
| `Current/Model/SpeedStore.swift` | Configurable polling and Live Activity update intervals, one-minute chart history and ActivityKit lifecycle |
| `Shared/SpeedActivityAttributes.swift` | Shared, codable speed values and formatting |
| `CurrentWidget/CurrentWidget.swift` | Lock Screen, compact/expanded/minimal Dynamic Island layouts |
| `CurrentWidget/CurrentSpeedWidget.swift` | Home Screen widgets with last-sample display and stale-state handling |
| `Shared/WidgetSpeedSnapshot.swift` | Optional App Group sharing between Current and the widget extension |
| `Current/Model/BackgroundLocationController.swift` | Opt-in, coarse Core Location session for experimental background execution |
| `Current/Views` | Dark glass-like SwiftUI dashboard and settings |

## Platform notes

- Uses public Apple APIs (`getifaddrs`, ActivityKit, WidgetKit and Swift Charts).
- No private frameworks or jailbreak injection.
- The optional location background mode does not guarantee continuous execution. Live Activities themselves do not grant arbitrary background execution time.

Independent project. Not affiliated with Apple.

## Artwork

The Current icon is original artwork made specifically for this project. It depicts two contrasting flows for upload and download, using the same dark, atmospheric color direction as the app interface. No third-party icon or stock artwork is used.
