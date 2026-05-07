# Tasks: Quran Reel & Screenshot Composer Redesign

**Feature**: [Quran Reel & Screenshot Composer Redesign](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/009-reel-composer-redesign/spec.md)
**Plan**: [Implementation Plan](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/009-reel-composer-redesign/plan.md)

> Phase 1 is the only phase scoped for immediate execution. Phases 2–6 are listed for visibility and will be filled in further as each phase begins.

---

## Phase 1: Quick UI Fixes

Low-risk visual and UX fixes. **No render-pipeline changes.** Render the live preview the same way; only the composer chrome, review panel, scaffold defaults, and dead code are touched.

### P1-001: Retry parity on the reel composer

- [x] In [composer_controls.dart](apps/tilawa/lib/features/share/presentation/widgets/composer_controls.dart), add a `bool isError` derived from the cubit `ShareStatus.error` state via the call site.
- [x] When `isError` is true, swap the primary button label to `context.l10n.retry`, icon to `Icons.refresh_rounded`, and keep the same `onPrimaryAction` callback.
- [x] Update [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart) to pass the error state into the controls.
- [x] Tap on retry calls the existing `_handleGenerateVideo`.
- [x] Widget test: when `state.status == ShareStatus.error`, the primary button reads "Retry". *(Implemented as a focused `ComposerControls` test in [composer_controls_retry_test.dart](apps/tilawa/test/features/share/presentation/widgets/composer_controls_retry_test.dart) — testing the screen directly trips a GetIt lookup for `MushafService` from the live preview tree.)*
- [x] Widget test: tapping retry invokes the same generate handler.

### P1-002: Touch target compliance for stepper buttons

- [x] In [share_composer_widgets.dart](apps/tilawa/lib/features/share/presentation/widgets/share_composer_widgets.dart), wrap `_StepperButton`'s tappable area in a `SizedBox(width: 48, height: 48)` while keeping the visual icon at 36×36 via inner `Center` + `SizedBox(36×36)`.
- [x] `AyahStepper`'s outer `SizedBox(height: 36)` grew to `48` so the wider buttons aren't clipped vertically. *Visual height of the bordered stepper grew by 12 dp; design can token-tune in Phase 4 if needed.*
- [x] `InkWell` ripple stays circular via the existing `Material(shape: CircleBorder, clipBehavior: Clip.antiAlias)` — clipped to the 48-diameter circle, which is the recommended Material behaviour for round icon buttons.
- [x] Widget test: each `InkWell` inside `AyahStepper` reports ≥ 48 dp on both axes — see [ayah_stepper_hit_area_test.dart](apps/tilawa/test/features/share/presentation/widgets/ayah_stepper_hit_area_test.dart).
- [x] Widget test: a tap 22 dp from the visual centre (outside the visible 36×36 icon, inside the 48-circle) fires the callback.
- [ ] Manual test on Pixel 6 + iPhone SE (small device): adjacent steppers do not overlap in hit area. *(Pending real-device pass before PR.)*

### P1-003: Inline reason for invalid range

- [x] In [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart), derive a local `String? rangeIssue` from `(fromAyah, toAyah, maxAyah, ShareLimits.maxVersesPerClip)` via `_rangeIssueLabel`:
  - `from < 1 || to > maxAyah` → `context.l10n.shareInvalidRangeBounds`
  - `to < from` → `context.l10n.shareInvalidRangeOrder`
  - `to - from + 1 > maxVersesPerClip` → `context.l10n.maxVersesExceeded(maxVersesPerClip)` *(reused existing key, not a new "too-long" key — copy was already perfect)*
- [x] Pass `rangeIssue` into [composer_controls.dart](apps/tilawa/lib/features/share/presentation/widgets/composer_controls.dart) as a new optional prop.
- [x] Render `rangeIssue` as `bodySmall` text in `theme.colorScheme.error` below the controls card, only when `rangeIssue != null && !isBusy`. *Hidden when `errorMessage` is set so the cubit-level error takes precedence.*
- [x] Add new l10n keys in `app_en.arb` / `app_ar.arb` for the order and bounds messages (the too-long message reuses `maxVersesExceeded`). Regenerated via `flutter gen-l10n`.
- [x] Widget test: setting a `rangeIssue` renders the inline text — see [composer_controls_range_issue_test.dart](apps/tilawa/test/features/share/presentation/widgets/composer_controls_range_issue_test.dart).
- [x] Widget test: invalid range disables the primary button.
- [x] Widget test: range issue is hidden while busy and when `errorMessage` is set.

### P1-004: `MediaPreviewFrame` radius → token

- [x] Inspected [share_preview_widgets.dart](apps/tilawa/lib/features/share/presentation/widgets/share_preview_widgets.dart): outer `TilawaCard.borderRadius: 34` is paired with inner `DecoratedBox` already at `tokens.radiusExtraLarge` (24 dp comfortable / 20 dp compact). The nested two-radius design is **intentional** — a 10 dp rounding gradient between outer card and inner media surface.
- [x] Token swap evaluated: `tokens.radiusExtraLarge` would close that gradient (outer radius 24, inner radius 24 — visually flat). Delta to current value is 10 dp, well outside the spec's ±2 dp tolerance.
- [x] **Decision: defer to Phase 4.** Leave the literal `34` in place; add a `mediaPreviewFrameRadius` field to `TilawaShareCanvasTokens` during the token-migration phase, where design owns the visual decision (keep the gradient, flatten it, or pick a third value).
- [x] No source change in Phase 1. No new tests required.

### P1-005: `_ReelTopBar` font sizes → tokens

