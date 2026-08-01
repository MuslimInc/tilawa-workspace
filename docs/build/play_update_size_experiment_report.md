# Report: Play update size ≈ install size — preliminary findings

**Date:** 2026-08-01  
**App:** MeMuslim / Tilawa (Android production AAB)  
**Device context:** Oppo A98 5G (user report); experiment is AAB-level only  
**Status:** Preliminary — **likely contributor**, not confirmed delivered patch size  
**Shorebird:** Out of scope (no longer used)

## Executive summary

Google Play showing an **update download size roughly equal to a fresh install (~35 MB)** is a **plausible outcome** for this Flutter AOT app when large native libraries change between releases. It is **not proven** here to be Oppo-specific, and it is **not** by itself evidence that App Bundles are misconfigured.

A local AAB comparison shows that the dominant payload under `base/lib/arm64-v8a/` is native libraries, and that **`libapp.so` (Dart AOT) differs between the two artifacts** (SHA-256 and byte content). That makes `libapp.so` a **strong suspect** for large Play updates. It does **not** measure the binary-delta size Play actually ships: Google’s patching can apply **bsdiff / archive-patcher** deltas *within* changed files, and uncompressed native libraries are intended to *help* those deltas. Until Play Console version comparison (or a measured patch) is available, treat “update ≈ install” as a **hypothesis**, not a confirmation.

## What this experiment measured (and did not)

| Measured | Not measured |
|----------|----------------|
| On-disk AAB size (~60.6 MB each) | Play Console “App size” / update size for a real version pair |
| Uncompressed `.so` sizes under `base/lib/arm64-v8a/` | Device-specific split APK set size (`bundletool get-size`) |
| SHA-256 equality of each `.so` | Binary-delta / bsdiff / archive-patcher patch byte size |
| Positional byte sampling on `libapp.so` (~91.5% differed) | Whether Play’s delta for that file is tiny, medium, or ~full |

**Tooling:** `tool/compare_aab_native_libs.sh` reports sizes, hashes, and SAME/CHANGED. It does **not** generate a patch. The ~91.5% positional sampling was an ad-hoc check outside that script; it shows content churn, **not** delta size. SHA mismatch only proves “not identical bytes.”

## Experiment method (limitations)

| Item | Detail |
|------|--------|
| Baseline AAB | `artifacts/android/production/app-production-release-2.2.2+95.aab` (2026-07-29, ~60.6 MB on disk) |
| Experiment AAB | Built locally 2026-08-01: `flutter build appbundle --release --flavor production --target-platform android-arm64 --obfuscate --build-number=99999` |
| Output | `artifacts/android/production/app-production-release-2.2.3-experiment+99999.aab` (~60.6 MB on disk) |
| Comparator | `tool/compare_aab_native_libs.sh` |

**Not a controlled, production-equivalent pair.** Relative to `pubspec.yaml` production build (`tilawa:build:android:production`), this run omitted at least:

- `--dart-define-from-file=env/production.json`
- `--split-debug-info=…`
- documented `flutter clean` / Gradle clean / `melos bootstrap` / `melos run gen`

Baseline vs experiment **Git SHAs**, Flutter **engine revision**, and lockfile parity were **not** recorded. **`libflutter.so` also CHANGED**, which is a warning that toolchain/engine/plugin parity was incomplete—so churn cannot be attributed solely to “one line of Dart.”

**Note:** The local experiment build temporarily removed the `integration_test` SDK dependency so release Java compilation could succeed on this machine. `pubspec.yaml` was restored after the build.

## Measured composition (baseline AAB)

Uncompressed sizes inside the **bundle** (path under `base/` — useful for orientation, **not** a device install-size measurement):

| Artifact | Size |
|----------|------|
| `base/lib/arm64-v8a/libapp.so` | **~19.5 MB** |
| `base/lib/arm64-v8a/libflutter.so` | **~11.6 MB** |
| All `base/lib/arm64-v8a/*.so` combined | **~32 MB** |
| `base/` zip entry total (approx.) | **~39.8 MB** |

Play generates **device-specific** base + configuration APKs (ABI, density, language). The Store “~35 MB” figure should be validated with:

1. **Play Console** → App size / version comparison (authoritative for update size), and/or  
2. **`bundletool get-size total`** with an Oppo-like device spec (install-size estimate).

Do not equate on-disk AAB size or raw `base/` zip weight with what a given device downloads.

## Comparison results (2.2.2+95 → experiment +99999)

