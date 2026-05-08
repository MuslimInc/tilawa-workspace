# Implementation Plan: Compact UI — Complete Coverage Across UI Kit

**Branch**: `007-compact-ui-coverage` | **Date**: 2026-05-04 | **Spec**: [spec.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/007-compact-ui-coverage/spec.md)

## Summary

Implement complete density awareness across all 28 component token families in the Tilawa UI Kit. 15 families gain real compact divergence while 13 remain no-op for safety. All comfortable values are preserved exactly. Touch targets never drop below 48dp.

## Technical Context

**Language/Version**: Flutter 3.x, Dart 3.x  
**Primary Dependencies**: `flutter/material.dart`, `tilawa_ui_kit` internal  
**Storage**: Token classes (immutable, const factories)  
**Testing**: Unit tests for every family (divergent + no-op)  
**Target Platform**: All (token-layer change, no platform code)  
**Performance Goals**: Zero runtime impact (const constructors, compile-time values)  
**Constraints**: Never reduce touch targets below 48dp; comfortable values must be unchanged.

## Constitution Check

- **Clean Architecture Boundaries**: PASS - Changes isolated to token layer in `foundation/component_tokens/`.
- **BLoC and GoRouter**: N/A - No state management changes.
- **Atomic Design and Tilawa UI Kit**: PASS - Pure token-layer enhancement; widgets already consume `componentTokens`.
- **Responsive and Adaptive UI**: PASS - Density is a first-class design axis alongside screen size.
- **Performance and Low Jank**: PASS - Const factories, no runtime allocation changes.
- **Structured Logging and Diagnostics**: N/A - No runtime behavior to log.
- **Testing Discipline**: PASS - 63 unit tests covering all families.
- **Safe Refactoring and Delivery**: PASS - No breaking changes; comfortable mode unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/007-compact-ui-coverage/
├── spec.md              
├── plan.md              
└── tasks.md             
```

### Source Code

```text
packages/ui_kit/lib/src/foundation/component_tokens/
├── atoms_tokens.dart           # 8 token classes (6 with density)
├── molecules_tokens.dart       # 8 token classes (all with density)
├── organisms_tokens.dart       # 6 token classes (all with density)
└── component_tokens_theme.dart # Aggregates all, passes density

packages/ui_kit/test/foundation/
└── component_tokens_density_test.dart  # 63 tests covering all families
```

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| No-op Families | Safety for touch targets | Shrinking everything would violate 48dp accessibility rule |
| Per-family Decisions | Each component has different touch/visibility tradeoffs | Uniform compact would over-shrink some, under-shrink others |

## Phase 1: Atoms (F-A)

**Files**: `atoms_tokens.dart`, `component_tokens_theme.dart`

Add `density` parameter to 6 token classes:
- **Divergent**: SheetHandle, ErrorState
- **No-op**: SectionTitle, LoadingIndicator, IconToggle, Divider

Update `TilawaComponentTokens._create()` to pass `density: density` to all 6.

## Phase 2: Molecules (F-B, F-C)

**Files**: `molecules_tokens.dart`, `component_tokens_theme.dart`

Add `density` parameter to 8 token classes:
- **Divergent (F-B)**: SegmentedControl, PermissionBanner, PrayerAlertRow
- **Divergent (F-C)**: SearchField (height stays at kMinInteractiveDimension)
- **No-op**: AlphabetScrollbar, IconActionButton, SeekBar, CountProgressRing

## Phase 3: Organisms (F-D)

**Files**: `organisms_tokens.dart`, `component_tokens_theme.dart`

Add `density` parameter to 6 token classes:
- **Divergent**: FooterBar, BottomSheetScaffold
- **No-op**: PlayerBackground, MediaPlayerBar, AdaptiveShell, ImmersiveComposer

## Phase 4: Test Coverage (F-E)

**Files**: `component_tokens_density_test.dart`

For each divergent family:
- Test comfortable equals legacy default
- Test each compact-changed field has expected new value
- Test non-changed fields are equal between modes
- Test light+dark propagation

For each no-op family:
- Single test asserting `compact == comfortable` for every field

## Phase 5: Validation

Run after each phase:
```bash
cd packages/ui_kit && flutter analyze && flutter test
```

Full validation:
```bash
cd packages/ui_kit && flutter test test/foundation/component_tokens_density_test.dart
```

## Implementation Complete

All phases implemented. 63 tests passing. Zero analyzer issues.
