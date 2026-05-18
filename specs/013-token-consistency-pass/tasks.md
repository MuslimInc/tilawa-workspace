# Tasks: Token Consistency Pass

**Feature Branch**: `013-token-consistency-pass`
**Created**: 2026-05-15

## Motion tokens

- [x] **T-001**: Audit every `Duration(milliseconds: N)` literal in `apps/tilawa/lib/features/` and replace UI-animation sites with `tokens.durationFast` / `durationMedium` / `durationSlow`.
- [x] **T-002**: Inline-comment any `initState`-scope `AnimationController` that can't read the theme.

## Type tokens

- [x] **T-010**: Replace `TextStyle(fontSize: N, …)` literals with `theme.textTheme.*` variants per the size-mapping rule in [plan.md](plan.md).
- [x] **T-011**: Leave `quran_reader_theme.dart` untouched (feature palette). Add an explicit note to [docs/design/colors.md](../../docs/design/colors.md) so future audits know this is intentional.

## Feedback tokens

- [x] **T-020**: Replace `SnackBar(...)` with `ToastUtils.show*Toast(...)` in 6 files: `prayer_times_screen.dart`, `prayer_notification_settings_sheet.dart`, `prayer_settings_sheet.dart`, `qibla_screen.dart`, `screenshot_composer_screen.dart`, `video_reel_composer_screen.dart`.

## Icon-button consistency

- [x] **T-030 (Pass A)**: Add `tooltip:` + `Semantics` parent to every bare `IconButton(...)` in `apps/tilawa/lib/features/` that lacks one. Six files known to be affected.
- [x] **T-031 (Pass B)**: Swap `IconButton` → `TilawaIconActionButton` where the call site is *not* inside `AppBar.actions` (those keep Material chrome — see prior spec).

## Touch feedback

- [x] **T-040**: Replace visible-cell `GestureDetector(onTap:)` with `InkWell` / `TilawaCard(onTap:)` in 8 files. Keep non-visible gesture detectors as-is.

## System chrome

- [x] **T-050** — *dropped on inspection*. The transparent `Color(0x00000000)` system-bar colours in [quran_reader_screen.dart:291-295](../../apps/tilawa/lib/features/quran_reader/presentation/screens/quran_reader_screen.dart) are **deliberate**: `_buildReaderSystemUiOverlayStyle` pairs them with `systemStatusBarContrastEnforced: false` to put the reader in immersive edge-to-edge mode so the Mushaf page extends behind the status bar. Replacing with `colorScheme.surface` would paint an opaque band over the page — the opposite of the intended UX. Leave as-is; add a code comment so the next audit doesn't re-flag this.

## Verification

- [x] **T-090**: `dart analyze` clean in `apps/tilawa` and `packages/ui_kit`.
- [x] **T-091**: UI Kit tests green (494/494 baseline).
- [x] **T-092**: Affected widget tests still pass; goldens regenerated only where a < 1 % visual diff is unavoidable.

## Follow-ups (out of scope)

- [ ] **F-001**: Decide whether to spec a `TilawaDialog` molecule (12 raw `AlertDialog` sites).
- [ ] **F-002**: Dynamic-type (textScaler 1.5×, 2.0×) golden coverage.
- [ ] **F-003**: Quran-reader theme: keep as Mushaf-only feature palette vs migrate to ColorScheme.
- [ ] **F-004**: Share-flow consolidation (three entry points → one).
- [ ] **F-005**: Quran-reader gesture discoverability (one-time tutorial).
