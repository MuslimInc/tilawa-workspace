# Phase 2 Rollout: Adaptive Layout Constraints

## Overview
Phase 2 of the adaptive architecture rollout focused on applying `TilawaContentBounds` to core screens to enforce content max-width constraints on wide-screen devices while maintaining compact phone layouts.

## Implementation Summary

### 1. Quran Reader Screen
- **Target**: Reading area (mushaf pages).
- **Kind**: `TilawaContentKind.reader`.
- **Refinement**: Moved the bounds inside the `Listener` to ensure that full-screen touch gestures (taps for overlays, swipes for pages) still work across the entire screen width, while only the visual reading content is bounded and centered.
- **File**: `lib/features/quran_reader/presentation/screens/quran_reader_screen.dart`

### 2. Settings Screen
- **Target**: Configuration forms.
- **Kind**: `TilawaContentKind.settings`.
- **Logic**: Wrapped the `SingleChildScrollView` to center the settings groups on wide screens.
- **File**: `lib/features/settings/presentation/screens/settings_screen.dart`

### 3. Bookmarks Screen
- **Target**: List of saved bookmarks.
- **Kind**: `TilawaContentKind.media`.
- **Logic**: Wrapped the main content stack, ensuring the bottom player remains integrated with the layout while content stays bounded.
- **File**: `lib/features/bookmarks/presentation/screens/bookmarks_screen.dart`

### 4. Reciter Details Screen
- **Target**: Profile and surah list.
- **Kind**: `TilawaContentKind.media`.
- **Logic**: Wrapped the `CustomScrollView` (containing the header and surah grid/list). This ensures the hero image and surah items are centered and not overly stretched on tablets.
- **File**: `lib/features/reciters/presentation/screens/reciter_details_screen.dart`

### 5. Screenshot & Video Composers
- **Status**: Verified compliant.
- **Logic**: These screens use `ImmersiveComposerScaffold`, which already integrates `TilawaContentBounds(kind: media)` by design. No additional changes were required.

## Verification Results
- **Compact Layouts**: Verified that phone-sized layouts (width < 600px) remain unchanged with full-width content.
- **Wide Layouts**: Verified centering and max-width clamping (720px for reader, 760px for settings, 1200px for media/lists).
- **Gestures**: Confirmed that Quran reader overlays still toggle when tapping outside the bounded mushaf area.
- **Slivers**: Verified that `CustomScrollView` in `ReciterDetailsScreen` maintains its scrolling and pinning behavior within the bounded column.

## Next Steps
- Proceed to Phase 3: `MediaQuery` hygiene and typography scaling refinements.
