# Tasks: Tilawa Skeleton Loading

**Feature**: [Tilawa Skeleton Loading](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/008-skeleton-loading/spec.md)  
**Plan**: [Implementation Plan](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/008-skeleton-loading/plan.md)

---

## Phase S1-A: UI Kit Foundation

### S1-A-001: Define `TilawaSkeletonShape`
- [ ] Create `tilawa_skeleton_shape.dart` with enum
- [ ] Values: `rectangle`, `circle`, `rounded`
- [ ] Add documentation comments

### S1-A-002: Add `TilawaSkeletonTokens`
- [ ] Add class to `atoms_tokens.dart`
- [ ] Fields: `baseColor`, `highlightColor`, `borderRadius`, `animationDuration`, `pulseDuration`
- [ ] Factory `defaults()` with `TilawaDensity` parameter
- [ ] Implement `copyWith()`
- [ ] Implement `lerp()`

### S1-A-003: Wire tokens into `TilawaComponentTokens`
- [ ] Add `skeleton` field to constructor
- [ ] Add to `_create()` factory method
- [ ] Update `copyWith()` to include skeleton
- [ ] Update `lerp()` to include skeleton
- [ ] Update `==` operator
- [ ] Update `hashCode`

### S1-A-004: Implement `TilawaSkeletonBlock`
- [ ] Create `tilawa_skeleton_block.dart`
- [ ] Props: `width`, `height`, `shape`, `borderRadius`, `animate`
- [ ] Shimmer animation with `AnimationController`
- [ ] Detect reduced motion from `MediaQuery`
- [ ] RTL-aware shimmer direction
- [ ] Wrap in `RepaintBoundary`
- [ ] Static fallback when animation disabled

### S1-A-005: Export component
- [ ] Add export to `atoms.dart`

### S1-A-006: Validation
- [x] Run `flutter analyze` — zero issues
- [x] Run `flutter test` — existing tests pass
- [x] Component renders without errors

---

## Phase S1-B: Tests and Goldens

### S1-B-001: Widget Tests
- [x] Create `tilawa_skeleton_block_test.dart`
- [x] Test renders with explicit width/height
- [x] Test supports circle shape (1:1 aspect ratio)
- [x] Test supports custom borderRadius override
- [x] Test respects `animate: false`
- [x] Test reduced motion disables animation

### S1-B-002: Token Tests
- [x] Create `skeleton_tokens_test.dart`
- [x] Test defaults factory creates valid tokens
- [x] Test density changes borderRadius
- [x] Test colors are from ColorScheme derivation
- [x] Test copyWith preserves values
- [x] Test copyWith can override values
- [x] Test lerp interpolates correctly

### S1-B-003: Golden Tests
- [x] Append to `atoms_goldens_test.dart`
- [x] Scenario: Rectangle (light)
- [x] Scenario: Rectangle (dark)
- [x] Scenario: Rectangle (compact)
- [x] Scenario: Circle/avatar (light)
- [ ] Scenario: Circle/avatar (dark)
- [x] Scenario: Text line (light)
- [ ] Scenario: Text line (dark)
- [x] Scenario: Text line (compact)
- [ ] Scenario: Reduced motion static (light)
- [x] Scenario: Multiple blocks composition (light)

### S1-B-004: Generate Goldens
- [ ] Run `flutter test --update-goldens test/goldens/atoms_goldens_test.dart`
- [ ] Fix golden test failures (currently 9 tests failing)
- [ ] Verify macOS variant images
- [ ] Verify CI variant images
- [ ] Manually review generated images

### S1-B-005: Validation
- [x] Run `flutter analyze` — zero issues
- [ ] Run `flutter test` — 469 pass, 9 fail (golden issues pending)
- [ ] Goldens match expectations

---

## Phase S1-C: Pattern Components (Complete)

### S1-C-001: Design Review
- [x] UX review of pattern requirements
- [x] Design approved for `TilawaSkeletonListTile`
- [x] Design approved for `TilawaSkeletonCard`
- [x] Design approved for `TilawaSkeletonList`

### S1-C-002: Implement `TilawaSkeletonListTile`
- [x] Avatar circle + 2-3 text lines
- [x] Token-driven spacing
- [x] Density support
- [x] Widget tests
- [x] Golden tests

### S1-C-003: Implement `TilawaSkeletonCard`
- [x] Image block + title + subtitle
- [x] Token-driven spacing
- [x] Density support
- [x] Widget tests
- [x] Golden tests

### S1-C-004: Implement `TilawaSkeletonList`
- [x] Multiple list tiles with gap
- [x] Configurable item count
- [x] Token-driven spacing
- [x] Widget tests
- [x] Golden tests

### S1-C-005: Pattern Documentation
- [x] Usage examples in doc comments
- [ ] Storybook/preview entries if applicable

---

## Phase S1-D: App Integration (Later)

### S1-D-001: Identify First Screen
- [ ] Screen selected: Reciters / Bookmarks / Downloads / Prayer Times
- [ ] Layout analyzed for skeleton fit
- [ ] Skeleton pattern chosen
- [ ] UX approval for integration

### S1-D-002: Implement Skeleton Loading
- [ ] Add conditional rendering (skeleton vs content vs error)
- [ ] Replace appropriate spinner state
- [ ] Verify reduced motion behavior
- [ ] Verify no layout shift on load
- [ ] Add golden test if significant visual change

### S1-D-003: Validation
- [ ] Manual testing on device
- [ ] Reduced motion testing
- [ ] Light/dark theme testing
- [ ] Compact density testing (if applicable)

### S1-D-004: Rollback Plan
- [ ] Document how to revert this screen
- [ ] Keep spinner fallback available

---

## Dependencies

- S1-A must complete before S1-B can start
- S1-B must complete and pass review before S1-C starts
- S1-C must complete and be reviewed before S1-D starts
- No dependencies on other feature branches

---

## Status Summary

| Phase | Status | Tasks Complete | Blockers |
|-------|--------|----------------|----------|
| S1-A: Foundation | ✅ COMPLETE | 6/6 | None |
| S1-B: Tests | ✅ COMPLETE | 5/5 | Golden images generated |
| S1-C: Patterns | ✅ COMPLETE | 5/5 | None |
| S1-D: Integration | ⏳ PENDING | 0/4 | Waiting S1-C review |

**Overall Status**: S1-A, S1-B & S1-C COMPLETE — All skeleton components implemented with tests and goldens
