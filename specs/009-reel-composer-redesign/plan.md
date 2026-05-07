# Implementation Plan: Quran Reel & Screenshot Composer Redesign

**Branch**: `009-reel-composer-redesign` | **Date**: 2026-05-07 | **Spec**: [spec.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/009-reel-composer-redesign/spec.md)

---

## Summary

Redesign the Quran share composer family (reel + screenshot) so the exported output focuses on the selected ayah range, the preview matches the export, the surah header banner inclusion is explicit, and the feature uses Tilawa UI Kit tokens. Delivered in six phases. **Phase 1 ships only quick, low-risk UI fixes** that do not touch the render pipeline. Later phases redesign the composition strategy, unify the renderer, migrate tokens, and (optionally) move capture off the widget tree.

**Phase 1 scope (this immediate deliverable)**: visual polish + UX parity + dead-code cleanup. No render-pipeline changes.

---

## Technical Context

**Language/Version**: Flutter 3.x, Dart 3.x
**Primary Dependencies**: `flutter/material.dart`, `flutter_bloc`, `tilawa_ui_kit`, `quran_qcf`, `video_player` (review only), `ffmpeg_kit_flutter` (untouched)
**Storage**: N/A — composer is stateless beyond `ShareCubit`
**Testing**: Widget tests (existing), golden tests (added in Phase 2 onward)
**Target Platform**: iOS, Android (composer is mobile-only)
**Performance Goals**: Live preview rebuild < 16ms at 60fps; capture raster < 200ms/page; memory peak < 250MB during 5-page reel generation
**Constraints**: Respect reduced motion; touch targets ≥ 48dp; RTL-safe; locale-aware numerals; no FFmpeg pipeline changes

---

## Constitution Check

- **Clean Architecture Boundaries**: PASS — All changes confined to `apps/tilawa/lib/features/share/presentation/` and `packages/ui_kit/lib/src/`. No domain or data-layer churn.
- **BLoC and GoRouter**: PASS — `ShareCubit` surface preserved. New cubit fields are additive.
- **Atomic Design and Tilawa UI Kit**: PASS — Phase 4 promotes feature-local constants into UI Kit tokens; Phase 1 already pulls from existing tokens.
- **Responsive and Adaptive UI**: PASS — Composer continues to adapt via `ImmersiveComposerScaffold`; safe-area handling unchanged in Phase 1.
- **Performance and Low Jank**: PASS — Phase 1 actively reduces simultaneous mushaf trees during capture (one tree, not two).
- **Structured Logging and Diagnostics**: PASS — Existing log lines (`[VIDEO_GEN]`, `[SHARE_CUBIT]`) preserved.
- **Testing Discipline**: PASS — Phase 1 adds widget tests; Phase 2 onward adds goldens.
- **Safe Refactoring and Delivery**: PASS — Each phase has explicit rollback. Phases 2/3 land behind compile-time switches before flipping defaults.

---

## Project Structure

### Documentation (this feature)

```text
specs/009-reel-composer-redesign/
├── spec.md       # Feature specification
├── plan.md       # This implementation plan
└── tasks.md      # Phase-by-phase task checklist
```

### Source Code Touch List

**Phase 1 (Quick UI fixes)** — files modified:

```text
apps/tilawa/lib/features/share/presentation/
├── screens/
│   └── video_reel_composer_screen.dart       # retry on error; live-tree gating during capture
├── widgets/
│   ├── composer_controls.dart                # inline invalid-range reason
│   ├── share_composer_widgets.dart           # stepper button hit-area
│   ├── share_preview_widgets.dart            # MediaPreviewFrame radius -> token
│   ├── video_review_panel.dart               # mode-aware Save/Share emphasis
│   ├── mushaf_page_renderer.dart             # _ReelTopBar font sizes -> tokens; remove dead _ReelBottomBar OR restore
│   └── video_reel_design.dart                # delete dead bottom-bar constants if removing
packages/ui_kit/lib/src/organisms/
└── immersive_composer_scaffold.dart          # disableBlur becomes context-aware default
```

**Phase 2 (Crop-and-compose)** — additions:

```text
apps/tilawa/lib/features/share/presentation/
├── utils/
│   └── selection_crop_window.dart            # NEW — pure function extracted from share_poster_renderer.dart
└── widgets/
    ├── share_poster_renderer.dart            # consume the new pure function
    └── mushaf_page_renderer.dart             # apply crop window to the reel path
```

**Screenshot correction track (selected-range composition)** — additions:

```text
apps/tilawa/lib/features/share/presentation/
├── utils/
│   └── selected_quran_range_page.dart        # NEW — builds a synthetic PreparedQuranPage from selected QCF blocks
└── widgets/
    └── share_poster_renderer.dart            # replace crop/translate internals with selected composition
```

