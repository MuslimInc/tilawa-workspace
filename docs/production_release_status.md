# Production release status

**Target:** Google Play **2.0.8+52** (version code **52**).  
**Previous tagged build:** **2.0.7+51** (`v2.0.7+51`).

## Quality gates (2026-06-10)

| Gate | Status |
|------|--------|
| `melos run analyze` | Clean |
| `cd apps/tilawa && flutter test` | 2930 passed, 3 skipped |
| Version bump committed | `apps/tilawa/pubspec.yaml` → `2.0.8+52` |
| Changelog / Play copy | [`CHANGELOG.md`](../CHANGELOG.md), [`release_notes.md`](release_notes.md) |

## Pre-upload checklist

1. Tag: `git tag -a v2.0.8+52 -m "Release 2.0.8+52"` and push tag
2. Build via **Actions → Android Release (Google Play)** (`track: internal`, `build_name: 2.0.8`, `build_number: 52`) or locally:
   `cd apps/tilawa && flutter build appbundle --release --target-platform android-arm64 --split-debug-info=build/symbols`
3. Upload AAB to **Internal testing**; review pre-launch report
4. Paste **What's new** from [`release_notes.md`](release_notes.md) (en-US + ar)
5. Staged production rollout after sign-off

See also: [google_play_release_checklist.md](google_play_release_checklist.md), [ci_release.md](ci_release.md).