- [x] In [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart), replace `VideoReelDesign.topBarTitleFontSize` (16) with `theme.textTheme.titleMedium?.fontSize`. *(Material 3 base `titleMedium = 16`, exact match; `titleSmall` would have been 14 — a regression.)*
- [x] Replace `VideoReelDesign.topBarMetaFontSize` (14) with `theme.textTheme.bodyMedium?.fontSize`. *(Material 3 base `bodyMedium = 14`, exact match; `bodySmall` would have been 12.)*
- [x] Each token-driven size has a `?? VideoReelDesign.topBar*FontSize` fallback to guarantee no regression if the textTheme is unexpectedly null.
- [x] Verified `responsiveTextTheme` is not applied app-wide (no production callers) — `Theme.of(context).textTheme` returns Material 3 base sizes regardless of window size, so capture output stays stable across phones and tablets.
- [x] Keep `VideoReelDesign.topBar*FontSize` constants in place for now (Phase 4 deletes them).
- [x] All 60 share tests pass; analyzer clean.
- [ ] Manual visual check: top bar reads the same as before in light + dark. *(Pending pre-PR sweep on real device.)*

### P1-006: Mode-aware Save/Share emphasis

- [x] In [video_review_panel.dart](apps/tilawa/lib/features/share/presentation/widgets/video_review_panel.dart), added `ShareMode mode` prop (defaults to `ShareMode.video` to preserve existing behaviour for any uncovered consumers).
- [x] On `ShareMode.screenshot`: `Save` is `FilledButton.icon`; `Share` is `FilledButton.tonalIcon`. *(`FilledButton.tonalIcon` is already used elsewhere in the app, so it's part of the design system.)*
- [x] On `ShareMode.video`: `Share` stays `FilledButton.icon`; `Save` stays `OutlinedButton.icon` (current behaviour preserved).
- [x] `Edit` is `OutlinedButton` in both modes.
- [x] [screenshot_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/screenshot_composer_screen.dart) passes `mode: ShareMode.screenshot`; [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart) takes the default (`ShareMode.video`).
- [x] Widget tests rewritten in [video_review_panel_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_review_panel_test.dart): video-mode Save is OutlinedButton + callback fires + spinner-while-saving; screenshot-mode Save is FilledButton + callback fires + spinner-while-saving; share-button label parity for both modes.
- [x] All 64 share tests pass; analyzer clean for the new code (4 pre-existing `use_build_context_synchronously` infos in the screenshot screen's `_handleSavePreparedContent` are unchanged).

### P1-007: Live preview unmounted during capture (single-tree invariant)

- [x] In [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart), the `background:` selector inside `ImmersiveComposerScaffold` now renders `_GeneratingBackdrop` whenever `bState.status` is `capturing` or `generating`. The live `_VideoLivePreview` only mounts in the idle/error state.
- [x] `_GeneratingBackdrop` is a `ColoredBox` (`reelPalette.mushafBackgroundColor`) with a centered `theme.textTheme.bodyMedium` label that pulls `state.progressMessage` from the cubit via a focused `BlocSelector`.
- [x] Widget test: while in `ShareStatus.generating`, `find.byKey(ValueKey('live_preview'))` returns zero matches and `find.byKey(ValueKey('generating_backdrop'))` returns one — see [video_reel_composer_screen_capture_backdrop_test.dart](apps/tilawa/test/features/share/presentation/screens/video_reel_composer_screen_capture_backdrop_test.dart).
- [x] Same assertion verified for `ShareStatus.capturing`.
- [x] Widget test: backdrop renders the cubit's `progressMessage` so the user has a visible status while busy.
- [x] All 67 share tests pass; analyzer clean for new code.
- [ ] Smoke test on a real device: generate a 3-page reel and confirm no jank during the capture phase. *(Pending pre-PR sweep.)*

### P1-008: `disableBlur` becomes a context-aware default

- [x] In [immersive_composer_scaffold.dart](packages/ui_kit/lib/src/organisms/immersive_composer_scaffold.dart), added top-level `enum BackgroundIntent { ui, media }` and `backgroundIntent` parameter (defaults to `ui`).
- [x] `disableBlur` is now `bool?`. When `null`, the scaffold derives blur from `backgroundIntent` via the new `effectiveDisableBlur` getter: `media → blur off`, `ui → blur on`. Existing callers passing `disableBlur: true`/`false` keep their explicit override.
- [x] [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart): removed `disableBlur: true`; now passes `backgroundIntent: BackgroundIntent.media`.
- [x] [screenshot_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/screenshot_composer_screen.dart): now passes `backgroundIntent: BackgroundIntent.media` so the screenshot composer feels visually consistent with the reel composer (no blur on either).
- [x] [organisms_preview.dart](packages/ui_kit/lib/organisms_preview.dart) preview untouched — it relied on the previous unspecified `disableBlur: false` default; the new default is `BackgroundIntent.ui → false`, so behavior is identical.
- [x] Widget tests added in [immersive_composer_scaffold_test.dart](packages/ui_kit/test/organisms/immersive_composer_scaffold_test.dart): `BackgroundIntent.media` with no explicit `disableBlur` produces no `BackdropFilter`; `BackgroundIntent.ui` (default) keeps it; explicit `disableBlur: false` overrides `BackgroundIntent.media`.
- [x] All UI kit tests pass (10/10, +3 new); all 67 share tests pass; analyzer clean for the new code.

### P1-009: Delete `_ReelBottomBar` dead code

- [x] In [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart), deleted:
  - `_ReelBottomBar` class.
  - `_ReelPageNumberBadge` class.
  - The `// _ReelBottomBar(...)` commented call site.
  - No imports were unique to the deleted classes — `_localizedQuranNumber` is still used by `_ReelTopBar`'s juz number, so the helper stays.
- [x] In [video_reel_design.dart](apps/tilawa/lib/features/share/presentation/widgets/video_reel_design.dart), deleted the unused constants: `bottomBarHorizontalMarginFactor`, `bottomBarTopMarginFactor`, `bottomBarBottomMarginFactor`, `bottomBarHorizontalPadding`, `bottomBarVerticalPaddingFactor`, `bottomBarMinVerticalPadding`, `bottomBarMaxVerticalPadding`, `bottomBarRadius`, `bottomBarMetaFontSize`, `bottomBarBorderAlpha`, `pageBadgeSizeFactor`, `pageBadgeMinSize`, `pageBadgeMaxSize`, `pageBadgePadding`, `pageBadgeAccentAlpha`.
- [x] `frameAccentColor` (palette) is now unused outside the palette class itself but was **not** in the spec's deletion list — left for Phase 4's full palette/token migration so the deletion stays in scope.
- [x] All 67 share tests pass; `flutter analyze` clean on both touched files.

### P1-010: Phase 1 validation

#### Automated gates (all green)

- [x] `flutter analyze` clean for every Phase 1-touched file. The 8 `info`-level `use_build_context_synchronously` warnings in `_handleSavePreparedContent` of both composer screens are **pre-existing** (predate Phase 1) and were flagged from P1-001 onward; not in scope to fix.
- [x] `flutter test apps/tilawa --plain-name "share"` (focused share suite) — **67/67 pass**, +11 net new tests across Phase 1.
- [x] `flutter test packages/ui_kit/test/organisms/immersive_composer_scaffold_test.dart` — **10/10 pass**, +3 net new tests.
- [x] Pre-existing flakes spotted in the broader full-suite run (2 `audio_player_handler_impl_test.dart` failures, 29 macOS golden tests in `goldens/atoms_goldens_test.dart`, `molecules_goldens_test.dart`, `skeletonizer_goldens_test.dart`) are confirmed **unrelated to Phase 1** — git diff shows zero Phase 1 commits touched those areas, and the audio test passes when run in isolation.

#### Manual smoke (pre-PR, pending real-device sweep)

- [ ] **Pixel 6 / Android**:
  - [ ] Generate reel for `Al-Baqarah 5–8` → review → save.
  - [ ] Force a generation error (airplane mode mid-generation) → see Retry button → tap Retry → succeed.
  - [ ] Pick range exceeding `maxVersesPerClip` → see inline reason text in error colour.
  - [ ] Pick `from > to` → see inline reason text.
  - [ ] Confirm only one mushaf tree mounted during capture (Flutter Inspector).
  - [ ] Verify Save is **OutlinedButton** in reel review and **FilledButton** in screenshot review.
  - [ ] Verify both composers have **no blur** on the bottom panel.
- [ ] **iPhone SE / iOS** (small device):
  - [ ] Stepper buttons easy to tap (≥48dp hit area).
  - [ ] No layout overflow in `ComposerControls`.
- [ ] **Arabic locale**:
  - [ ] Banner names render correctly with QCF glyphs.
  - [ ] Inline range-issue messages wrap cleanly RTL (`shareInvalidRangeOrder`, `shareInvalidRangeBounds`, `maxVersesExceeded`).
  - [ ] Retry label is localized.
  - [ ] Stepper buttons stay symmetrical in RTL row.
- [ ] PR description includes before/after screenshots: composer (idle / busy / error), review (screenshot mode / reel mode), Arabic + English.

#### Phase 1 summary

| Task | Outcome |
| --- | --- |
| P1-001 | Retry parity on reel composer — done, 3 widget tests |
| P1-002 | Stepper button hit-area ≥48dp — done, 2 widget tests; visual stepper height grew 36→48 dp |
| P1-003 | Inline reason for invalid range — done, 4 widget tests, 2 new l10n keys + 1 reused |
| P1-004 | `MediaPreviewFrame` radius → token — **deferred to Phase 4** (10 dp delta would break the intentional nested-corner gradient) |
| P1-005 | `_ReelTopBar` font sizes → tokens — done via `titleMedium`/`bodyMedium` (spec's `titleSmall`/`bodySmall` would shrink) |
| P1-006 | Mode-aware Save/Share emphasis — done, `VideoReviewPanel` rewritten with `ShareMode` prop, 6 widget tests |
| P1-007 | Live preview unmounted during capture — done with new `_GeneratingBackdrop`, 3 widget tests |
| P1-008 | `disableBlur` context-aware default — done via new `BackgroundIntent` enum, 3 widget tests |
| P1-009 | `_ReelBottomBar` dead-code deletion — done, ~120 lines removed |
| P1-010 | Phase 1 validation — done (this task) |

**Carryovers to Phase 4**: media-preview-frame radius token; `frameAccentColor` palette field cleanup; `_ReelTopBar` weight scale; full `VideoReelDesign` palette migration to `TilawaShareCanvasTokens`.

---

## Phase 2: Crop-and-Compose

Goal: Make the reel path focus on the selected ayah range while preserving the current Phase 1 UI shell. All production behavior lands behind `kReelComposerV2` until goldens and pixel-diff checks pass.

### P2-001: Feature flag and composition constants

- [x] Add `const bool kReelComposerV2 = bool.fromEnvironment('REEL_COMPOSER_V2');` in [video_reel_composer_presets.dart](apps/tilawa/lib/features/share/presentation/utils/video_reel_composer_presets.dart) or a new [share_feature_flags.dart](apps/tilawa/lib/features/share/presentation/utils/share_feature_flags.dart).
- [x] Add reel canvas constants (`reelCanvasWidth = 1080`, `reelCanvasHeight = 1920`, `reelSafeZoneTopFraction = 0.08`, `reelSafeZoneBottomFraction = 0.14`) in [video_page_specs.dart](apps/tilawa/lib/features/share/presentation/utils/video_page_specs.dart) or a new [reel_canvas_metrics.dart](apps/tilawa/lib/features/share/presentation/utils/reel_canvas_metrics.dart).
- [x] Add tests for the new flag defaults and canvas constants in [video_page_specs_test.dart](apps/tilawa/test/features/share/presentation/utils/video_page_specs_test.dart) or a new [reel_canvas_metrics_test.dart](apps/tilawa/test/features/share/presentation/utils/reel_canvas_metrics_test.dart).

### P2-002: Extract selection crop window from screenshot path

- [x] Add [selection_crop_window.dart](apps/tilawa/lib/features/share/presentation/utils/selection_crop_window.dart) with a pure `SelectionCropWindow` value object and function that derives `top`, `bottom`, `height`, and selected block membership from rendered ayah blocks.
- [x] Move the current crop-window logic from [share_poster_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/share_poster_renderer.dart) into the new pure function without changing screenshot output.
- [x] Add unit tests in [selection_crop_window_test.dart](apps/tilawa/test/features/share/presentation/utils/selection_crop_window_test.dart): single selected block, multi-block range, first block on page, last block on page, empty block fallback.
- [ ] Add a regression widget test in [share_poster_renderer_test.dart](apps/tilawa/test/features/share/presentation/widgets/share_poster_renderer_test.dart) proving screenshot output still crops the same selected range after the extraction. *(Existing renderer smoke passes; exact crop-equivalence assertion still pending.)*

### P2-003: Add diacritic-safe crop expansion

- [x] Extend `SelectionCropWindow` in [selection_crop_window.dart](apps/tilawa/lib/features/share/presentation/utils/selection_crop_window.dart) with an upward safety inset for QCF diacritics, clamped to the page top.
- [x] Add tests in [selection_crop_window_test.dart](apps/tilawa/test/features/share/presentation/utils/selection_crop_window_test.dart): upward extension applies, does not underflow below zero, and preserves the selected bottom edge.
- [x] Add a QA calibration note in [tasks.md](specs/009-reel-composer-redesign/tasks.md) after implementation with the final chosen inset value and screenshots used to validate it. *(Initial inset: `4.0` px, validated by unit coverage for clamp/bottom-edge behavior; screenshot calibration remains part of P2 manual QA.)*

### P2-004: Canonical Surah Header Banner policy

- [x] Add [surah_header_policy.dart](apps/tilawa/lib/features/share/presentation/utils/surah_header_policy.dart) implementing the canonical rule from [spec.md](specs/009-reel-composer-redesign/spec.md): include the banner when the selection touches ayah 1 or when the composer is in its initial untouched range.
- [x] Add `SurahHeaderDecision` fields for `includeBanner`, `includeBismillah`, `surahNumber`, and `reason` in [surah_header_policy.dart](apps/tilawa/lib/features/share/presentation/utils/surah_header_policy.dart).
- [x] Add tests in [surah_header_policy_test.dart](apps/tilawa/test/features/share/presentation/utils/surah_header_policy_test.dart): selection includes ayah 1, initial untouched range excludes ayah 1, adjusted range excludes ayah 1, Al-Fatihah skips Bismillah, At-Tawbah skips Bismillah.
- [x] Replace the implicit `_injectMissingSurahHeaders` decision in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart) with the new helper under `kReelComposerV2`.
- [x] Keep the legacy `_injectMissingSurahHeaders` path when `kReelComposerV2 == false`.

### P2-005: Apply crop-and-compose to the reel renderer

- [x] Update [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart) so `kReelComposerV2` renders only the cropped selected blocks plus banner/Bismillah chrome instead of rendering non-selected verses transparently.
- [x] Reserve top and bottom safe zones in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart) using the Phase 2 canvas metrics before laying out selected Quran content.
- [x] Ensure the first selected ayah starts within the top 30% of the content area in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart).
- [x] Preserve the legacy transparent-text behavior when `kReelComposerV2 == false`.
- [x] Add focused widget tests in [mushaf_page_renderer_responsive_test.dart](apps/tilawa/test/features/share/presentation/widgets/mushaf_page_renderer_responsive_test.dart): selected mid-page ayahs are top-anchored under `REEL_COMPOSER_V2`, non-selected verses above the range are absent under the flag, and legacy behavior remains unchanged without the flag. *(Coverage asserts selected metadata under the flag, legacy full-page metadata without the flag, and no responsive overflow under both modes.)*

