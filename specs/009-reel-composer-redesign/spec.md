# Feature Specification: Quran Reel & Screenshot Composer Redesign

**Feature Branch**: `009-reel-composer-redesign`
**Created**: 2026-05-07
**Status**: Planning
**Depends On**: Tilawa UI Kit foundation (tokens, density, theming), `quran_qcf` page preparation services, existing share/export pipeline (FFmpeg, screenshot capture)

---

## Context

The Quran share feature has two output paths — a **screenshot composer** (`SharePosterRenderer`, vertical crop of a mushaf page) and a **video reel composer** (`MushafPageRenderer`, full 9:16 page with non-selected verses rendered transparent). A senior-eyes audit (2026-05-07) found that the two paths use different rendering strategies, the live preview does not match the exported output for reels, the surah header banner inclusion rule is implicit and inconsistent, the social-platform safe zones are not respected, and several design-system tokens are bypassed.

This feature redesigns the composer family to deliver a polished, premium share experience that:

1. Focuses the exported screenshot/video on the **selected ayah range**, not the whole mushaf page.
2. Makes the **preview match the export** pixel-for-pixel.
3. Includes the **Surah Header Banner** under a single explicit rule across both paths.
4. Respects **social-platform safe zones** (Instagram Reels, TikTok, YouTube Shorts).
5. Consolidates the feature onto **Tilawa UI Kit tokens** instead of a parallel hardcoded palette.

