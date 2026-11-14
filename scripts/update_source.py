"""Publish Current and optional Current Anchor IPA builds in the FlareStore feed."""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE = "https://github.com/soum91/current/releases/download"


def publish(app, ipa, version, build, description):
    record = {
        "version": f"{version}.{build}",
        "buildVersion": build,
        "date": datetime.now(timezone.utc).date().isoformat(),
        "localizedDescription": description,
        "downloadURL": f"{BASE}/build-{build}/{ipa.name}",
        "size": ipa.stat().st_size,
        "minOSVersion": "18.0",
    }
    app["versions"] = [record, *[
        old for old in app.get("versions", [])
        if old.get("buildVersion") != build
    ]][:25]
    app["version"] = record["version"]
    app["versionDate"] = record["date"]
    app["versionDescription"] = record["localizedDescription"]
    app["downloadURL"] = record["downloadURL"]
    app["size"] = record["size"]


def main():
    if len(sys.argv) not in (4, 5):
        raise SystemExit("Usage: update_source.py CURRENT_IPA BASE_VERSION BUILD_NUMBER [ANCHOR_IPA]")
    current_path = Path(sys.argv[1])
    base_version, build = sys.argv[2:4]
    anchor_path = Path(sys.argv[4]) if len(sys.argv) == 5 else None
    if not build.isdecimal() or not current_path.is_file() or (anchor_path and not anchor_path.is_file()):
        raise SystemExit("IPA(s) must exist and build number must be numeric")

    source_path = Path(__file__).resolve().parent.parent / "source.json"
    source = json.loads(source_path.read_text(encoding="utf-8"))
    current = next(a for a in source["apps"] if a["bundleIdentifier"] == "com.soum91.current")
    publish(current, current_path, base_version, build,
            "Current network monitor IPA. This build also ships a separate, optional Anchor experiment.")
    current["localizedDescription"] = (
        "Current measures Wi-Fi/cellular traffic with configurable sampling and a Dynamic Island "
        "Live Activity. Optional Always-location background monitoring is experimental. "
        "A separate Current Anchor companion can be installed to test detached-Island behavior. "
        "Requires iOS 18 or later."
    )

    if anchor_path:
        bundle = "com.soum91.current.anchor"
        anchor = next((a for a in source["apps"] if a["bundleIdentifier"] == bundle), None)
        if anchor is None:
            anchor = {
                "name": "Current Anchor",
                "bundleIdentifier": bundle,
                "developerName": "soum91",
                "subtitle": "Optional Dynamic Island placement experiment",
                "localizedDescription": (
                    "A separate companion app that starts and stops a minimal placeholder Live Activity. "
                    "It may cause iOS to show Current in the detached bubble, but placement is not guaranteed. "
                    "No location tracking, network traffic or background processing. Start and stop manually."
                ),
                "iconURL": (
                    "https://raw.githubusercontent.com/soum91/current/main/"
                    "Current/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
                ),
                "tintColor": "#61E8C7",
                "category": "utilities",
                "versions": [],
            }
            source["apps"].append(anchor)
        publish(anchor, anchor_path, base_version, build,
                "Initial Current Anchor experiment: manual placeholder Live Activity and stop control.")
        if bundle not in source.setdefault("featuredApps", []):
            source["featuredApps"].append(bundle)

    source_path.write_text(json.dumps(source, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
