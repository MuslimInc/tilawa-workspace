# Implementation Plan: Tilawa Skeleton Loading

**Branch**: `008-skeleton-loading` | **Date**: 2026-05-04 | **Spec**: [spec.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/008-skeleton-loading/spec.md)

---

## Summary

Implement a skeleton loading foundation for the Tilawa UI Kit. Start with a single reusable block component and token system, validate with comprehensive tests and goldens, then expand to patterns and app integration in later phases.

**Scope**: UI Kit foundation only for S1-A/S1-B. No app integration until S1-D.

---

## Technical Context

**Language/Version**: Flutter 3.x, Dart 3.x  
**Primary Dependencies**: `flutter/material.dart`, `tilawa_ui_kit` internal  
**Storage**: Token classes (immutable, const factories)  
**Testing**: Widget tests, golden tests, token tests  
**Target Platform**: All (UI component layer)  
**Performance Goals**: 60fps animation, minimal rebuilds, battery-aware  
**Constraints**: Respect reduced motion, never drop below 48dp touch targets, RTL-safe

---

## Constitution Check

- **Clean Architecture Boundaries**: PASS - Component isolated to `atoms/` layer
- **BLoC and GoRouter**: N/A - Pure UI component, no state management
- **Atomic Design and Tilawa UI Kit**: PASS - Follows atom/molecule/organism hierarchy
- **Responsive and Adaptive UI**: PASS - Supports density and theme changes
- **Performance and Low Jank**: PASS - Uses RepaintBoundary, optimized animations
- **Structured Logging and Diagnostics**: N/A - No runtime logging needed
- **Testing Discipline**: PASS - Golden tests for visuals, unit tests for behavior
- **Safe Refactoring and Delivery**: PASS - New component, no breaking changes

---

## Project Structure

### Documentation (this feature)

```text
specs/008-skeleton-loading/
├── spec.md              # This specification
├── plan.md              # This implementation plan
└── tasks.md             # Task checklist
```

### Source Code (Phase S1-A)

```text
packages/ui_kit/lib/src/
├── atoms/
│   ├── atoms.dart                          # Export skeleton
│   ├── tilawa_skeleton_block.dart          # Core component
│   └── tilawa_skeleton_shape.dart          # Shape enum
├── foundation/component_tokens/
│   ├── atoms_tokens.dart                   # Add TilawaSkeletonTokens
│   └── component_tokens_theme.dart         # Add skeleton field
```

### Tests (Phase S1-B)

```text
packages/ui_kit/test/
├── goldens/
│   └── atoms_goldens_test.dart             # Add skeleton goldens
├── atoms/
│   └── tilawa_skeleton_block_test.dart     # Widget tests
└── foundation/
    └── skeleton_tokens_test.dart           # Token tests
```

---

## Design Decisions

### A. Token Architecture

- **Do not** put `TextDirection shimmerDirection` inside tokens
- Tokens should not depend on runtime Directionality
- Direction resolved in widget from `Directionality.of(context)`
- Follow existing UI Kit token architecture (no new patterns)

### B. Golden Test Stability

- Golden tests render skeleton in **static mode** (`animate: false`)
- Shimmer animation must not cause flaky goldens
- Visual testing happens on static representation

### C. Reduced Motion

- Runtime behavior from `MediaQuery.disableAnimationsOf(context)`
- Not a token-only concern
- Widget checks media query, tokens provide static colors

### D. Animation Control

- `animate: true` by default
- Tests and goldens can set `animate: false`
- Respects system reduced motion setting automatically

### E. Component Scope

- Start with `TilawaSkeletonBlock` only
- Do not implement `TilawaSkeletonContainer` in S1-A unless clearly necessary
- Add pattern components (ListTile, Card) in S1-C

---

## Phase S1-A: UI Kit Foundation

### Files

1. `packages/ui_kit/lib/src/atoms/tilawa_skeleton_shape.dart`
2. `packages/ui_kit/lib/src/atoms/tilawa_skeleton_block.dart`
3. `packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart`
4. `packages/ui_kit/lib/src/foundation/component_tokens/component_tokens_theme.dart`
5. `packages/ui_kit/lib/src/atoms/atoms.dart`

### Work Items

**S1-A-001: Define `TilawaSkeletonShape` enum**
- Values: `rectangle`, `circle`, `rounded`
- Documentation for each shape use case

**S1-A-002: Add `TilawaSkeletonTokens` to atoms_tokens.dart**
- Fields: `baseColor`, `highlightColor`, `borderRadius`, `animationDuration`, `pulseDuration`
- Factory `defaults()` without a separate density axis (single comfortable-equivalent defaults; see [007 supersession](../007-compact-ui-coverage/spec.md))
- Standard `copyWith()` and `lerp()` methods

**S1-A-003: Wire tokens into `TilawaComponentTokens`**
- Add `skeleton` field to constructor
- Add to `_create()` factory
- Update `copyWith()`, `lerp()`, `==`, `hashCode`

**S1-A-004: Implement `TilawaSkeletonBlock`**
- Props: `width`, `height`, `shape`, `borderRadius`, `animate`
- Shimmer animation with `AnimationController`
- Reduced motion detection
- RTL-aware shimmer direction
- `RepaintBoundary` wrapper
- Static fallback when animation disabled