The feature is delivered in six phases. Phase 1 (this spec's first deliverable) ships only **low-risk visual and UX fixes** that do not touch the render pipeline. Later phases redesign the composition strategy, unify the renderer, and introduce the token migration.

---

## Problem Statement

### Render-pipeline gaps

1. **Two divergent renderers.** Screenshot uses `SharePosterRenderer` (crop window). Video uses `MushafPageRenderer` (transparent text). Same selection produces visually different outputs.
2. **Preview ≠ export for the reel path.** `_VideoLivePreview` (`isCapturing: false`) and `_OffScreenRenderers` (`isCapturing: true`, wrapped in `FittedBox(BoxFit.contain)` over a 1080×1920 box) lay out in different parents and can wrap text differently.
3. **Selection is not anchored to the top.** Non-selected ayahs are rendered as transparent text but still consume vertical space, so a mid-page selection floats lower in the frame than expected. Contradicts the product requirement: *"Start the selected ayah content near the top of the composition"*.
4. **Surah Header Banner inclusion is implicit.** `_injectMissingSurahHeaders` only fires when a rendered text block contains `verse == 1`. Selections that exclude ayah 1 never get a banner — even when the banner would be useful (e.g. selection from a long surah).
5. **Capture-time fractional scaling.** Video capture runs through `FittedBox(contain)` over a `RepaintBoundary` declared as 1080×1920, so the rasterized pixel size depends on the offstage layout, not the declared size. Risk of blurry text / wrong DPR.
6. **Diacritic clipping risk.** The screenshot poster crops to `block.painter.height`, which excludes top-side diacritic ascent on QCF PUA glyphs.
7. **Screenshot crop preserves original page offset.** `SharePosterRenderer` currently renders a full `PageContent` inside `OverflowBox` and shifts it with `Transform.translate`. This captures a slice of the original page rather than composing the selected range from the top, so mid-page selections can produce large empty areas and no leading Surah Header Banner.

### UX gaps

7. **No retry on the reel screen** when generation fails (the screenshot screen has retry).
8. **No invalid-range hint.** The "Generate Reel" button silently disables when the user exceeds `ShareLimits.maxVersesPerClip` or picks an invalid range.
9. **Touch targets below platform minimums.** `_StepperButton` is 36×36 (iOS HIG: 44pt; Android: 48dp).
10. **Save vs. Share emphasis is wrong.** `VideoReviewPanel` puts Save as outlined next to Edit; on a *screenshot* output, Save is usually the primary intent.
11. **Tap-to-toggle hides the cancel button** mid-generation if the user touches the preview.
12. **Two mushaf trees mounted simultaneously** during generation (live preview + offstage capture).

### Design-system gaps

13. **Parallel palette.** `VideoReelDesign` carries hardcoded hex (`0xFFFFF8ED`, `0xF52E2116`, `0xFFC5A358`, …). These are not in `app_colors.dart`.
14. **Token bypass.** `MediaPreviewFrame` uses `borderRadius: 34`, `_ReelTopBar` uses `fontSize: 16/14/12`, all literals.
15. **Dead code.** `_ReelBottomBar` is commented out but its constants and import remain.
16. **Mode-coupled blur.** `disableBlur: true` is hardcoded only on the reel composer; the screenshot composer keeps blur. Two screens with the same scaffold feel like two products.
17. **Save/Edit/Share role split** is identical across screenshot and reel modes despite different user intents.

---

## Goals

1. Make the **exported reel and screenshot focus on the selected ayah range**, anchored near the top of the composition.
2. Make the **live preview match the export** for both modes (same widget tree, scaled).
3. Adopt a **single, explicit Surah Header Banner rule** documented in this spec and enforced by both renderers.
4. Reserve **social-platform safe zones** (top ~8%, bottom ~14%) so the last selected ayah is never under platform UI.
5. Promote `VideoReelDesign` colors and dimensions into **Tilawa UI Kit tokens**.
6. Bring composer touch targets, retry/cancel parity, and primary-action emphasis to the **rest-of-app baseline**.
7. Eliminate **dead code** (`_ReelBottomBar` and related tokens) — either wire it back as a token-driven organism or delete it.
8. Provide a **golden-test suite** for the canonical selection scenarios (single ayah, multi-line, page-boundary, multi-page, surah-boundary).

---

## Non-Goals

1. **Do not** redesign the share *destination* picker (system share sheet, save-to-gallery flow). Out of scope.
2. **Do not** touch the FFmpeg pipeline, video encoding profile, or audio mixing. The capture surface and timing change; the encode does not.
3. **Do not** change the QCF font loading mechanism or the `quran_qcf` package's internal layout strategy.
4. **Do not** re-architect `ShareCubit` state machine. Add at most additional fields/events; do not rename existing states.
5. **Do not** touch the reciter picker / audio configuration UI in this feature beyond the audition affordance in Phase 5.
6. **Do not** migrate routing, deep links, or the entry points into the composer.
7. **Do not** introduce a new state-management library or rendering framework.
8. **Do not** ship a "skeleton-to-content morph" or animated banner reveal; render decisions stay synchronous.

---

## Product Requirements (load-bearing)

When the user selects ayahs and generates a screenshot or reel video, the final output **must**:

| Requirement | Rule |
|---|---|
| **R1 — Selection focus** | The exported frame shows only the selected ayah range (and the Surah Header Banner when R3 applies). No non-selected verses appear above the first selected verse. |
| **R2 — Top anchoring** | The first selected verse appears within the **top 30%** of the composition's content area (the area below the Surah Header Banner and above the bottom safe zone). |
| **R3 — Surah Header Banner** | The banner is included when **either** (a) the selection touches ayah 1 of any surah on the rendered range, **or** (b) the selection is the *first* render for a given session (i.e. user just opened the composer). The banner uses the correct localized surah name. |
| **R4 — Bismillah** | Bismillah is included whenever the banner is included for surahs other than Al-Fatihah (1) and At-Tawbah (9), matching existing mushaf convention. |
| **R5 — Preview parity** | The preview the user sees must be the same widget tree (scaled) as the exported frame. Pixel diff between preview-at-export-resolution and exported PNG must be < 1% of pixels. |
| **R6 — Safe zones** | A top safe zone of 8% (≈154px on 1920) and bottom safe zone of 14% (≈269px on 1920) is reserved on the 1080×1920 canvas. Verse text never enters these zones. Brand chrome (top bar, optional bottom badge) may. |
| **R7 — Aspect ratios** | Reel: 9:16 hard. Screenshot: variable height, fixed `0.56` width-to-height ratio (current behaviour) — preserved to keep social-aspect compatibility. |
| **R8 — Localization** | Surah names use `getSurahNameArabic` for Arabic locale, `getSurahNameEnglish` otherwise. Numeric values (juz, page, hizb if used) use Eastern-Arabic numerals in Arabic locale. |
| **R9 — Selection limits** | Selections exceeding `ShareLimits.maxVersesPerClip` are blocked with an inline reason; no silent button disabling. |
| **R10 — Screenshot selected composition** | Screenshot export must start with the Surah Header Banner, optional Bismillah per policy, then selected Quran content. It must not preserve the selected ayah's original page offset or show unrelated previous ayahs above the selected range. Preview and export must use the same selected-range composition widget. |

---

## User Experience Principles

### Composer screen

1. **One primary action at a time.** Generate → Cancel during work → Save/Share in review. Never two primaries at once.
2. **Inline reasons for disabled state.** When the primary button is disabled, a single line of `bodySmall` text below explains why.
3. **Progress is staged.** The user sees: "Capturing frames" → "Encoding video" → "Finalizing" rather than a single bar.
4. **Calm and respectful.** No bouncing animations, no celebratory micro-interactions, no emoji. Quran content sets the tone.

### Preview

5. **What you see is what you ship.** Preview frame must use the same composition widget as capture. No "demo only" placeholder.
6. **Show the safe zones during edit, hide them in review.** While composing, faint dashed borders mark the social safe zones; in review, the preview is clean.

### Review

7. **Save and Share are equal-weight on screenshots; Share dominates on reels.** Mode-aware emphasis.
8. **Edit returns to the composer with the previous selection retained.** No state loss.

---

## Accessibility Requirements

| Concern | Requirement |
|---|---|
| Touch targets | ≥ 44×44 pt (iOS) / 48×48 dp (Android) for stepper buttons, header buttons, panel buttons. |
| Reduced motion | The optional ambient orbs/shadow on the preview must respect `MediaQuery.disableAnimationsOf` and stay disabled during capture. |
| Screen reader | Stepper buttons announce "Decrease ayah from 5 to 4" / "Increase ayah". The generate button announces estimated reel duration. The progress bar announces stage transitions via live region. |
| Contrast | Selected verse text on background ≥ 4.5:1. Verse highlight band on background ≥ 3:1 luminance contrast. |
| RTL | All composer chrome respects `Directionality`. The Surah Header Banner stays RTL regardless of UI locale. |
| Localization | Arabic and English locales tested for: stepper layout, button labels (no clipping), progress label fit, banner glyph correctness. |

---

## Performance Constraints

| Constraint | Limit | Rationale |
|---|---|---|
| Live preview build | < 16ms per frame at 60fps on a Pixel 6 / iPhone 12-class device | Avoid jank while user adjusts ayah range |
| Capture frame raster | < 200ms per page on the same class | Acceptable user wait (handled offstage during generation) |
| Memory during generation | < 250MB resident during a 5-page reel capture | Headroom for FFmpeg side-by-side |
| Simultaneous mushaf trees | 1 during generation (currently 2) | Drop the live tree while offstage capture is mounted |
| Font preloading | All pages of the selected range fonts loaded **before** capture starts | Prevents the spinner flash during capture |
| Frame capture pixel size | Exact 1080×1920 (no `FittedBox(contain)` in the capture path) | Avoids fractional scaling and DPR drift |

---

## Theming Requirements

### Token migration target

Promote `VideoReelDesign` constants into the UI Kit:

| Old (literal in `video_reel_design.dart`) | New (UI Kit) |
|---|---|
| `mushafBackgroundColor: 0xFFFFF8ED` | `colorScheme.surfaceContainerLowest` (or new `tokens.mushafCanvas`) |
| `mushafTextColor: 0xF52E2116` | `readerTheme.textColor` (already exists) |
| `verseHighlightColor: 0x3DF57C00` | `colorScheme.primary.withValues(alpha: tokens.opacityHighlight)` |
| `frameTextColor`, `frameSecondaryTextColor`, `frameStrongTextColor` | `colorScheme.onSurface`, `onSurfaceVariant`, `onSurface` (with token alphas) |
| `frameAccentColor: 0xFFC5A358` | `colorScheme.primary` |
| `frameSurfaceColor: 0xFFFFF9F2` | `colorScheme.surfaceContainer` |
| `bottomBarRadius: 32` | `tokens.radiusExtraLarge` |
| `topBarTitleFontSize: 16`, `topBarMetaFontSize: 14`, `bottomBarMetaFontSize: 12` | `tokens.fontSizeBody`, `tokens.fontSizeBodySmall`, `tokens.fontSizeCaption` (verify exact names) |
| `topBarHeightFactor: 0.042` etc. | Keep as factors but move to `ShareCanvasTokens` |

### New component tokens

Introduce `TilawaShareCanvasTokens` (in `packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart`):

- `topBarHeightFactor`, `topBarMinHeight`, `topBarMaxHeight`
- `bottomBarHeightFactor`, `bottomBarRadius`, `bottomBarBorderAlpha`
- `surahHeaderToBismillahGapFactor` (with min/max clamps)
- `bismillahToTextGapFactor` (with min/max clamps)
- `safeZoneTop`, `safeZoneBottom` (fractional, default 0.08 / 0.14)
- `selectionTopAnchor` (fractional, default 0.0 — first verse aligned to the top of the content area)

---

## Surah Header Banner — Inclusion Rule (canonical)

For both renderers, decide banner inclusion as:

```
include = (selection contains ayah 1 of any surah on the rendered range)
       OR (composer is in initial state and user has not adjusted range)
```

- **Always** include Bismillah under the banner for surahs other than 1 and 9.
- **Never** show two banners stacked, even if the selection crosses two surahs (rare; use the *first* selected surah's banner).
- The banner is rendered as a **fixed top section** of deterministic height, *above* the cropped Quran content. It does not flow inline with the page.

This rule is enforced in Phase 2 (crop-and-compose). Phase 1 does not change banner behavior.

### Screenshot Header Rule

For generated Quran screenshots, the Surah Header Banner is always shown at the top of the selected-range composition for the selected surah. This is stricter than the reel policy because screenshot output is a compact standalone artifact and must identify the selected surah even when the selected range starts mid-surah. Bismillah follows the existing convention: include it under the banner for surahs other than Al-Fatihah (1) and At-Tawbah (9).

Screenshot composition must not use a translated full-page crop as its primary rendering strategy. It should build a dedicated selected-range composition:

```text
Surah Header Banner
Bismillah, when allowed by policy
Selected QCF ayah content from the top
Optional footer/branding
```

The first selected ayah content should appear immediately after the header/Bismillah spacing, subject only to typographic padding needed to avoid QCF clipping.

---

## Social-Platform Safe Zones

| Platform | Top reserve | Bottom reserve | Notes |
|---|---|---|---|
| Instagram Reels | 8% | 14% | Username, caption, like/comment overlays |
| TikTok | 6% | 18% | Username row + bottom action stack |
| YouTube Shorts | 8% | 12% | Subscribe + like buttons |

Adopt **8% top / 14% bottom** as the unified default. Verse text MUST NOT enter these zones. Brand chrome MAY (banner sits at the top; optional badge sits at the bottom).

---

## Testing Requirements

### Phase 1 (Quick UI fixes)

| Test | Purpose |
|---|---|
| Reel screen shows retry on error | Parity with screenshot screen |
| Stepper buttons are ≥ 48×48 dp | Touch target compliance |
| Invalid range shows inline reason | UX clarity |
| `MediaPreviewFrame` uses `tokens.radiusExtraLarge` | Token compliance |
| `_ReelTopBar` font sizes pull from `tokens` | Token compliance |
| Save button is filled style on screenshot mode, outlined on reel mode | Mode-aware emphasis |
| Live preview is unmounted while offstage capture is active | Single-tree invariant |

### Phase 2 (Crop-and-compose)

| Test | Purpose |
|---|---|
| Golden: `Al-Baqarah 5–8` reel — first selected verse top-anchored | R1, R2 |
| Golden: `Yasin 36–40` reel — multi-line selection top-anchored | R1, R2 |
| Golden: `Al-Kahf 1–3` reel — banner + bismillah present | R3, R4 |
| Golden: `Al-Fatihah 1–7` reel — banner present, bismillah absent | R3, R4 (Fatihah exception) |
| Golden: `An-Nas 1–6` reel — last surah, short selection | R1 |
| Pixel diff: preview-at-1080×1920 vs. captured PNG < 1% | R5 |

### Phase 3 (Single composition widget)

| Test | Purpose |
|---|---|
| `VideoComposition` rendered live and offstage produces identical raster | R5 |
| Capture path does not use `FittedBox(contain)` | Exact 1080×1920 raster |
| Live preview rebuilds < 16ms during stepper interaction | Performance |

### Phase 4 (Tokens)

| Test | Purpose |
|---|---|
| No literal hex in `video_reel_design.dart` | Token compliance |
| `flutter analyze` passes with no `avoid_hard_coded_color` warnings | Token compliance |
| Goldens pass in light, dark, and compact density | Theming |

### Phase 5 (UX upgrades)

| Test | Purpose |
|---|---|
| Range slider accepts keyboard input and accessibility focus | A11y |
| Reciter audition plays 5s sample without leaving composer | Flow |
| Stage-labelled progress bar transitions through capture/encode/finalize | Progress UX |

### Phase 6 (PictureRecorder capture, optional)

| Test | Purpose |
|---|---|
| Capture path produces identical raster vs. widget-tree capture | Equivalence gate before swap |
| Memory peak during capture < 250MB | Performance budget |

---

## Rollback Plan

### Phase 1 (Quick UI fixes)

- All changes are isolated to widget files (`composer_controls.dart`, `video_review_panel.dart`, `video_reel_composer_screen.dart`, `share_preview_widgets.dart`, `share_composer_widgets.dart`) plus the `disableBlur` toggle in `immersive_composer_scaffold.dart` consumers.
- Feature flag: none required; revert is a single PR revert.
- Token usages introduced in Phase 1 are additive (already-existing tokens) — no token surface changes.

### Phase 2 (Crop-and-compose)

- Land behind a `kReelComposerV2` boolean in `share_cubit.dart` (compile-time, not runtime). Off by default until goldens land.
- If issues found post-merge: flip the constant; the legacy `MushafPageRenderer` path is preserved for one release.

### Phase 3 (Single composition widget)

- `VideoComposition` ships alongside the existing `_VideoLivePreview` and `_OffScreenRenderers`. A second compile-time switch `kReelComposerSingleTree` selects which path runs.
- Rollback: flip the switch; both trees still in source.

### Phase 4 (Tokens)

- Token additions are non-breaking (new `TilawaShareCanvasTokens` field; old `VideoReelDesign` deleted only after all consumers migrate). Revert is a single PR revert.

### Phase 5 (UX upgrades)

- New widgets (range slider, audition button, stage progress) are additive. Old widgets remain in source for one release.

### Phase 6 (PictureRecorder, optional)

- Highest risk, gated on Phase 3. If raster equivalence test fails, do not ship — keep widget-tree capture indefinitely.

---

## Dependencies

- **Tilawa UI Kit foundation**: `tokens` (radii, spacing, fontSize, opacity), `colorScheme` extensions, density support.
- **`quran_qcf`**: `PreparedQuranPage`, `PreparedHeaderBlock`, `PreparedBismillahBlock`, `PreparedTextBlock`, `StandardQuranLayoutStrategy`, `QuranFontService`.
- **Existing share pipeline**: `ShareCubit`, `GenerateVideoUseCase`, `prepareScreenshot`, `WidgetCaptureHandle`. Surface preserved.
- **No new packages**.

---

## Success Criteria

### Phase 1 — Quick UI fixes (this phase)

- [ ] Reel composer shows a visible retry affordance when generation fails (parity with screenshot composer).
- [ ] Stepper button hit area ≥ 48×48 dp; visual size unchanged or token-driven.
- [ ] Invalid range (out-of-bounds or > `ShareLimits.maxVersesPerClip`) shows an inline reason below the stepper.
- [ ] `MediaPreviewFrame.borderRadius` is token-driven (`tokens.radiusExtraLarge`).
- [ ] `_ReelTopBar` font sizes are token-driven.
- [ ] `VideoReviewPanel` uses filled `Save` on screenshot mode and filled `Share` on reel mode.
- [ ] Live preview is unmounted while offstage capture is active (single mushaf tree during generation).
- [ ] `_ReelBottomBar` and its constants either restored (token-driven) or deleted entirely.
- [ ] `disableBlur` decision moved into the scaffold's context-aware default; both composers feel like the same product.
- [ ] All existing golden and widget tests still pass; new widget tests added per §Testing.
- [ ] No analyzer regressions.

### Phase 2 — Crop-and-compose

- [ ] `SelectionCropWindow` extracted as a pure function shared by both renderers.
- [ ] Reel selection always anchored to the top of the content area (R2).
- [ ] No transparent-text trick remaining in the reel path.
- [ ] Banner inclusion follows the canonical rule (R3, R4).
- [ ] Goldens for the five canonical scenarios pass.
- [ ] Preview-vs-export pixel diff < 1% (R5).

### Phase 3 — Single composition widget

- [ ] `VideoComposition` widget in `widgets/`, used by both live preview and offstage capture.
- [ ] No `FittedBox(BoxFit.contain)` between the capture boundary and the composition widget.
- [ ] Capture raster is exactly 1080×1920 px regardless of preview size.

### Phase 4 — Token migration

- [ ] `VideoReelDesign` deleted; all values pulled from `TilawaShareCanvasTokens` and existing `tokens`/`colorScheme`.
- [ ] Goldens pass in light, dark, and compact density.

### Phase 5 — UX upgrades

- [ ] Range slider replaces the stepper pair; keyboard and screen reader supported.
- [ ] Reciter audition plays a 5s sample inline.
- [ ] Stage-labelled progress with capture / encode / finalize transitions.
- [ ] Mode-aware Save/Share emphasis confirmed in QA.

### Phase 6 — PictureRecorder capture (optional)

- [ ] Capture raster equivalence test passes (vs. widget-tree capture).
- [ ] Memory peak under budget.
- [ ] Ship only if both gates pass; otherwise hold indefinitely.

---

## Notes

- The audit (2026-05-07) flagged that the screenshot poster's crop tightly hugs `block.painter.height`, which can clip top-side diacritics on QCF PUA glyphs. Phase 2 must extend the crop window upward by one diacritic-safety margin (a small fraction of `metrics.fontSize`, exact value to be calibrated in QA).
- The `_ReelBottomBar` decision (restore or delete) should be made before Phase 4 — it carries its own constants that would otherwise migrate to tokens without a consumer.
- Phase 6 is intentionally optional. If Phases 2–3 deliver pixel parity, a `PictureRecorder`-based capture is a nice-to-have rather than a blocker.
