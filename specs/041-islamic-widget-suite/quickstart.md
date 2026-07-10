# Quickstart Validation: Islamic Home Screen Widget Suite (v1)

## Prerequisites

- Flutter SDK configured for this workspace and dependencies bootstrapped.
- Android API 24+ emulator or device with a launcher that supports resizable widgets.
- Arabic and English device locales available.
- Test location and prayer calculation settings configured in the app.
- Curated Ayah rotation fixture and three approved share-card backgrounds present.

## Automated Checks

From the workspace root:

```sh
melos run fix:format
melos run analyze
melos run bloc:lint
melos run test
```

Run native widget logic and Robolectric tests from `apps/tilawa/android`:

```sh
./gradlew testDevelopmentDebugUnitTest
```

Targeted tests must cover envelope parsing/version rejection, atomic last-valid fallback, prayer boundaries, deterministic no-repeat Ayah selection, Athkar period/reset/advance behavior, Hijri offsets and timezone rollover, share selection validation, cache cleanup, deep-link mapping, and privacy-safe analytics.

## End-to-End Scenarios

1. Install a development build and place every widget in compact and expanded sizes.
2. Verify Arabic/English labels, RTL/LTR order, light/dark/automatic appearance, accessible descriptions, non-color state indicators, and the launcher's supported large-text behavior.
3. Confirm each tap lands on the exact typed destination: prayer screen, Mushaf page/Ayah, Athkar set, or Hijri settings.
4. Cross prayer, Athkar, and local-midnight boundaries with a controlled clock. Confirm content advances once, persists, and never blanks.
5. Reboot, restart the launcher, force-stop the app, change timezone/DST, revoke location, and simulate stale/malformed/missing-artifact snapshots. Confirm current or explicitly stale/setup content appears within 10 seconds.
6. Place two instances of each widget with different themes/sizes. Confirm per-instance choices and Athkar progress do not interfere; confirm Hijri adjustment remains shared.
7. Disable network and repeat Ayah rotation, Athkar advance, Hijri rollover, and widget deep links.
8. Generate share cards for one and five consecutive Ayat on all three backgrounds. Verify QCF glyphs, ordering, attribution, share-sheet delivery, cancel behavior, and cleanup. Reject zero, six, and non-consecutive selections before render.

## QCF Visual-Fidelity Gate

- Render the entire curated daily-Ayah pool in every supported widget size/theme.
- Render representative one-to-five-Ayah share cards including long Ayat, multiple lines, Surah boundaries that are allowed by selection rules, diacritics, and verse markers.
- Compare against approved Mushaf references at native pixel scale.
- Fail release on missing/incorrect glyphs, tofu, clipped diacritics, wrong RTL order, illegible scaling, missing attribution, or checksum/artifact mismatch.

## Performance and Battery Gate

- Capture generation time, output dimensions/bytes, cache occupancy, provider render duration, and refresh reason on representative low/mid/high devices.
- Verify QCF generation does not run during hot reader scrolling or block a visible frame.
- Observe a 24-hour idle cycle under normal and battery-restricted modes. There must be no per-second wakeups and no sustained widget-attributed battery complaint pattern.
- Verify bounded cache eviction never removes the currently referenced artifact before its replacement is committed.

## Release Device Matrix

At minimum test one Xiaomi/Redmi device and one Samsung device, plus an API 24 emulator and target-API emulator. Exercise reboot, Doze, battery restriction, launcher resize, app upgrade, locale switch, timezone change, and process death.

## Expected Result

All four widget types remain useful offline and after host/process lifecycle events; QCF artifacts pass the visual corpus; share cards complete through the system share sheet; analytics contain only approved fields; and all automated checks pass without architectural or analyzer regressions.
