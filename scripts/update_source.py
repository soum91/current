"""Publish Current's newly built IPA in the AltStore-compatible source."""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("Usage: update_source.py IPA_PATH BASE_VERSION BUILD_NUMBER")

    ipa = Path(sys.argv[1])
    base_version = sys.argv[2]
    build_number = sys.argv[3]
    if not ipa.is_file() or not build_number.isdecimal():
        raise SystemExit("IPA must exist and build number must be numeric")

    source_path = Path(__file__).resolve().parent.parent / "source.json"
    source = json.loads(source_path.read_text(encoding="utf-8"))
    app = next(item for item in source["apps"] if item["bundleIdentifier"] == "com.soum91.current")

    new_version = {
        "version": base_version,
        "buildVersion": build_number,
        "date": datetime.now(timezone.utc).date().isoformat(),
        "localizedDescription": "Automated build of Current for iPhone.",
        "downloadURL": (
            "https://github.com/soum91/current/releases/download/"
            f"build-{build_number}/{ipa.name}"
        ),
        "size": ipa.stat().st_size,
        "minOSVersion": "18.0",
    }
    app["versions"] = [
        new_version,
        *[
            v
            for v in app["versions"]
            if v["buildVersion"] != build_number
            and len(v["version"].split(".")) == 3
        ],
    ]
    source_path.write_text(json.dumps(source, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