### P2-006: Keep preview and capture using the same crop data

- [x] Update `_VideoLivePreview` in [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart) to pass the same initial/adjusted-range context needed by `surah_header_policy.dart`.
- [x] Update `_OffScreenRenderers` in [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart) to use the same crop-window and banner-policy inputs as the live preview.
- [ ] Add tests in [video_reel_composer_screen_capture_backdrop_test.dart](apps/tilawa/test/features/share/presentation/screens/video_reel_composer_screen_capture_backdrop_test.dart) or a new [video_reel_composer_screen_crop_test.dart](apps/tilawa/test/features/share/presentation/screens/video_reel_composer_screen_crop_test.dart) that verify live preview and offstage renderer receive the same selected range and banner policy under `REEL_COMPOSER_V2`.

### P2-007: Golden coverage for canonical reel scenarios

- [ ] Add a reel golden harness in [video_reel_composer_goldens_test.dart](apps/tilawa/test/features/share/presentation/goldens/video_reel_composer_goldens_test.dart) or [mushaf_page_renderer_goldens_test.dart](apps/tilawa/test/features/share/presentation/goldens/mushaf_page_renderer_goldens_test.dart).
- [ ] Add golden baseline for `Al-Fatihah 1-7`: banner present, Bismillah absent, selected range top-anchored.
- [ ] Add golden baseline for `Al-Baqarah 5-8`: no non-selected ayahs above the selected range, first selected verse near top.
- [ ] Add golden baseline for `Yasin 36-40`: multi-line selection remains readable and inside safe zones.
- [ ] Add golden baseline for `Al-Kahf 1-3`: banner and Bismillah present.
- [ ] Add golden baseline for `An-Nas 1-6`: short final-surah selection top-anchored without awkward vertical centering.
- [ ] Document the golden update command in [tasks.md](specs/009-reel-composer-redesign/tasks.md) after the baselines are generated.

