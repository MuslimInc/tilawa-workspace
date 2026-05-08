# Compact UI — Complete Coverage Across UI Kit

**Spec**: [specs/007-compact-ui-coverage/spec.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/007-compact-ui-coverage/spec.md) | **Status**: Implemented  
**Plan**: [specs/007-compact-ui-coverage/plan.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/007-compact-ui-coverage/plan.md) | **Tasks**: [specs/007-compact-ui-coverage/tasks.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/007-compact-ui-coverage/tasks.md)

## Context

Compact UI is now the app default (`TILAWA_COMPACT_UI=true`). Today, 7 of 28 component token families diverge in compact mode (SettingsGroup, EmptyState, IconBox, Chip, Card, GlassPanel, FeedbackStrip). The remaining ~21 families return identical values for both modes, so compact has uneven visual reach: Cards and EmptyStates shrink, but PermissionBanner, SearchField, MediaPlayerBar, BottomSheetScaffold, etc. stay full size on the same screens. The user wants every reasonable family made density-aware before doing visual review, while:

- Preserving comfortable behavior exactly
- Never reducing interactive touch targets below 48dp
- Not touching `TilawaDesignTokens` (global tokens) yet
- Allowing high-risk components to be no-op compact when shrinking is unsafe
- Producing a complete, reviewable compact build the user can spot-check screen by screen

This plan sequences ~21 families into safe phases, names exact compact deltas, and identifies the small number that should remain no-op until visual review.

## Inventory & Decision Per Family

Already density-aware (no change): **TilawaCardTokens, TilawaIconBoxTokens, TilawaEmptyStateTokens, TilawaChipTokens, TilawaGlassPanelTokens, TilawaFeedbackStripTokens, TilawaSettingsGroupTokens.**

Decision codes:
- **COMPACT** — safe to diverge, deltas listed
- **NO-OP** — keep `defaults({density})` signature so the wiring is uniform, but return identical values; deferred until visual review or accessibility refactor
- **TOKEN REFACTOR FIRST** — widget has hardcoded sizes; refactor needed before density support is meaningful

