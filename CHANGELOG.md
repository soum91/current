# Changelog

## [build-25] - 2026-11-14

## Verified changes since build-23

- Fix initialization order in Current traffic-triggered Live Activity ([`fd3b4207`](https://github.com/soum91/current/commit/fd3b42078fd8818a863582b0432408b84032b9ae); `Current/Model/SpeedStore.swift`)
- Keep Current Live Activity armed during idle to restore speeds without background restart ([`6867b0c8`](https://github.com/soum91/current/commit/6867b0c83c6740726e6fc2481e36b26fb4eac4ec); `.github/workflows/build.yml`, `Current/Model/SpeedStore.swift`, `Current/Views/SettingsView.swift`, and 3 more)

[Inspect exact code changes](https://github.com/soum91/current/compare/build-23...build-25)

## [build-23] - 2026-11-14

## Verified changes since build-22

- Add zero-size Anchor trial, quiet Lock Screen options, and traffic-triggered Current Island ([`1bddbc34`](https://github.com/soum91/current/commit/1bddbc34f03d8730e444789485c9c372bf9590e7); `.github/workflows/build.yml`, `AnchorApp/AnchorApp.swift`, `AnchorShared/AnchorAttributes.swift`, and 6 more)

[Inspect exact code changes](https://github.com/soum91/current/compare/build-22...build-23)

## [build-22] - 2026-11-14

## Verified changes since build-21

- Let Current Anchor marker be black, clear or gray ([`fb9cd9ce`](https://github.com/soum91/current/commit/fb9cd9ceea81a29fbb57d42e99eb7dea451becc2); `AnchorApp/AnchorApp.swift`, `AnchorShared/AnchorAttributes.swift`, `AnchorWidget/AnchorWidget.swift`, and 1 more)

[Inspect exact code changes](https://github.com/soum91/current/compare/build-21...build-22)

## [build-21] - 2026-11-14

## Verified changes since build-20

- Add opt-in Current Anchor companion and separate IPA release ([`afdd435a`](https://github.com/soum91/current/commit/afdd435a7560dabea2cf68da1035753a545102fe); `.github/workflows/build.yml`, `AnchorApp/AnchorApp.swift`, `AnchorShared/AnchorAttributes.swift`, and 5 more)

[Inspect exact code changes](https://github.com/soum91/current/compare/build-20...build-21)

This log records verified, release-specific changes. The [Factual release changelog](.github/workflows/release-changelog.yml) GitHub Action adds entries based on the actual commits between published releases. Entries are not fabricated for older versions that have not been audited.