### P2-008: Pixel-diff preview/export parity gate

- [ ] Add a test helper in [video_reel_composer_pixel_diff_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_reel_composer_pixel_diff_test.dart) that renders the preview at 1080x1920 and compares it to a captured PNG from the offstage path.
- [ ] Assert pixel diff is `< 1%` for `Al-Baqarah 5-8` under `REEL_COMPOSER_V2`.
- [ ] Add failure-artifact output to `apps/tilawa/test/failures/reel_composer/` for preview image, capture image, and diff mask.
- [ ] Keep the test skipped or tagged as `golden` until deterministic font loading is confirmed on CI.

### P2-009: Phase 2 validation

- [x] Run `fvm flutter test test/features/share/presentation/utils/selection_crop_window_test.dart` in [apps/tilawa](apps/tilawa).
- [x] Run `fvm flutter test test/features/share/presentation/utils/surah_header_policy_test.dart` in [apps/tilawa](apps/tilawa).
- [x] Run `fvm flutter test test/features/share/presentation/widgets/share_poster_renderer_test.dart test/features/share/presentation/widgets/mushaf_page_renderer_responsive_test.dart` in [apps/tilawa](apps/tilawa).
- [ ] Run the new reel golden suite with `REEL_COMPOSER_V2=true`.
- [x] Run `fvm flutter analyze lib/features/share/presentation test/features/share/presentation` in [apps/tilawa](apps/tilawa).
- [ ] Manual QA on Pixel 6 and iPhone SE: verify `Al-Baqarah 5-8`, `Yasin 36-40`, and `Al-Kahf 1-3` are focused, top-anchored, and readable.

