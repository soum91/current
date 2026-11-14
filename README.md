# Current

A small iPhone network monitor with a Dynamic Island Live Activity. Built with SwiftUI, ActivityKit and the network interface counters already exposed by iOS. No jailbreak, VPN, tracking server or active speed test.

Designed for iPhone 17 on iOS 27, with iOS 18 as the minimum deployment target.

## What it does

- **Upload and download speeds** from kernel-maintained Wi-Fi (`en*`) and cellular (`pdp_ip*`) interface byte counters. Set sampling to 0.25, 0.5, 1 or 2 seconds (0.5 seconds by default).
- **Live Activity** in the Dynamic Island and on the Lock Screen, with compact and expanded upload/download readouts and the original compact arrows in the secondary minimal bubble. Set Live Activity update attempts to 0.5, 1, 2 or 5 seconds (1 second by default).
- **Home Screen widgets** in small and medium sizes, showing the latest stored measurements. WidgetKit chooses when to refresh them.
- **One-minute chart** of observed transfer rates and data transferred during the current monitoring session.
- **Connection type** from the active Network framework path rather than treating every present Wi-Fi and cellular interface as currently carrying traffic.
- **Bytes or bits** display settings. No user account or network permissions required.
- **Optional experimental background mode** requiring Location: Always to request additional background execution time. Location coordinates are never read, saved or transmitted by Current. Balanced background updates are on by default: network sampling is throttled to every 5 seconds and Island updates to 15 seconds in the background, while foreground speed stays unchanged.
- **Privacy-first**: all speed calculations happen on the phone; the app makes no network requests of its own.

## The iOS background limit

Current is intentionally honest about the operating system's restrictions:

1. The measurement is live while Current is in the foreground.
2. The app attempts Live Activity updates at the chosen interval while it can execute. iOS may coalesce or throttle those updates; the chosen interval is not a guaranteed screen refresh rate.
3. By default, sampling pauses when Current enters the background. The Live Activity keeps its last measured speed visible in gray and marks it as **Paused** when stale.
4. In Settings, you may opt into experimental background monitoring. This uses coarse Core Location updates, `UIBackgroundModes=location` and **Always** authorization. `showsBackgroundLocationIndicator` is disabled for this Always-authorized session, but iOS may still show other privacy indicators.
5. The location session may keep Current running while backgrounded, but iOS can suspend or terminate the app anyway. Using location services can increase battery consumption. Current never uses the coordinates for speed measurement.
6. A Home Screen widget is a last-sample display, not a keep-alive mechanism. It is refreshed on WidgetKit's schedule, not per second.
7. This version does **not** guarantee 24/7 system-wide throughput monitoring. A VPN packet tunnel would also change the device's network path and is not silently enabled here.

When another app also starts a Live Activity, iOS may render Current as the smaller, detached minimal bubble. Apps cannot force the secondary position, and a second fake activity is not started to manipulate this layout.
The restored minimal Island view uses the small transfer-arrows icon from build 3. Open the expanded view to see both upload and download rates.

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
4. Choose your preferred sampling and Island update request intervals in Settings. Background sampling is off by default. To try keeping it active, enable experimental background monitoring and grant **Always** location access in iOS Settings when prompted.
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
| `Current/Model/BackgroundLocationController.swift` | Optional, coarse, Always-authorized background location session (coordinates discarded) |
| `Shared/SpeedActivityAttributes.swift` | Shared, codable speed values and formatting |
| `CurrentWidget/CurrentWidget.swift` | Lock Screen, compact/expanded/minimal Dynamic Island layouts |
| `CurrentWidget/CurrentSpeedWidget.swift` | Home Screen widgets with last-sample display and stale-state handling |
| `Shared/WidgetSpeedSnapshot.swift` | Optional App Group sharing between Current and the widget extension |
| `Current/Views` | Dark glass-like SwiftUI dashboard and settings |

## Platform notes

- Uses public Apple APIs (`getifaddrs`, ActivityKit, WidgetKit and Swift Charts).
- No private frameworks or jailbreak injection.
- Live Activities themselves do not grant arbitrary background execution time. Location permission is requested only if the user opts into experimental background monitoring.

Independent project. Not affiliated with Apple.

## Artwork

The Current icon is original artwork made specifically for this project. It depicts two contrasting flows for upload and download, using the same dark, atmospheric color direction as the app interface. No third-party icon or stock artwork is used.


## Optional companion: Current Anchor (experimental)

This repository also builds a **separate app** with its own bundle ID,
`com.soum91.current.anchor`, and a separate Live Activity widget extension.
It is published as a second IPA in the same GitHub Release and as **Current Anchor**
in the existing FlareStore feed. It uses Current's existing app icon for the prototype.

1. Install **both** Current and Current Anchor, preserving both widget extensions.
2. Open Current Anchor and tap **Start Anchor**. This creates a neutral-dot placeholder
   Live Activity; no fake network speeds are generated.
3. Tap **Open Current**, then start or restart Current's speed Live Activity.
4. Switch apps and observe the Dynamic Island. With activities from two different
   app bundle IDs, iOS *may* use its two-activity presentation.
5. To stop the test, open Current Anchor and tap **Stop Anchor**.

The Anchor does not need location permission, sample the network, or periodically
update itself. Apple controls which Live Activities are visible and their order,
so this is **not** a guaranteed way to force Current into the detached bubble.
iOS can automatically expire Live Activities after eight hours. A completely
transparent or invisible system-owned Dynamic Island is not supported.

The normal Current app's networking, always-location option and the proven
secondary numeric readout are unchanged by this experiment.

### Anchor marker appearance

The standalone Anchor app now offers **Black** (default), **Clear**, and **Gray** marker styles. Black blends into the system-owned black pill; Clear renders a fully transparent marker inside an unchanged 5–6 pt view. Both preserve the activity's layout footprint and cannot remove or resize the system Dynamic Island. You can change the marker while Anchor is already running without restarting Current. Gray is the original visible-dot fallback. The Current network-monitor target is unchanged.

## Experimental zero-footprint Anchor and traffic-triggered Current

- **Current Anchor** has a fourth marker style, **Zero**, which requests an `EmptyView` for both compact-leading and minimal Island presentations. The system may reserve the same black hardware pill or not display the empty activity. Black is retained as the safe default.
- Both apps offer optional **Quiet Lock Screen** rendering. This makes the activity's Lock Screen content almost empty and requests a clear background. iOS may still render a blank system card: there is no supported Dynamic-Island-only Live Activity flag.
- **Current** has an opt-in on-demand Live Activity mode. It samples total download + upload traffic in bytes/s. Configurable trigger thresholds are 1, 10, 50, 100 or 500 KB/s; configurable idle delays are 5, 15, 30 or 60 seconds. A sustained 1-second rise starts the activity while the app is foregrounded; sustained idle traffic ends it immediately.
- Background auto-restart is not guaranteed: ActivityKit normally requires the foreground app (or a system-invoked LiveActivityIntent) to create a Live Activity. Traffic measurements and the optional location session do not override that requirement. Leave on-demand mode disabled for original always-on behavior.