**S1-A-005: Export from atoms barrel**
- Add to `atoms.dart`

**S1-A-006: Validation**
- Run `flutter analyze` — zero issues
- Run `flutter test` — existing tests pass

---

## Phase S1-B: Tests and Goldens

### Files

1. `packages/ui_kit/test/atoms/tilawa_skeleton_block_test.dart`
2. `packages/ui_kit/test/foundation/skeleton_tokens_test.dart`
3. `packages/ui_kit/test/goldens/atoms_goldens_test.dart` (append)

### Work Items

**S1-B-001: Add widget tests**
- Renders with explicit width/height
- Supports circle shape (aspect ratio 1:1)
- Supports custom borderRadius override
- Respects `animate: false`
- Reduced motion disables shimmer

**S1-B-002: Add token tests**
- Defaults factory creates valid tokens
- `copyWith` overrides and `lerp` behave predictably
- Colors derive from ColorScheme

**S1-B-003: Add golden tests**
- Rectangle (light)
- Rectangle (dark)
- Circle/avatar (light)
- Circle/avatar (dark)
- Text line (light, dark)
- Reduced motion static (light)
- Multiple blocks composition (light)

_(Historical third golden axis “compact density” was removed with `TilawaDensity`; see [007 spec](../007-compact-ui-coverage/spec.md).)_

**S1-B-004: Generate goldens**
- Run with `--update-goldens`
- Verify macOS and CI variants
- Review images manually

**S1-B-005: Validation**
- All tests pass
- No analyzer issues

---

## Phase S1-C: Pattern Components (Later)

### Timing

Only proceed after S1-A and S1-B are reviewed and approved.

### Proposed Patterns

| Component | Purpose | Building Blocks |
|-----------|---------|-----------------|
| `TilawaSkeletonListTile` | List item placeholder | Avatar circle + 2-3 text lines |
| `TilawaSkeletonCard` | Card placeholder | Image block + title + subtitle |
| `TilawaSkeletonList` | Full list placeholder | Multiple list tiles with gap |
| `TilawaReciterCardSkeleton` | Reciter grid item | Avatar + name + count lines |
| `TilawaPrayerTimeSkeleton` | Prayer time row | Icon + time + label lines |

### Design Approach

- Each pattern composes multiple `TilawaSkeletonBlock` widgets
- Patterns accept `itemCount` for repeating structures
- Patterns support light/dark themes and responsive layout where needed
- Separate golden tests for each pattern

---

## Phase S1-D: App Integration (Later)

### Timing

Only proceed after S1-C patterns are reviewed and UI Kit skeleton foundation is stable.

### Candidate Screens

| Screen | Current Loading | Skeleton Pattern | Priority |
|--------|-----------------|------------------|----------|
| **Reciters** | Spinner | `TilawaSkeletonList` | P1 |
| **Bookmarks** | Spinner | `TilawaSkeletonListTile` | P1 |
| **Downloads** | Spinner | `TilawaSkeletonListTile` | P2 |
| **Prayer Times** | Spinner | `TilawaPrayerTimeSkeleton` | P2 |
| **Favorites** | Spinner | `TilawaSkeletonList` | P2 |

### Integration Steps (Per Screen)

1. Identify predictable layout sections
2. Design skeleton matching final layout
3. Add conditional rendering (skeleton vs content vs error)
4. Test reduced motion
5. Verify no layout shift on content load
6. Golden test if significant visual change

### Rollback per Screen

If issues arise on a specific screen:
- Revert that screen to `TilawaLoadingIndicator`
- Keep UI Kit components available for other screens
- No global rollback required

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Animation in component | Core UX value of skeleton | Static blocks don't convey "loading" |
| Reduced motion check | Accessibility requirement | Can't rely on animation alone |
| RTL direction handling | Internationalization | Hardcoded LTR breaks Arabic UX |
| Token-per-shape | Flexibility | Single token can't serve all shapes |

---

## Phase Validation

### After S1-A

```bash
cd packages/ui_kit && flutter analyze && flutter test
```

### After S1-B

```bash
cd packages/ui_kit
flutter test test/atoms/tilawa_skeleton_block_test.dart
flutter test test/foundation/skeleton_tokens_test.dart
flutter test test/goldens/atoms_goldens_test.dart
```

### Before S1-C

- [ ] Design review of pattern components
- [ ] UX approval for shimmer animation
- [ ] Accessibility review (reduced motion)

### Before S1-D

- [ ] Pattern library complete and tested
- [ ] Documentation for app developers
- [ ] Performance validation on low-end device

---

## Dependencies

- **S1-A** is independent and can start immediately
- **S1-B** depends on S1-A completion
- **S1-C** depends on S1-A and S1-B review/approval
- **S1-D** depends on S1-C completion and UX validation

---

## Implementation Complete

### S1-A/S1-B Complete Criteria

- [ ] `TilawaSkeletonBlock` implemented
- [ ] `TilawaSkeletonTokens` integrated
- [ ] All tests passing
- [ ] Golden images generated
- [ ] No analyzer issues
- [ ] Documentation complete

**Status**: PENDING — Ready to start S1-A