---

## Phase 3: Single Composition Widget

Goal: Make preview and export share one intrinsic 1080x1920 composition widget. Production behavior lands behind `kReelComposerSingleTree` until raster equivalence passes.

### P3-001: Feature flag and composition contract

- [ ] Add `const bool kReelComposerSingleTree = bool.fromEnvironment('REEL_COMPOSER_SINGLE_TREE');` in [share_feature_flags.dart](apps/tilawa/lib/features/share/presentation/utils/share_feature_flags.dart).
- [ ] Add a `VideoCompositionSpec` value object in [video_composition.dart](apps/tilawa/lib/features/share/presentation/widgets/video_composition.dart) or [video_page_specs.dart](apps/tilawa/lib/features/share/presentation/utils/video_page_specs.dart) that carries selected ayahs, page specs, banner policy, capture mode, locale, and canvas metrics.
- [ ] Add tests in [video_composition_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_composition_test.dart) proving the spec is immutable/equatable enough for stable rebuilds.

### P3-002: Build `VideoComposition`

- [ ] Create [video_composition.dart](apps/tilawa/lib/features/share/presentation/widgets/video_composition.dart) with a widget that renders at intrinsic 1080x1920 without depending on parent constraints.
- [ ] Move the reel frame structure currently in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart) into `VideoComposition` behind `kReelComposerSingleTree`.
- [ ] Ensure `VideoComposition` uses `MushafPageRenderer` or lower-level renderers as children without adding `FittedBox` inside the export boundary.
- [ ] Export `VideoComposition` from [widgets.dart](apps/tilawa/lib/features/share/presentation/widgets/widgets.dart).
- [ ] Add widget tests in [video_composition_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_composition_test.dart): intrinsic size is 1080x1920, safe-zone guides can be enabled for edit mode, and safe-zone guides are hidden for review/export mode.

### P3-003: Use `VideoComposition` in live preview

- [ ] Update `_VideoLivePreview` in [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart) to render `VideoComposition` inside `FittedBox(fit: BoxFit.contain)` when `kReelComposerSingleTree == true`.
- [ ] Keep the Phase 2 preview path when `kReelComposerSingleTree == false`.
- [ ] Add tests in [video_reel_composer_screen_save_state_test.dart](apps/tilawa/test/features/share/presentation/screens/video_reel_composer_screen_save_state_test.dart) or [video_composition_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_composition_test.dart) that the live preview contains one `VideoComposition` under the flag.

### P3-004: Use `VideoComposition` in offstage capture

- [ ] Update `_OffScreenRenderers` in [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart) to render `VideoComposition` at native 1080x1920 with no `FittedBox` between `RepaintBoundary` and the composition when `kReelComposerSingleTree == true`.
- [ ] Ensure every `WidgetCaptureHandle` in [widget_capture_handle.dart](apps/tilawa/lib/features/share/domain/entities/widget_capture_handle.dart) still resolves the correct boundary key for each page.
- [ ] Add a widget test in [video_composition_capture_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_composition_capture_test.dart) that fails if a `FittedBox` exists between the export boundary and `VideoComposition`.

### P3-005: Raster equivalence and performance gates

- [ ] Extend [video_reel_composer_pixel_diff_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_reel_composer_pixel_diff_test.dart) to compare live-preview-at-1080x1920 with offstage-capture output under `REEL_COMPOSER_SINGLE_TREE`.
- [ ] Assert raster diff is within epsilon for `Al-Baqarah 5-8`, `Al-Kahf 1-3`, and `An-Nas 1-6`.
- [ ] Add a rebuild benchmark in [video_composition_perf_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_composition_perf_test.dart) proving stepper interaction rebuilds stay under 16ms on the test host baseline.
- [ ] Document benchmark caveats and real-device timing in [tasks.md](specs/009-reel-composer-redesign/tasks.md) after the run.

### P3-006: Phase 3 validation

- [ ] Run `fvm flutter test test/features/share/presentation/widgets/video_composition_test.dart` in [apps/tilawa](apps/tilawa).
- [ ] Run `fvm flutter test test/features/share/presentation/widgets/video_composition_capture_test.dart` in [apps/tilawa](apps/tilawa).
- [ ] Run the pixel-diff suite with `REEL_COMPOSER_V2=true` and `REEL_COMPOSER_SINGLE_TREE=true`.
- [ ] Run `fvm flutter analyze lib/features/share/presentation test/features/share/presentation` in [apps/tilawa](apps/tilawa).
- [ ] Manual QA on Pixel 6 and iPhone SE: preview and exported frame visually match for the five canonical selections.

