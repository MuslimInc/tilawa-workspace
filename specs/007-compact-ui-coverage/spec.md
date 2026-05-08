# Feature Specification: Compact UI — Complete Coverage Across UI Kit

**Feature Branch**: `007-compact-ui-coverage`  
**Created**: 2026-05-04  
**Status**: Completed  
**Input**: [docs/update-direction-i-want-clever-moonbeam.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/docs/update-direction-i-want-clever-moonbeam.md)

## Context

Compact UI is the app default (`TILAWA_COMPACT_UI=true`). Prior to this work, only 7 of 28 component token families diverged in compact mode, creating uneven visual density across screens. This feature implements complete density awareness across all reasonable component families while preserving comfortable behavior and maintaining touch targets above 48dp.

---

## User Scenarios & Testing

### User Story 1 - Consistent Compact Visual Density (Priority: P1)

As a user with the compact UI preference enabled, I want all UI components to have consistent spacing and sizing so that the interface feels cohesive and professional rather than a mix of compact and full-size elements.

**Why this priority**: Visual inconsistency between compact and non-compact families on the same screen creates a jarring, unfinished appearance.

**Independent Test**: Enable compact mode and navigate through prayer times, audio player, and settings screens. All components should have proportionally reduced padding and spacing.

**Acceptance Scenarios**:

1. **Given** compact mode is enabled, **When** viewing any screen with cards, empty states, and buttons, **Then** all components have consistent reduced spacing (no full-size elements mixed with compact ones).
2. **Given** compact mode is enabled, **When** interacting with segmented controls and search fields, **Then** the reduced padding is visually apparent but touch targets remain usable.

---

### User Story 2 - Preserved Touch Accessibility (Priority: P1)

As a user with accessibility needs or on a small device, I want interactive elements to remain tappable even in compact mode so that I don't struggle to hit small targets.

**Why this priority**: Compact should not mean inaccessible. Touch targets must remain at or above 48dp.

**Independent Test**: Verify via accessibility inspector that all interactive elements maintain minimum touch targets.

**Acceptance Scenarios**:

1. **Given** compact mode is enabled, **When** viewing icon action buttons and seek bars, **Then** their sizes remain unchanged (already at minimum safe size).
2. **Given** compact mode is enabled, **When** using the search field, **Then** the height remains at `kMinInteractiveDimension` (48dp) despite other reductions.

---

### User Story 3 - Seamless Comfortable Mode (Priority: P2)

As a user who prefers the original comfortable UI, I want the option to disable compact mode and see the original spacing so that I can choose my preferred density.

**Why this priority**: User preference and accessibility options should always be preserved.

**Independent Test**: Run app with `TILAWA_COMPACT_UI=false` and verify all components use original comfortable spacing.

**Acceptance Scenarios**:

1. **Given** comfortable mode is enabled, **When** viewing any screen, **Then** all component spacing matches pre-compact-UI values exactly.
2. **Given** comfortable mode is enabled, **When** comparing to compact mode screenshots, **Then** the difference is visually apparent with comfortable having more breathing room.

---

## Requirements

### Functional Requirements

- **FR-001**: All 28 component token families must accept a `density` parameter in their `defaults()` factory.
- **FR-002**: 15 families must have real compact divergence (smaller padding, spacing, or sizes).
- **FR-003**: 11 families must remain no-op in compact (API uniform but values unchanged for safety).
- **FR-004**: Comfortable mode values must be byte-for-byte identical to pre-implementation defaults.
- **FR-005**: No interactive touch target may drop below 48dp in compact mode.
- **FR-006**: All families must have unit test coverage asserting compact/comfortable behavior.

### Component Inventory

**Already density-aware (7 families) - no changes:**
- TilawaCardTokens, TilawaIconBoxTokens, TilawaEmptyStateTokens, TilawaChipTokens
- TilawaGlassPanelTokens, TilawaFeedbackStripTokens, TilawaSettingsGroupTokens

**Phase F-A - Atoms (2 divergent, 4 no-op):**
| Family | Decision | Compact Changes |
|--------|----------|-----------------|
| SheetHandleTokens | Divergent | `marginBottom 16→12` |
| ErrorStateTokens | Divergent | `iconSize 80→64`, spacing reductions |
| SectionTitleTokens | No-op | Only fontWeight field |
| LoadingIndicatorTokens | No-op | Display-only, already small |
| IconToggleTokens | No-op | Already 36dp (below 48dp, don't worsen) |
| DividerTokens | No-op | 1px line, nothing to compact |

**Phase F-B - Molecules (3 divergent, 5 no-op):**
| Family | Decision | Compact Changes |
|--------|----------|-----------------|
| SegmentedControlTokens | Divergent | padding, radius reductions |
| PermissionBannerTokens | Divergent | padding, spacing reductions |
| PrayerAlertRowTokens | Divergent | verticalPadding, spacing |
| AlphabetScrollbarTokens | No-op | 30dp already touch-marginal |
| IconActionButtonTokens | No-op | 48dp at floor |
| SeekBarTokens | No-op | 30dp touchExtent, track is main affordance |
| CountProgressRingTokens | No-op | Display-only, calibrated for legibility |
| SearchFieldTokens | Divergent (F-C) | borderRadius, shadow, iconSize (height stays 48dp) |

**Phase F-D - Organisms (2 divergent, 4 no-op):**
| Family | Decision | Compact Changes |
|--------|----------|-----------------|
| FooterBarTokens | Divergent | `height 56→52`, padding/gap |
| BottomSheetScaffoldTokens | Divergent | radius, padding (closeButton 40dp stays) |
| PlayerBackgroundTokens | No-op | Pure backdrop, no layout |
| MediaPlayerBarTokens | No-op | Buttons 32-36dp, don't worsen |
| AdaptiveShellTokens | No-op | App-wide nav, high-risk |
| ImmersiveComposerTokens | No-op | Fields are screen-size responsive, not density |

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: All 28 component families have `density` parameter in `defaults()` factory.
- **SC-002**: All comfortable values match pre-implementation defaults exactly.
- **SC-003**: 63 unit tests pass covering all divergent and no-op families.
- **SC-004**: `flutter analyze` reports zero issues in `packages/ui_kit`.
- **SC-005**: No widget files modified (pure token-layer change).

### Quality Gates

- No touch target below 48dp in compact mode.
- Visual consistency across all screens in compact mode.
- Comfortable mode unchanged and fully functional.

---

## Assumptions

- Density awareness is implemented at the token layer; widgets already read `componentTokens.<family>`.
- No-op families are documented with rationale for future maintainers.
- Test coverage prevents accidental divergence in no-op families.
