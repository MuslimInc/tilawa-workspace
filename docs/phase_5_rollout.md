# Phase 5 Rollout: Grid Helper Migration

## Overview

Phase 5 migrates manual grid column calculations to the `TilawaContentGrid` helper, eliminating `crossAxisCount` branching logic and adopting `maxCrossAxisExtent` for responsive column determination.

## Goal

Replace manual breakpoint-based column counting with automatic column calculation based on target item width. This ensures grids behave correctly across all device sizes without per-feature breakpoint logic.

## Architecture Principle

**Before (Manual):**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final crossAxisCount = constraints.maxWidth >= 980
        ? 3
        : constraints.maxWidth >= 680
            ? 2
            : 1;
    return GridView.count(crossAxisCount: crossAxisCount, ...);
  },
)
```

**After (Automatic):**
```dart
TilawaContentGrid(
  targetItemExtent: 280,  // Max width per item
  childAspectRatio: 3 / 4,
  itemBuilder: ...,       // Columns = availableWidth / targetItemExtent
)
```

## Files Changed

### 1. AthkarCategoriesScreen
**File:** `apps/tilawa/lib/features/athkar/presentation/screens/athkar_categories_screen.dart`

**Change:** Replace fixed 2-column grid with `TilawaContentGrid` using `targetItemExtent: 180`.
- Fixed `crossAxisCount: 2` → `targetItemExtent: 180`
- Automatically shows 2 columns on phones, 3-4 on tablets
- Maintains 0.9 child aspect ratio

### 2. PrayerTimesGrid
**File:** `apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_times_grid.dart`

**Change:** Replace manual column calculation with `maxCrossAxisExtent`.
- Manual breakpoints (980/680/else) for 4/3/2 columns → `maxCrossAxisExtent: 160`
- Maintains dynamic height calculation for text scaling
- Preserves RTL-aware item ordering

### 3. RecitersScreen
**File:** `apps/tilawa/lib/features/reciters/presentation/screens/reciters_screen.dart`

**Change:** Simplify `_ReciterGridView` to use `TilawaContentGrid`.
- Complex 3-tier breakpoint logic (980/680/else) → `targetItemExtent: 220`
- `SliverGridDelegateWithFixedCrossAxisCount` → `TilawaContentGrid`
- `_ReciterGridView.crossAxisCount` parameter removed
- Maintains `mainAxisExtent: 104` for card height

## Verification Results

- **Compact (phone):** Grids show 1-2 columns as appropriate
- **Medium (foldable portrait):** Grids show 2-3 columns
- **Expanded (tablet):** Grids show 3-4+ columns
- **No layout shifts:** Column transitions happen at natural breakpoints
- **Performance:** No `LayoutBuilder` rebuild churn on minor size changes

## Migration Pattern Reference

| Scenario | Before | After |
|----------|--------|-------|
| Fixed 2-col grid | `crossAxisCount: 2` | `TilawaContentGrid(targetItemExtent: 180)` |
| Breakpoint branching | `LayoutBuilder` with width checks | `TilawaContentGrid` with `targetItemExtent` |
| Dynamic item height | Compute in `LayoutBuilder` | Set `mainAxisExtent` directly on grid |
| Sliver grid | `SliverGrid` with delegate | Wrap with `SliverToBoxAdapter` + `TilawaContentGrid` |

## Exit Criteria

- No feature uses manual `crossAxisCount` branching
- All grids use `maxCrossAxisExtent` via `TilawaContentGrid`
- `flutter analyze` passes
- Manual verification on phone + tablet shows correct column counts