---

## Phase 4: Token Migration

Goal: Move reel/screenshot composition styling out of feature-local constants and into Tilawa UI Kit tokens, then delete `VideoReelDesign`.

### P4-001: Add UI Kit share-canvas tokens

- [ ] Add `TilawaShareCanvasTokens` to [organisms_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart) with top bar, bottom bar, safe-zone, banner-gap, highlight-opacity, canvas-radius, and media-preview-frame-radius fields.
- [ ] Add lerp/copy/equality support for `TilawaShareCanvasTokens` in [organisms_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart) and [token_lerp.dart](packages/ui_kit/lib/src/foundation/component_tokens/token_lerp.dart) if needed.
- [ ] Expose the tokens through [component_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens.dart) and [component_tokens_theme.dart](packages/ui_kit/lib/src/foundation/component_tokens/component_tokens_theme.dart).
- [ ] Add tests in [component_tokens_test.dart](packages/ui_kit/test/foundation/component_tokens_test.dart) for defaults, copyWith, equality, and density overrides.
- [ ] Add tests in [component_tokens_density_test.dart](packages/ui_kit/test/foundation/component_tokens_density_test.dart) for comfortable and compact share-canvas token values.

### P4-002: Migrate reel composition dimensions

- [ ] Replace `VideoReelDesign.topBar*`, gap, safe-zone, and layout factor reads in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart) with `TilawaShareCanvasTokens`.
- [ ] Replace Phase 2 canvas metric literals in [reel_canvas_metrics.dart](apps/tilawa/lib/features/share/presentation/utils/reel_canvas_metrics.dart) with token-backed defaults where appropriate.
- [ ] Keep explicit fallbacks for any token read that can be null in tests.
- [ ] Add widget tests in [mushaf_page_renderer_responsive_test.dart](apps/tilawa/test/features/share/presentation/widgets/mushaf_page_renderer_responsive_test.dart) for comfortable and compact density dimensions.

### P4-003: Migrate reel composition colors

- [ ] Replace `VideoReelDesign.mushafBackgroundColor` in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart) with `theme.colorScheme.surfaceContainerLowest` or the new share-canvas token.
- [ ] Replace `VideoReelDesign.frameSurfaceColor`, `frameTextColor`, `frameSecondaryTextColor`, and `frameStrongTextColor` in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart) with `ColorScheme` and token opacity values.
- [ ] Replace `VideoReelDesign.verseHighlightColor` with `theme.colorScheme.primary.withValues(alpha: tokens.shareCanvas.highlightOpacity)` in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart).
- [ ] Decide whether `frameAccentColor` remains as a token or is removed; document the decision in [tasks.md](specs/009-reel-composer-redesign/tasks.md).
- [ ] Add light/dark widget or golden assertions in [mushaf_page_renderer_responsive_test.dart](apps/tilawa/test/features/share/presentation/widgets/mushaf_page_renderer_responsive_test.dart).

### P4-004: Migrate media preview frame radius

- [ ] Add `mediaPreviewFrameRadius` to `TilawaShareCanvasTokens` in [organisms_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart).
- [ ] Replace the literal `borderRadius: 34` in [share_preview_widgets.dart](apps/tilawa/lib/features/share/presentation/widgets/share_preview_widgets.dart) with `tokens.shareCanvas.mediaPreviewFrameRadius`.
- [ ] Add a widget test in [share_poster_renderer_test.dart](apps/tilawa/test/features/share/presentation/widgets/share_poster_renderer_test.dart) or a new [share_preview_widgets_test.dart](apps/tilawa/test/features/share/presentation/widgets/share_preview_widgets_test.dart) proving the token is applied.
- [ ] Capture before/after screenshots for design review and attach them to the PR.

### P4-005: Remove `VideoReelDesign`

- [ ] Delete every remaining production reference to [video_reel_design.dart](apps/tilawa/lib/features/share/presentation/widgets/video_reel_design.dart).
- [ ] Delete [video_reel_design.dart](apps/tilawa/lib/features/share/presentation/widgets/video_reel_design.dart).
- [ ] Remove the export from [widgets.dart](apps/tilawa/lib/features/share/presentation/widgets/widgets.dart) if present.
- [ ] Run `rg "VideoReelDesign|video_reel_design" apps/tilawa packages/ui_kit` and record zero production hits in [tasks.md](specs/009-reel-composer-redesign/tasks.md).

### P4-006: Token migration goldens and validation

- [ ] Add or update UI Kit goldens in [organisms_goldens_test.dart](packages/ui_kit/test/goldens/organisms_goldens_test.dart) if `TilawaShareCanvasTokens` affects exported organisms.
- [ ] Add reel composition goldens for light, dark, and compact density in [video_reel_composer_goldens_test.dart](apps/tilawa/test/features/share/presentation/goldens/video_reel_composer_goldens_test.dart).
- [ ] Run `fvm flutter test test/foundation/component_tokens_test.dart test/foundation/component_tokens_density_test.dart` in [packages/ui_kit](packages/ui_kit).
- [ ] Run `fvm flutter test test/goldens` in [packages/ui_kit](packages/ui_kit).
- [ ] Run the app reel golden suite in [apps/tilawa](apps/tilawa).
- [ ] Run `fvm flutter analyze packages/ui_kit apps/tilawa/lib/features/share/presentation apps/tilawa/test/features/share/presentation` from the workspace root.

---

## Phase 5: UX Upgrades

Goal: Improve composer interaction quality after the renderer and token migration are stable.

### P5-001: Replace stepper pair with accessible range slider

