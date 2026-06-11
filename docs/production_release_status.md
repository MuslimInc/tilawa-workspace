# Production release status

**Target:** Google Play **2.0.9+53** (version code **53**).  
**Previous tagged build:** **2.0.8+52** (`v2.0.8+52` pending).

## Quality gates (2026-06-11)

| Gate | Status |
|------|--------|
| `melos run analyze` | Pending |
| `cd apps/tilawa && flutter test` | Pending |
| Version bump committed | `apps/tilawa/pubspec.yaml` → `2.0.9+53` |
| Changelog / Play copy | [`CHANGELOG.md`](../CHANGELOG.md), [`release_notes.md`](release_notes.md), [`changelog.json`](../apps/tilawa/assets/changelog/changelog.json) |

## Pre-upload checklist

1. Tag: `git tag -a v2.0.9+53 -m "Release 2.0.9+53"` and push tag (pending)
2. Build via **Actions → Android Release (Google Play)** (`track: internal`, `build_name: 2.0.9`, `build_number: 53`) or locally:
   `cd apps/tilawa && flutter build appbundle --release --target-platform android-arm64 --split-debug-info=build/symbols`
3. Upload AAB to **Internal testing**; review pre-launch report
4. Paste **What's new** from [`release_notes.md`](release_notes.md) (en-US + ar)
5. Staged production rollout after sign-off

See also: [google_play_release_checklist.md](google_play_release_checklist.md), [ci_release.md](ci_release.md).
