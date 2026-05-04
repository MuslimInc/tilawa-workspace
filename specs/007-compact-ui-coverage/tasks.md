# Tasks: Compact UI — Complete Coverage Across UI Kit

**Feature**: [Compact UI Coverage](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/007-compact-ui-coverage/spec.md)  
**Plan**: [Implementation Plan](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/007-compact-ui-coverage/plan.md)

## Implementation Strategy

This feature implements density awareness across all component token families. Already-completed families (Card, IconBox, EmptyState, Chip, GlassPanel, FeedbackStrip, SettingsGroup) are not modified. New work focuses on 21 additional families across atoms, molecules, and organisms.

---

## Phase F-A: Atoms

### Divergent Families (real compact changes)
- [x] **T001** Add `density` to `TilawaSheetHandleTokens` with `marginBottom 16→12` divergence
  - File: `packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart`
  - Verified: Comfortable values unchanged, compact reduces marginBottom

- [x] **T002** Add `density` to `TilawaErrorStateTokens` with spacing/iconSize divergence
  - File: `packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart`
  - Changes: `iconSize 80→64`, `titleSpacing 24→16`, `subtitleSpacing 12→8`, `actionSpacing 32→20`

### No-op Families (API uniform, values unchanged)
- [x] **T003** Add `density` parameter to `TilawaSectionTitleTokens` (no-op)
  - Rationale: Only field is `fontWeight`; nothing dimensional to compact

- [x] **T004** Add `density` parameter to `TilawaLoadingIndicatorTokens` (no-op)
  - Rationale: Stroke widths are display-only and already small

- [x] **T005** Add `density` parameter to `TilawaIconToggleTokens` (no-op)
  - Rationale: Total tap area is 36dp, already below 48dp guideline. Do not shrink further.

- [x] **T006** Add `density` parameter to `TilawaDividerTokens` (no-op)
  - Rationale: 1px display-only line; nothing meaningful to compact

- [x] **T007** Update `TilawaComponentTokens._create()` to pass `density` to all 6 atom families
  - File: `packages/ui_kit/lib/src/foundation/component_tokens/component_tokens_theme.dart`

---

## Phase F-B: Molecules (Low-risk Spacing)

### Divergent Families
- [x] **T008** Add `density` to `TilawaSegmentedControlTokens` with padding/radius divergence
  - Changes: `containerPadding 4→2`, `itemPadding (h:16,v:8)→(h:12,v:6)`, `containerRadius 12→10`, `itemRadius 8→6`

- [x] **T009** Add `density` to `TilawaPermissionBannerTokens` with spacing divergence
  - Changes: `padding (h:12,v:8)→(h:10,v:6)`, `borderRadius 12→10`, `iconSpacing 8→6`, `actionSpacing 8→6`

- [x] **T010** Add `density` to `TilawaPrayerAlertRowTokens` with spacing divergence
  - Changes: `verticalPadding 4→2`, `toggleSpacing 8→6`

### No-op Families
- [x] **T011** Add `density` parameter to `TilawaAlphabetScrollbarTokens` (no-op)
  - Rationale: `itemExtent 30` is already touch-marginal; tightening risks misclicks on long surah list

- [x] **T012** Add `density` parameter to `TilawaIconActionButtonTokens` (no-op)
  - Rationale: `size = kMinInteractiveDimension` (48dp) — at the floor

- [x] **T013** Add `density` parameter to `TilawaSeekBarTokens` (no-op)
  - Rationale: `touchExtent 30` already below 48dp; track is main drag affordance

- [x] **T014** Add `density` parameter to `TilawaCountProgressRingTokens` (no-op)
  - Rationale: Display-only counter ring; sizes calibrated for legibility

- [x] **T015** Update `TilawaComponentTokens._create()` to pass `density` to all 8 molecule families

---

## Phase F-C: Molecules (Form Components)

- [x] **T016** Add `density` to `TilawaSearchFieldTokens` with safe reductions
  - Changes: `borderRadius 16→12`, `contentPadding v:12→v:10`, `iconSize 18→16`, `shadowBlur 12→8`, `shadowOffset (0,4)→(0,2)`
  - Constraint: `height` stays at `kMinInteractiveDimension` (48dp)

---

## Phase F-D: Organisms

### Divergent Families
- [x] **T017** Add `density` to `TilawaFooterBarTokens` with height/padding divergence
  - Changes: `height 56→52`, `horizontalPadding 16→12`, `contentGap 12→8`

- [x] **T018** Add `density` to `TilawaBottomSheetScaffoldTokens` with padding/radius divergence
  - Changes: `topRadius 28→24`, `headerPadding (20,8,12,12)→(16,6,8,8)`, `bodyPadding 20→16`
  - Constraint: `closeButtonSize 40` stays (already below 48dp)

### No-op Families
- [x] **T019** Add `density` parameter to `TilawaPlayerBackgroundTokens` (no-op)
  - Rationale: Pure backdrop layer (cache scale, blur, overlay); no layout