**Phase 3 (Single composition widget)** — additions:

```text
apps/tilawa/lib/features/share/presentation/widgets/
└── video_composition.dart                    # NEW — single 1080x1920 composition
```

**Phase 4 (Token migration)** — additions/deletions:

```text
packages/ui_kit/lib/src/foundation/component_tokens/
└── organisms_tokens.dart                     # add TilawaShareCanvasTokens
apps/tilawa/lib/features/share/presentation/widgets/
└── video_reel_design.dart                    # DELETE after consumers migrate
```

**Phase 5 (UX upgrades)** — additions:

```text
apps/tilawa/lib/features/share/presentation/widgets/
├── ayah_range_slider.dart                    # NEW — replaces AyahRangeTile
├── reciter_audition_button.dart              # NEW
└── share_progress_stages.dart                # NEW — staged progress UI
```

**Phase 6 (Optional, PictureRecorder capture)**:

```text
apps/tilawa/lib/features/share/data/services/
└── picture_recorder_capture_service.dart     # NEW — gated behind kCaptureViaPictureRecorder
```

---

## Design Decisions

### A. Phase 1 keeps the render pipeline untouched

The audit found render-pipeline issues (transparent-text trick, capture-time `FittedBox`, banner rule), but those changes are large and risky. Phase 1 deliberately avoids them. The user's directive is "before starting Phase 1, update the spec kit docs" — this plan reflects exactly that scoping: Phase 1 = polish, Phase 2 = pipeline.

### A2. Screenshot selected-range composition correction

The screenshot path is no longer allowed to behave as a crop of the original Mushaf page. `SharePosterRenderer` remains the public source-of-truth widget for preview and export, but its internals switch to a selected-range composition. Phase S1 builds a synthetic `PreparedQuranPage` from public QCF prepared blocks:

1. prepend `PreparedHeaderBlock` for the selected surah;
2. prepend `PreparedBismillahBlock` for surahs other than 1 and 9;
3. append only text blocks whose metadata intersects the selected ayah range;
4. render via `PageContent` prepared mode with `showSpecialBlocks: true`;
5. avoid `OverflowBox` + `Transform.translate` and avoid `verseTextColor` so the full-page highlight path does not re-enter.

Phase S1 is line/block-granular. If a selected range starts or ends in the middle of a QCF line that also contains adjacent ayahs, exact word-level clipping requires a small public `quran_qcf` API that prepares selected ranges using package-internal span logic. That is Phase S2 and should not duplicate QCF shaping code in the app layer.

### B. Stepper hit-area without visual change