| # | Family | File | Decision | Notes |
|---|---|---|---|---|
| **ATOMS** | | | | |
| 1 | TilawaSectionTitleTokens | atoms_tokens.dart:7 | NO-OP | Only field is `fontWeight`; nothing dimension-related to compact. Keep signature uniform. |
| 2 | TilawaSheetHandleTokens | atoms_tokens.dart:31 | COMPACT | `marginBottom 16→12`. Width/height stay (visual affordance, not interactive). |
| 3 | TilawaLoadingIndicatorTokens | atoms_tokens.dart:215 | NO-OP | Stroke widths are display-only & already small. No compact value. |
| 4 | TilawaIconToggleTokens | atoms_tokens.dart:265 | NO-OP | Total tap area today is **36dp** (`iconSize 20 + padding 8*2`), already below 48dp guideline. **Do not shrink further.** Keep no-op; flag for separate accessibility refactor outside this work. |
| 5 | TilawaDividerTokens | atoms_tokens.dart:309 | NO-OP | Just height/thickness/opacity for a 1px line. Nothing meaningful to compact. |
| 6 | TilawaErrorStateTokens | atoms_tokens.dart:442 | COMPACT | `iconSize 80→64`, `titleSpacing 24→16`, `subtitleSpacing 12→8`, `actionSpacing 32→20`. Mirrors EmptyState scaling ratios. |
| **MOLECULES** | | | | |
| 7 | TilawaAlphabetScrollbarTokens | molecules_tokens.dart:7 | NO-OP | Interactive scrollbar; `itemExtent 30` is already touch-marginal. Tightening risks misclicks on long surah list. Keep no-op. |
| 8 | TilawaIconActionButtonTokens | molecules_tokens.dart:230 | NO-OP | `size = kMinInteractiveDimension (48dp)` — at the floor. Keep no-op. |
| 9 | TilawaSegmentedControlTokens | molecules_tokens.dart:449 | COMPACT | `containerPadding all(4)→all(2)`, `itemPadding (h:16,v:8)→(h:12,v:6)`, `containerRadius 12→10`, `itemRadius 8→6`. Item still ≥ ~32dp tall once text is rendered; the control sits inline with chips, not a primary tap target. |
| 10 | TilawaSeekBarTokens | molecules_tokens.dart:539 | NO-OP | `touchExtent 30` is already below 48dp; track is the main drag affordance. Keep no-op until proper UX review. |
| 11 | TilawaSearchFieldTokens | molecules_tokens.dart:612 | COMPACT | `height` stays at `kMinInteractiveDimension` (48dp — non-negotiable). Compact only: `borderRadius 16→12`, `contentPadding v:12→v:10`, `iconSize 18→16`, `shadowBlur 12→8`, `shadowOffset Offset(0,4)→Offset(0,2)`. |
| 12 | TilawaCountProgressRingTokens | molecules_tokens.dart:716 | NO-OP | Display-only; sizes are already calibrated for the Athkar counter visual. Reducing risks loss of legibility for the count number (`fontSize 36`). Keep no-op. |
| 13 | TilawaPermissionBannerTokens | molecules_tokens.dart:859 | COMPACT | `padding (h:12,v:8)→(h:10,v:6)`, `borderRadius 12→10`, `iconSpacing 8→6`, `actionSpacing 8→6`. `iconSize 16` unchanged. Action chip lives outside the banner so this doesn't touch tap targets. |
| 14 | TilawaPrayerAlertRowTokens | molecules_tokens.dart:916 | COMPACT | `verticalPadding 4→2`, `toggleSpacing 8→6`. Toggle is the actual switch widget — Material handles min hit area itself. |
| **ORGANISMS** | | | | |
| 15 | TilawaPlayerBackgroundTokens | organisms_tokens.dart:7 | NO-OP | Pure backdrop layer (cache scale, blur, overlay). No layout. |
| 16 | TilawaFooterBarTokens | organisms_tokens.dart:66 | COMPACT | `height 56→52`, `horizontalPadding 16→12`, `contentGap 12→8`. Used in share-preview footer; not a primary nav bar. |
| 17 | TilawaMediaPlayerBarTokens | organisms_tokens.dart:147 | NO-OP | Control buttons are **already 32-36dp** (below 48dp). Compacting further would worsen accessibility; this needs a separate accessibility refactor, not a compact pass. |
| 18 | TilawaAdaptiveShellTokens | organisms_tokens.dart:315 | NO-OP | App-wide bottom nav. Touching it shifts every screen and is the highest-risk family in the kit. Defer until explicit nav-shell pass with the user. |
| 19 | TilawaImmersiveComposerTokens | organisms_tokens.dart:886 | NO-OP | Immersive overlay with its own `compactHeightBreakpoint`/`compactPanelHeightFactor` fields — those are **screen-size responsiveness**, unrelated to `TilawaDensity`. Mixing them would be confusing. Keep no-op. |
| 20 | TilawaBottomSheetScaffoldTokens | organisms_tokens.dart:1050 | COMPACT | `topRadius 28→24`, `headerPadding (20,8,12,12)→(16,6,8,8)`, `bodyPadding all(20)→all(16)`. **`closeButtonSize 40` stays** (already below 48dp; not making it worse). |
| **WIDGETS WITHOUT TOKEN CLASSES** | | | | |
| 21 | TilawaButton | tilawa_button.dart | TOKEN REFACTOR FIRST | Hardcoded `_getDimensions()` per size variant. Wraps with explicit `BoxConstraints(minHeight: 48, minWidth: 48)` so accessibility is fine. Out of scope for this pass — the dimensions object would need to become a token class. |
| 22 | TilawaTextField | tilawa_text_field.dart | TOKEN REFACTOR FIRST | No token class; reads only `radiusMedium`, `spaceMedium` from design tokens. Out of scope. |