- [x] **T020** Add `density` parameter to `TilawaMediaPlayerBarTokens` (no-op)
  - Rationale: Control buttons already 32-36dp; compacting would worsen accessibility

- [x] **T021** Add `density` parameter to `TilawaAdaptiveShellTokens` (no-op)
  - Rationale: App-wide bottom nav; highest-risk family. Defer until explicit nav-shell pass.

- [x] **T022** Add `density` parameter to `TilawaImmersiveComposerTokens` (no-op)
  - Rationale: Has `compactHeightBreakpoint`/`compactPanelHeightFactor` fields but those are screen-size responsive, not density-related

- [x] **T023** Update `TilawaComponentTokens._create()` to pass `density` to all 6 organism families

---

## Phase F-E: Test Coverage

### Divergent Family Tests (9 families)
- [x] **T024** Test `SheetHandle` compact divergence (marginBottom only)
- [x] **T025** Test `ErrorState` compact divergence (iconSize, all spacings)
- [x] **T026** Test `SegmentedControl` compact divergence (padding, radius)
- [x] **T027** Test `PermissionBanner` compact divergence (padding, spacing)
- [x] **T028** Test `PrayerAlertRow` compact divergence (verticalPadding, toggleSpacing)
- [x] **T029** Test `SearchField` compact divergence (borderRadius, shadow, iconSize; height unchanged)
- [x] **T030** Test `FooterBar` compact divergence (height, padding, gap)
- [x] **T031** Test `BottomSheetScaffold` compact divergence (radius, padding; closeButton unchanged)

### Pre-existing Divergent Family Tests (7 families - verified unchanged)
- [x] **T032** Confirm `EmptyState` tests pass (Phase 1C-A)
- [x] **T033** Confirm `SettingsGroup` tests pass (Phase 1A)
- [x] **T034** Confirm `IconBox` tests pass (Phase 1D-A)
- [x] **T035** Confirm `Chip` tests pass (Phase 1D-A)
- [x] **T036** Confirm `Card` tests pass (Phase 1E-A)
- [x] **T037** Confirm `GlassPanel` tests pass (Phase 1E-A)
- [x] **T038** Confirm `FeedbackStrip` tests pass (Phase 1E-A)

### No-op Family Tests (12 families)
- [x] **T039** Test `SectionTitle` compact equals comfortable (fontWeight)
- [x] **T040** Test `LoadingIndicator` compact equals comfortable (stroke widths)
- [x] **T041** Test `IconToggle` compact equals comfortable (iconSize, padding, radius)
- [x] **T042** Test `Divider` compact equals comfortable (height, thickness, opacity)
- [x] **T043** Test `AlphabetScrollbar` compact equals comfortable (all 9 fields)
- [x] **T044** Test `IconActionButton` compact equals comfortable (all 5 fields)
- [x] **T045** Test `SeekBar` compact equals comfortable (all 6 fields)
- [x] **T046** Test `CountProgressRing` compact equals comfortable (all 9 fields)
- [x] **T047** Test `PlayerBackground` compact equals comfortable (all 4 fields)
- [x] **T048** Test `MediaPlayerBar` compact equals comfortable (all 5 fields)
- [x] **T049** Test `AdaptiveShell` compact equals comfortable (all 5 fields)
- [x] **T050** Test `ImmersiveComposer` compact equals comfortable (all 6 fields)

### Infrastructure Tests
- [x] **T051** Test default constructor uses comfortable density
- [x] **T052** Test explicit comfortable equals default
- [x] **T053** Test compact stores density correctly
- [x] **T054** Test witness no-op family (divider) unchanged
- [x] **T055** Test dark theme supports density parameter
- [x] **T056** Test copyWith preserves density by default
- [x] **T057** Test copyWith can change density

---

## Phase F-F: Validation

- [x] **T058** Run `flutter analyze` in `packages/ui_kit` — No issues found
- [x] **T059** Run `flutter test` in `packages/ui_kit` — All 63 tests pass
- [x] **T060** Verify comfortable values unchanged (no byte changes to comfortable branches)
- [x] **T061** Verify no widget files modified (pure token-layer change)

---

## Dependencies

- Phase F-A (Atoms) is independent and was completed first.
- Phase F-B (Molecules) depends on F-A completion for API pattern validation.
- Phase F-C (SearchField) is independent within molecule work.
- Phase F-D (Organisms) depends on F-A and F-B patterns.
- Phase F-E (Tests) was written incrementally alongside each phase.

---

## Results

**Total Families**: 28 component token families  
**Divergent in Compact**: 15 families (9 new + 7 pre-existing)  
**No-op in Compact**: 13 families (12 new + 1 pre-existing witness)  
**Tests**: 63 unit tests, all passing  
**Analyzer**: Zero issues  
**Widget Changes**: None (pure token layer)  

**Status**: COMPLETE — Ready for Phase F-G (User Visual QA)