- [ ] Add [ayah_range_slider.dart](apps/tilawa/lib/features/share/presentation/widgets/ayah_range_slider.dart) with keyboard, pointer, and screen-reader support for selecting `fromAyah` and `toAyah`.
- [ ] Add localized semantics labels to [app_en.arb](apps/tilawa/lib/l10n/app_en.arb) and [app_ar.arb](apps/tilawa/lib/l10n/app_ar.arb) for increasing/decreasing start and end ayah.
- [ ] Run `fvm flutter gen-l10n` from [apps/tilawa](apps/tilawa).
- [ ] Replace `AyahRangeTile` usage in [composer_controls.dart](apps/tilawa/lib/features/share/presentation/widgets/composer_controls.dart) with `AyahRangeSlider` while keeping the old stepper behind a temporary `kUseLegacyAyahStepper` flag if needed.
- [ ] Add widget and semantics tests in [ayah_range_slider_test.dart](apps/tilawa/test/features/share/presentation/widgets/ayah_range_slider_test.dart): drag start handle, drag end handle, keyboard increment/decrement, RTL layout, semantics label correctness.
- [ ] Update [composer_controls_range_issue_test.dart](apps/tilawa/test/features/share/presentation/widgets/composer_controls_range_issue_test.dart) for the slider-driven control path.

### P5-002: Add reciter audition button

- [ ] Add [reciter_audition_button.dart](apps/tilawa/lib/features/share/presentation/widgets/reciter_audition_button.dart) with play, stop, loading, and error states.
- [ ] Add a 5-second audition method to [audio_clip_service.dart](apps/tilawa/lib/features/share/data/services/audio_clip_service.dart) or a new [reciter_audition_service.dart](apps/tilawa/lib/features/share/data/services/reciter_audition_service.dart).
- [ ] Wire the audition service through [share_repository.dart](apps/tilawa/lib/features/share/domain/repositories/share_repository.dart), [share_repository_impl.dart](apps/tilawa/lib/features/share/data/repositories/share_repository_impl.dart), and the share DI module.
- [ ] Surface audition events/state in [share_cubit.dart](apps/tilawa/lib/features/share/presentation/cubit/share_cubit.dart) without changing the existing generation state machine.
- [ ] Add unit tests for the service in [audio_clip_service_test.dart](apps/tilawa/test/features/share/data/services/audio_clip_service_test.dart) or [reciter_audition_service_test.dart](apps/tilawa/test/features/share/data/services/reciter_audition_service_test.dart).
- [ ] Add cubit tests in [share_cubit_reciter_options_test.dart](apps/tilawa/test/features/share/presentation/cubit/share_cubit_reciter_options_test.dart).
- [ ] Add widget tests in [reciter_audition_button_test.dart](apps/tilawa/test/features/share/presentation/widgets/reciter_audition_button_test.dart): tap plays, second tap stops, loading state disables repeated taps, failure shows a localized inline error.

### P5-003: Stage-labelled generation progress

- [ ] Add explicit progress stages to [share_progress_messages.dart](apps/tilawa/lib/features/share/domain/entities/share_progress_messages.dart): capturing frames, encoding video, finalizing.
- [ ] Map stages to localized labels in [share_progress_messages_l10n.dart](apps/tilawa/lib/features/share/presentation/share_progress_messages_l10n.dart), [app_en.arb](apps/tilawa/lib/l10n/app_en.arb), and [app_ar.arb](apps/tilawa/lib/l10n/app_ar.arb).
- [ ] Emit staged progress from [generate_video_use_case.dart](apps/tilawa/lib/features/share/domain/usecases/generate_video_use_case.dart), [share_repository_impl.dart](apps/tilawa/lib/features/share/data/repositories/share_repository_impl.dart), and [video_service.dart](apps/tilawa/lib/features/share/data/services/video_service.dart) without changing FFmpeg encoding settings.
- [ ] Update [share_progress_overlay.dart](apps/tilawa/lib/features/share/presentation/widgets/share_progress_overlay.dart) to display the current stage and progress fraction.
- [ ] Add tests in [video_service_test.dart](apps/tilawa/test/features/share/data/services/video_service_test.dart) for stage emission order.
- [ ] Add widget tests in [share_progress_overlay_test.dart](apps/tilawa/test/features/share/presentation/widgets/share_progress_overlay_test.dart): each stage renders, label wraps cleanly in Arabic, and progress uses a live region semantics announcement.

### P5-004: Lock overlay visibility while busy

- [ ] Update tap-to-toggle handling in [video_reel_composer_screen.dart](apps/tilawa/lib/features/share/presentation/screens/video_reel_composer_screen.dart) so controls cannot be hidden while `ShareStatus.capturing` or `ShareStatus.generating`.
- [ ] Ensure cancel remains visible and reachable while busy in [composer_controls.dart](apps/tilawa/lib/features/share/presentation/widgets/composer_controls.dart).
- [ ] Add tests in [video_reel_composer_screen_save_state_test.dart](apps/tilawa/test/features/share/presentation/screens/video_reel_composer_screen_save_state_test.dart): tapping preview while busy does not hide controls, tapping preview while idle still toggles overlays.

### P5-005: Review mode QA and validation

- [ ] Re-run [video_review_panel_test.dart](apps/tilawa/test/features/share/presentation/widgets/video_review_panel_test.dart) to confirm screenshot Save remains filled and reel Share remains filled.
- [ ] Run `fvm flutter test --plain-name "share"` in [apps/tilawa](apps/tilawa).
- [ ] Run `fvm flutter analyze lib/features/share test/features/share` in [apps/tilawa](apps/tilawa).
- [ ] Manual QA on Pixel 6 and iPhone SE: slider touch/keyboard behavior, audition play/stop, staged progress labels, cancel visibility during generation.
- [ ] Manual Arabic QA: slider semantics, progress labels, and audition error copy wrap cleanly RTL.

