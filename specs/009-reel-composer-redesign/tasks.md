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

- [ ] `flutter analyze` is clean.
- [ ] `flutter test apps/tilawa` passes (existing + new tests).
- [ ] `flutter test packages/ui_kit` passes.
- [ ] Manual smoke on Pixel 6:
  - [ ] Generate reel for `Al-Baqarah 5–8` → review → save.
  - [ ] Force a generation error (airplane mode mid-generation) → see Retry → tap Retry → succeed.
  - [ ] Pick range exceeding `maxVersesPerClip` → see inline reason.
  - [ ] Pick `from > to` → see inline reason.
  - [ ] Confirm only one mushaf tree mounted during capture (Flutter Inspector).
- [ ] Manual smoke on iPhone SE (small device):
  - [ ] Stepper buttons are easy to hit.
  - [ ] No layout overflow in `ComposerControls`.
- [ ] Manual smoke in Arabic locale:
  - [ ] Banner names render correctly.
  - [ ] Inline reason text wraps cleanly.
  - [ ] Retry label localized.
- [ ] PR description includes before/after screenshots: composer (idle, busy, error), review (screenshot mode, reel mode).

---

## Phase 2: Crop-and-Compose

> Detailed task list pending. Headline tasks below.

- [ ] Extract `SelectionCropWindow` from [share_poster_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/share_poster_renderer.dart) into a pure function in `apps/tilawa/lib/features/share/presentation/utils/selection_crop_window.dart`.
- [ ] Apply the crop window to the reel path in [mushaf_page_renderer.dart](apps/tilawa/lib/features/share/presentation/widgets/mushaf_page_renderer.dart).
- [ ] Codify the canonical Surah Header Banner inclusion rule as a single helper.
- [ ] Reserve top 8% / bottom 14% safe zones on the 1080×1920 canvas.
- [ ] Eliminate the transparent-text trick from the reel path.
- [ ] Add the diacritic-safety upward extension to the crop window (calibrate in QA).
- [ ] Land behind `kReelComposerV2` compile-time switch.
- [ ] Goldens for `Al-Fatihah 1–7`, `Al-Baqarah 5–8`, `Yasin 36–40`, `Al-Kahf 1–3`, `An-Nas 1–6`.
- [ ] Pixel diff test: preview-at-1080×1920 vs. captured PNG < 1%.

---

## Phase 3: Single Composition Widget

> Detailed task list pending. Headline tasks below.

- [ ] Create `VideoComposition` widget at `apps/tilawa/lib/features/share/presentation/widgets/video_composition.dart` rendering at intrinsic 1080×1920.
- [ ] Use it in `_VideoLivePreview` via `FittedBox(contain)` (preview only).
- [ ] Use it offstage at native size for capture (no `FittedBox` between boundary and composition).
- [ ] Land behind `kReelComposerSingleTree` compile-time switch.
- [ ] Raster equivalence test: preview rendered at 1080×1920 == captured frame within ε.
- [ ] Live preview rebuild < 16ms during stepper interaction.

---

## Phase 4: Token Migration

> Detailed task list pending. Headline tasks below.

- [ ] Add `TilawaShareCanvasTokens` to [organisms_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart) with all the share-canvas factors and minima.
- [ ] Migrate every consumer of `VideoReelDesign` to the new tokens.
- [ ] Add `mediaPreviewFrameRadius` to `TilawaShareCanvasTokens` and replace the literal `borderRadius: 34` in [share_preview_widgets.dart](apps/tilawa/lib/features/share/presentation/widgets/share_preview_widgets.dart). *(Carried over from P1-004: the 10 dp delta vs `tokens.radiusExtraLarge` was deemed a design decision — owns by design, not a Phase 1 swap.)*
- [ ] Delete `VideoReelDesign` and [video_reel_design.dart](apps/tilawa/lib/features/share/presentation/widgets/video_reel_design.dart).
- [ ] Verify goldens pass in light, dark, and compact density.
- [ ] Decide on `_ReelBottomBar` re-introduction (token-driven organism) or finalize deletion.

---

## Phase 5: UX Upgrades

> Detailed task list pending. Headline tasks below.

- [ ] Replace `AyahRangeTile` (stepper pair) with `AyahRangeSlider` — keyboard and screen-reader supported.
- [ ] Add reciter audition button: 5s sample plays inline.
- [ ] Stage-labelled progress: "Capturing frames" → "Encoding video" → "Finalizing".
- [ ] Tap-to-toggle overlays: do not hide overlays during generation (lock visibility while busy).
- [ ] Confirm mode-aware Save/Share emphasis still passes in QA.

---

## Phase 6: PictureRecorder Capture (optional)

> Detailed task list pending. Highest risk. Gated on Phase 3.

- [ ] Implement `PictureRecorderCaptureService` rendering the `VideoComposition` directly to a `ui.Picture`.
- [ ] Add raster equivalence test vs. widget-tree capture.
- [ ] Memory peak under 250MB during 5-page reel.
- [ ] Ship only if both gates pass.