| Library | Old | New | Result |
|---------|-----|-----|--------|
| `libapp.so` | 19.53 MB | 19.60 MB | **CHANGED** (SHA-256 differs) |
| `libflutter.so` | 11.58 MB | 11.58 MB | **CHANGED** |
| `libsentry.so` | 0.78 MB | 0.80 MB | **CHANGED** |
| `libsentry-android.so` | 0.02 MB | 0.02 MB | **CHANGED** |
| `libdartjni.so` | 0.12 MB | 0.12 MB | SAME |
| `libdatastore_shared_counter.so` | 0.01 MB | 0.01 MB | SAME |

Additional sampling on `libapp.so`: **~91.5%** of sampled *positions* differed. That indicates **high content churn**, not that a binary patch must be ~91.5% of the file. Google introduced **bsdiff** precisely so native libraries can patch efficiently even when many bytes differ in a naive positional sense ([Play download improvements, 2016](https://android-developers.googleblog.com/2016/07/improvements-for-smaller-app-downloads.html); [archive-patcher](https://github.com/google/archive-patcher)).

**Script verdict (revised wording):** `libapp.so` changed → it is a **likely major contributor** to update cost; **delivered** patch size is unknown until Play Console / patch tooling is used.

## Working hypothesis (not root-cause confirmation)

1. **Flutter release payload is mostly native code.** Dart AOT lands in `libapp.so`; with `libflutter.so` this dominates the arm64 lib set.
2. **App code releases usually rebuild `libapp.so`.** Production flags (`--obfuscate`, tree-shaking, AOT) make small Dart edits capable of large binary churn—but **delta size** depends on Play’s patcher, not on SHA inequality alone.
3. **Play does not only replace whole files.** File-level change detection matters, but **within-file binary deltas** can still be small or large. Unchanged `.so` files can be skipped; changed ones may still patch well.
4. **Existing packaging choices affect install *and* delta behavior:**
   - AAB (not multi-ABI fat APK), `abiFilters` / `--target-platform android-arm64`, R8 — primarily **install / split** sizing.
   - `extractNativeLibs="false"` stores native libs **uncompressed** in the APK; Google documents this as **beneficial to native binary-delta efficiency** (and avoids on-device extraction). It is **not** “install-size only,” and it does **not** guarantee that updates stay small when `libapp.so` / engine libs churn heavily.  
     *(CHANGELOG 2.0.12 claimed deltas would “no longer re-download the full app”; that overpromised in the opposite direction from an earlier draft of this report.)*

## What this is not (yet)

- Not proof of a misconfigured product flavor or missing AAB.
- Not proof the issue is Oppo A98–specific (same AAB physics may apply elsewhere; device-specific Console data still needed).
- Not fixed by removing Shorebird alone (Play store updates remain AAB-driven releases).

## Practical implications (framed as hypotheses)

- Large Play updates **may** track large native-lib changes across releases; confirm per version pair in Console.
- Small UI/code changes **can** still produce large `libapp.so` churn; whether users download ~full size is **unconfirmed** here.
- Dropping `--obfuscate` **might** change binary layout / delta quality; it is **not** established that it “will not” help—or that it will.

## Options going forward

| Option | Expected role |
|--------|----------------|
| Accept current Play behavior until Console confirms | Correct interim mental model |
| Reduce rarely changing assets (adhan audio, large JSON) | Modest install/update savings; does not address AOT churn |
| Experiment: drop or keep `--obfuscate` on controlled pairs | Measure **actual** patch / Console update size |
| Pin Flutter/engine/plugin versions across releases | Reduces avoidable `libflutter.so` / plugin `.so` churn when those should be identical |
| Re-evaluate code-push / patch products later | One possible path to small Dart-only updates; **not** the only conceivable mitigation |

## Decisive follow-ups

1. Compare the two real releases in **Play Console → App size** (authoritative update size).
2. Generate device-specific APK sets with an **Oppo-like** device spec; run **`bundletool get-size total`**.
3. Build **controlled pairs**: identical source + toolchain, then a one-line Dart change — **with and without** obfuscation; record Flutter engine revision and Git SHAs.
4. Measure **actual** bsdiff / archive-patcher (or Play-reported) output; investigate why **`libflutter.so` changed** in this experiment.

## Reproducing the hash/size check

```bash
./tool/compare_aab_native_libs.sh \
  artifacts/android/production/app-production-release-2.2.2+95.aab \
  artifacts/android/production/app-production-release-2.2.3-experiment+99999.aab
```

## Conclusion

**Preliminary:** `libapp.so` (and in this run also `libflutter.so` / Sentry libs) **changing between AABs** is a **likely contributor** to large Play updates on arm64 devices. On-disk AAB size (~60.6 MB) and native-lib hashes are solid; **delivered patch size and root cause are not confirmed**. Revise only after Play Console comparison and/or measured binary deltas on controlled builds.