---

## Phase 6: PictureRecorder Capture (optional)

Goal: Replace widget-tree capture only if direct `PictureRecorder` rendering proves equivalent and materially improves performance/memory. This phase is optional and gated on Phase 3.

### P6-001: Add optional capture flag and service contract

- [ ] Add `const bool kCaptureViaPictureRecorder = bool.fromEnvironment('CAPTURE_VIA_PICTURE_RECORDER');` in [share_feature_flags.dart](apps/tilawa/lib/features/share/presentation/utils/share_feature_flags.dart).
- [ ] Add a capture abstraction in [screenshot_service.dart](apps/tilawa/lib/features/share/data/services/screenshot_service.dart) or a new [composition_capture_service.dart](apps/tilawa/lib/features/share/data/services/composition_capture_service.dart) that supports both widget-tree and picture-recorder implementations.
- [ ] Keep the existing widget-tree capture as the default implementation when `kCaptureViaPictureRecorder == false`.

### P6-002: Implement `PictureRecorderCaptureService`

- [ ] Add [picture_recorder_capture_service.dart](apps/tilawa/lib/features/share/data/services/picture_recorder_capture_service.dart) rendering `VideoComposition`-equivalent drawing commands into a `ui.Picture`.
- [ ] Ensure the service outputs exact 1080x1920 PNG frames with the same locale, banner, Bismillah, safe-zone, and token inputs as [video_composition.dart](apps/tilawa/lib/features/share/presentation/widgets/video_composition.dart).
- [ ] Add structured logs for capture time, image dimensions, and memory markers in [picture_recorder_capture_service.dart](apps/tilawa/lib/features/share/data/services/picture_recorder_capture_service.dart).
- [ ] Register the service in share DI while keeping the default path unchanged.

### P6-003: Raster equivalence tests

- [ ] Add [picture_recorder_capture_service_test.dart](apps/tilawa/test/features/share/data/services/picture_recorder_capture_service_test.dart) with deterministic fixtures for the five canonical selections.
- [ ] Compare `PictureRecorderCaptureService` output against widget-tree `VideoComposition` capture for `Al-Fatihah 1-7`, `Al-Baqarah 5-8`, `Yasin 36-40`, `Al-Kahf 1-3`, and `An-Nas 1-6`.
- [ ] Fail the test if raster diff exceeds the same epsilon used by Phase 3.
- [ ] Write failure artifacts to `apps/tilawa/test/failures/picture_recorder/`.

### P6-004: Performance and memory gates

- [ ] Add a benchmark in [picture_recorder_capture_service_perf_test.dart](apps/tilawa/test/features/share/data/services/picture_recorder_capture_service_perf_test.dart) for a 5-page reel capture.
- [ ] Verify memory peak stays under 250MB during the 5-page benchmark on Pixel 6.
- [ ] Verify per-page capture raster time stays under 200ms on Pixel 6 and iPhone 12-class hardware.
- [ ] Document benchmark device, OS version, Flutter version, and results in [tasks.md](specs/009-reel-composer-redesign/tasks.md).

### P6-005: Optional rollout decision

- [ ] If raster and performance gates pass, wire `kCaptureViaPictureRecorder` through [generate_video_use_case.dart](apps/tilawa/lib/features/share/domain/usecases/generate_video_use_case.dart), [share_repository_impl.dart](apps/tilawa/lib/features/share/data/repositories/share_repository_impl.dart), and [video_service.dart](apps/tilawa/lib/features/share/data/services/video_service.dart).
- [ ] If either gate fails, leave the flag default off and document why the widget-tree capture path remains canonical.
- [ ] Add rollback instructions to the PR description: disable `CAPTURE_VIA_PICTURE_RECORDER` to return to widget-tree capture.
- [ ] Run `fvm flutter test test/features/share/data/services/picture_recorder_capture_service_test.dart` in [apps/tilawa](apps/tilawa).
- [ ] Run `fvm flutter analyze lib/features/share test/features/share` in [apps/tilawa](apps/tilawa).

---

## Cross-Phase Dependencies

| Dependency | Required Before |
| --- | --- |
| P2 crop window + banner policy | P3 `VideoComposition`, P4 token migration goldens |
| P2 golden/pixel-diff harness | P3 raster equivalence, P6 picture-recorder equivalence |
| P3 `VideoComposition` | P6 `PictureRecorderCaptureService` |
| P4 `TilawaShareCanvasTokens` | P5 final visual QA, optional P6 direct renderer parity |
| P5 staged progress | Any future UX change to generation/cancel flow |

## Parallel Execution Notes

- P2-002 (`selection_crop_window`) and P2-004 (`surah_header_policy`) can be implemented in parallel because they touch separate utility files and tests.
- P2-007 golden harness can start after P2-005 has a stable flagged render path; baseline generation should wait for P2-006.
- P3-002 (`VideoComposition`) and P3-004 offstage wiring must be sequential because the capture path depends on the widget contract.
- P4-001 UI Kit token work can proceed in parallel with P4-003 color migration once token names and defaults are agreed.
- P5-001 range slider and P5-002 reciter audition can proceed in parallel; both converge in `ComposerControls` and should be integrated sequentially.
- P6 work must remain sequential after P3 because direct rendering has to match the final `VideoComposition` contract.

## Implementation Strategy

1. Treat Phase 2 as the next MVP: it delivers selected-range focus and explicit banner behavior behind `REEL_COMPOSER_V2`.
2. Do not flip any new flag by default until that phase's validation block is green.
3. Keep each phase independently reviewable and avoid mixing Phase 4 token migration with Phase 2/3 render-pipeline changes.
4. Preserve the widget-tree capture path until Phase 6 passes both raster and memory gates.
5. Update this task file after each phase with exact command output summaries, generated baseline paths, manual QA devices, and any deferred carryovers.