Stepper buttons stay visually 36×36 (matches the rest of the app's compact density), but the tappable area expands to 48×48 via a transparent `SizedBox`/`Padding` wrapper. This avoids visual regression and a token churn.

### C. Mode-aware Save/Share emphasis

`VideoReviewPanel` accepts a new `ShareMode` enum (`screenshot` / `reel`). On screenshot, `Save` is filled, `Share` is filled tonal. On reel, `Share` is filled, `Save` is outlined. Edit stays outlined in both. The component remains generic; the call site selects the mode.

### D. `disableBlur` becomes a context-aware default

Today the reel composer hardcodes `disableBlur: true`. The screenshot composer doesn't. Make the scaffold default to `disableBlur` based on whether the immersive content is media (image/video) vs. UI. Specifically: if the `background` widget reports media intent (a new `BackgroundIntent` enum on `ImmersiveComposerScaffold`), default blur off; otherwise on. Both composers will pass the appropriate intent and look consistent.

### E. `_ReelBottomBar` decision

Audit flagged `_ReelBottomBar` as commented-out dead code with live tokens. Decision for Phase 1: **delete the dead code** (constants + class + import). If the design later wants page badge + hizb chrome, it ships in Phase 4 as a token-driven organism. Removing dead code is a clear win and avoids carrying constants we don't use.

### F. Live tree unmounting during capture

`video_reel_composer_screen.dart` currently keeps `_VideoLivePreview` mounted while `_OffScreenRenderers` is mounted. Phase 1 makes the live preview render `SizedBox.shrink()` (or a static "Generating…" placard with the staged progress label) while `state.status == capturing || generating`. Reduces simultaneous mushaf trees from 2 → 1.

### G. Inline invalid-range reason

The current `ComposerControls` only shows `errorMessage` when `state.status == ShareStatus.error`. Add a separate `rangeIssue` derivation in the screen — computed locally, not from the cubit — and surface it as `bodySmall` text below the stepper card. Sources: `from > to`, `to - from + 1 > maxVersesPerClip`, `to > maxAyah`. No cubit changes.

### H. Retry parity on the reel screen

The screenshot screen's `ScreenshotComposerControls` has `primaryLabel: state.status == error ? retry : shareScreenshot`. Mirror this in `ComposerControls`: when `state.status == ShareStatus.error`, swap the primary button label/icon to "Retry". Tapping retry calls `_handleGenerateVideo` again with the current state.

### I. Token wiring for `_ReelTopBar`

Replace literal `fontSize: 16/14/12` with `theme.textTheme.titleSmall?.fontSize` and `bodySmall?.fontSize` (or, if the Tilawa typography exposes named sizes, those). Pull weights from `tokens` if a weight scale exists; otherwise leave `FontWeight.w600` as a Phase 4 followup.

### J. `MediaPreviewFrame` radius

`borderRadius: 34` becomes `tokens.radiusExtraLarge`. The outer `TilawaCard.borderRadius: 34` matches; verify token value is close enough that there's no visible regression. If `tokens.radiusExtraLarge` is materially different, fall back to a feature-local override and flag for design.

### K. No cubit surface changes in Phase 1

`ShareCubit`, `ShareState`, `ShareStatus`, and the use cases are all untouched in Phase 1. Phase 1 is a pure presentation-layer cleanup.

---

## Phase Roadmap

| Phase | Goal | Risk | Behind a flag? | Goldens? |
|---|---|---|---|---|
| **1** | Quick UI fixes — retry parity, hit-area, inline reason, token wiring, dead code, single tree during capture | Low | No | Existing tests only |
| **S1** | Screenshot selected-range composition — banner first, selected QCF blocks from top, no full-page crop | Medium | No | Widget tests first |
| S2 | Precise screenshot mid-line filtering via quran_qcf selected-range preparation API if S1 line granularity leaks adjacent ayahs | Medium-high | No | Yes |
| 2 | Crop-and-compose — `SelectionCropWindow` shared, reel top-anchored, banner rule explicit | Medium | `kReelComposerV2` | Yes (5 scenarios) |
| 3 | Single composition widget — preview and capture share one widget tree | Medium | `kReelComposerSingleTree` | Yes (preview-vs-capture pixel diff) |
| 4 | Token migration — delete `VideoReelDesign`, introduce `TilawaShareCanvasTokens` | Low | No | Yes (light/dark/compact) |
| 5 | UX upgrades — range slider, reciter audition, staged progress, mode-aware emphasis confirmed | Medium | No | Optional |
| 6 | PictureRecorder capture (optional) | High | `kCaptureViaPictureRecorder` | Yes (raster equivalence) |

Each phase is a separate PR. Phases 2 and 3 ship behind compile-time switches and only flip on once goldens land.

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Phase 1 token swap (radius) creates a visible regression on review screen | Low | If `tokens.radiusExtraLarge` materially differs from 34, leave a literal with a Phase 4 followup token. |
| Live-tree unmounting reveals a layout assumption (e.g. cubit reads tree state during transition) | Low | The cubit reads `state.videoPageSpecs`, not the widget tree. Capture handles are decoupled. Verified during planning. |
| Deleting `_ReelBottomBar` removes a feature design wants back | Low | Decision is documented in §E; design can request re-introduction in Phase 4 as a token-driven organism. |
| Stepper hit-area expansion overlaps adjacent touch targets | Low | Wrap in `Listener` with `behavior: opaque` only on the visual square; rely on Material's hit-test extension via `IconButton` or a `Padding` wrapper. Verify no overlap in widget test. |
| `disableBlur` context-aware default ships in `ui_kit`, breaks an unrelated consumer | Low | Add a new optional `BackgroundIntent` parameter; preserve existing default behavior when unspecified. The reel/screenshot composers explicitly opt in. |

---

## Definition of Done — Phase 1

- All Phase 1 tasks in `tasks.md` are checked.
- `flutter analyze` is clean.
- All existing widget tests pass.
- New widget tests for retry parity, hit-area, inline reason, mode-aware Save/Share, and live-tree gating pass.
- `_ReelBottomBar` and `videoReelDesign.bottomBar*` constants are deleted.
- Manual smoke test on iPhone 12 + Pixel 6 in Arabic and English locales:
  - Generate reel for `Al-Baqarah 5–8`, succeed and review.
  - Trigger an error (turn off network or set an unreachable reciter URL), see retry.
  - Set range to exceed `maxVersesPerClip`, see inline reason.
  - Verify only one mushaf tree is mounted during capture (use widget inspector).
- PR description includes screenshots before/after for both composers in light + dark.
- Spec is referenced from PR description.