**Summary:** 9 families gain real compact divergence (#2, #6, #9, #11, #13, #14, #16, #20, plus the 7 already done = 15 total). 11 stay no-op (#1, #3, #4, #5, #7, #8, #10, #12, #15, #17, #18, #19 — 12). 2 widgets are out of scope (#21, #22). The no-op families still get the `density` parameter wired into `defaults()` so the API is uniform and future compact work is a pure value change.

## Phased Rollout

### Phase F-A — Lowest-risk display-only atoms

Files: `atoms_tokens.dart`, `component_tokens_theme.dart`

Add `density` parameter to: SectionTitle, SheetHandle, LoadingIndicator, IconToggle, Divider, ErrorState. Real divergence in **SheetHandle** (marginBottom) and **ErrorState** (icon/spacings). Others no-op.

Update `_create()` to pass `density: density` for each. Add `copyWith`/`lerp` lines (no-op for unchanged classes — already correct).

### Phase F-B — Low-risk molecules with safe spacing

Files: `molecules_tokens.dart`, `component_tokens_theme.dart`

Add `density` to: AlphabetScrollbar, IconActionButton, SegmentedControl, SeekBar, CountProgressRing, PermissionBanner, PrayerAlertRow. Real divergence in **SegmentedControl, PermissionBanner, PrayerAlertRow**. Others no-op.

### Phase F-C — Form/picker components

Files: `molecules_tokens.dart`, `component_tokens_theme.dart`

Add `density` to **SearchField** with the strict rule that `height` remains `kMinInteractiveDimension`. Only borderRadius, contentPadding (vertical), iconSize, shadow shrink. Other tokens preserved.

### Phase F-D — Complex organisms (mostly no-op)

Files: `organisms_tokens.dart`, `component_tokens_theme.dart`

Add `density` to: PlayerBackground, FooterBar, MediaPlayerBar, AdaptiveShell, ImmersiveComposer, BottomSheetScaffold. Real divergence only in **FooterBar** and **BottomSheetScaffold**. The other 4 stay no-op intentionally.

### Phase F-E — Test coverage

Files under `packages/ui_kit/test/foundation/`:
- Extend [component_tokens_density_test.dart](packages/ui_kit/test/foundation/component_tokens_density_test.dart) with one `group(...)` per newly-divergent family asserting:
  1. `comfortable == defaults()` (no-arg)
  2. Each compact-changed field has the expected new value
  3. Non-changed fields are equal between modes
  4. Both `TilawaComponentTokens.light(density: compact)` and `.dark(density: compact)` propagate.

For no-op families, add a single test per family asserting `compact == comfortable` for every field. This documents intent so a future reader knows the no-op is deliberate, not an oversight.

### Phase F-F — Goldens (selective)

Files under `packages/ui_kit/test/goldens/`:

Generate compact goldens **only** for divergent families with widgets that meaningfully change shape:
- atoms: `tilawa_sheet_handle_compact`, `tilawa_error_state_compact`
- molecules: `tilawa_segmented_control_compact` (if a new test scaffold is needed; today there is no segmented_control golden), `tilawa_permission_banner_compact`, `tilawa_search_field_compact`
- organisms: `tilawa_share_footer_bar_compact` (if no current golden, decide whether worth adding), `tilawa_bottom_sheet_scaffold_compact` (if practical)

Skip compact goldens for: PrayerAlertRow (no widget golden today; visual delta is 2dp), and all no-op families.

Generation: `flutter test --update-goldens packages/ui_kit/test/goldens/`. Review the diffs visually before accepting.

### Phase F-G — App QA review (the user's step)

The user runs the app in compact mode (default) and visually reviews high-impact screens. Anything that doesn't look right is reported back; we tune specific token values surgically.

## Critical Files To Modify (✅ All Complete)

- [x] [packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart) — add `density` to 6 token classes (2 divergent, 4 no-op)
- [x] [packages/ui_kit/lib/src/foundation/component_tokens/molecules_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens/molecules_tokens.dart) — add `density` to 8 token classes (4 divergent, 4 no-op)
- [x] [packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart](packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart) — add `density` to 6 token classes (2 divergent, 4 no-op)
- [x] [packages/ui_kit/lib/src/foundation/component_tokens/component_tokens_theme.dart](packages/ui_kit/lib/src/foundation/component_tokens/component_tokens_theme.dart) — pass `density: density` to all 20 newly-density-aware families in `_create()`
- [x] [packages/ui_kit/test/foundation/component_tokens_density_test.dart](packages/ui_kit/test/foundation/component_tokens_density_test.dart) — 63 tests covering all families (9 divergent + 12 no-op groups)

## Patterns To Reuse

The existing density-aware classes establish the pattern. New code should match these exactly:

- **Factory shape**: see [TilawaCardTokens.defaults](packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart) — `factory ...defaults({TilawaDensity density = TilawaDensity.comfortable})`. Comfortable returns the historical const, compact returns a separate const. **Comfortable values must be byte-for-byte unchanged.**
- **No-op factory shape**: same signature, but the `if (density == compact)` branch returns *the same* values as comfortable. This is preferable to omitting the parameter — keeps the API uniform and lets the future remove the no-op without a signature change.
- **`copyWith` / `lerp`**: existing classes already implement these correctly. Adding `density` to the **token class itself** is not needed — it lives only on the parent `TilawaComponentTokens` (already there).
- **Test patterns**: copy the structure of the existing `'Card Compact Density (Phase 1E-A)'` group in [component_tokens_density_test.dart:620-661](packages/ui_kit/test/foundation/component_tokens_density_test.dart#L620-L661). Same comfortable=default check, per-field compact-change assertions, light+dark propagation tests.
- **Golden test patterns**: copy the `'TilawaCard compact'` test scaffold in [atoms_goldens_test.dart](packages/ui_kit/test/goldens/atoms_goldens_test.dart) — it wraps the widget in a `TilawaThemeFixture(density: TilawaDensity.compact)` and renders both light/dark variants. Use the same fixture, same naming convention `<widget>_compact`.

## Test Strategy

1. **Unit tests (Phase F-E)** — every newly-density-aware family gets a test group:
   - Comfortable equals legacy default
   - Compact differs in expected fields only
   - Both light/dark `TilawaComponentTokens` propagate
   - For no-op families: a single "compact equals comfortable" test that names every field, so a future engineer is forced to update the test if they decide to diverge a value
2. **Golden tests (Phase F-F)** — only for the 5–7 widgets with meaningful shape change. Skip widgets where the delta is ≤ 4dp on one axis and visually invisible at thumbnail scale.
3. **Existing tests** — no expected breakage. The 7 already-density-aware families are not touched by this work; their goldens stay valid.

## Validation Commands

Run after each phase (F-A through F-D), and full sweep before opening for visual review:

```bash
cd packages/ui_kit && flutter analyze && flutter test
cd apps/tilawa && flutter analyze && flutter test
```

Goldens-only smoke after F-F:

```bash
cd packages/ui_kit && flutter test test/goldens/
```

If goldens fail unexpectedly on a family that was supposed to be no-op, that's a bug — investigate before regenerating.

End-to-end visual check (the user, after F-G):

```bash
flutter run                                          # default → compact
flutter run --dart-define=TILAWA_COMPACT_UI=false    # comfortable for diff comparison
```

## Risk Matrix

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| Touch-target regression on a "safe" molecule | Low | High | Hard rule: SearchField height stays at `kMinInteractiveDimension`; SegmentedControl item padding bottoms out at v:6 (still ≥32dp with text); never reduce sizes already <48dp |
| Visual inconsistency between compact / non-compact families on a screen | Medium | Low | Expected — this is the whole point of the work. User will catch in Phase F-G |
| Goldens churn explodes | Low | Medium | Only generating compact goldens for 5–7 widgets, not every family. Existing 7-family goldens untouched |
| ImmersiveComposer "compact*" field names collide with `TilawaDensity.compact` semantics | Medium | Low | Documented in inventory: those fields are screen-size responsiveness, kept no-op; we add the `density` param but ignore it inside |
| Comfortable behavior subtly drifts | Low | High | Every comfortable branch must return `const`s identical to today's default. Tests in F-E assert this with `equals(defaultTokens.<field>)` |
| User sees the broad change and wants it backed out partially | Low | Medium | Each phase is independently revertable; commits map 1:1 to phases |

## Recommended Implementation Order

1. F-A (atoms, ~30 min) → analyze + test
2. F-B (molecules low-risk, ~45 min) → analyze + test
3. F-C (SearchField, ~15 min) → analyze + test
4. F-D (organisms, ~30 min) → analyze + test
5. F-E (unit tests, ~45 min) — written incrementally alongside each phase is also fine
6. F-F (goldens, ~30 min including review) — only after F-A through F-E pass
7. **STOP** — hand back to user for F-G visual QA. Do not tune values speculatively.

## Verification Checklist

Before declaring complete:

- [ ] `flutter analyze` clean in both packages
- [ ] All existing tests still pass (unchanged count)
- [ ] New unit tests pass for every newly-density-aware family
- [ ] New compact goldens render and are visually sensible
- [ ] No comfortable-mode token value changed (verify with grep diff against pre-work tokens.dart files)
- [ ] No widget files modified (this is a pure token-layer change; widgets already read `componentTokens.<family>`)
- [ ] App builds and runs in both modes:
  - `flutter run` → compact (default)
  - `flutter run --dart-define=TILAWA_COMPACT_UI=false` → comfortable
- [ ] No commits made until user reviews and approves
