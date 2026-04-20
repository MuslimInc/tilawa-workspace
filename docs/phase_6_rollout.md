# Phase 6 Rollout: ScreenUtil Retirement + RTL Test Matrix

## Overview

Phase 6 completes the responsive architecture by retiring the legacy ScreenUtil compatibility shim and ensuring the test suite covers RTL (Right-to-Left) layout scenarios. This final phase ensures the architecture is fully self-contained and tested for the app's primary language directions (Arabic RTL and English LTR).

## Goals

1. **Remove screenutil_compat.dart**: Delete the test-only compatibility layer that was never actually imported anywhere.
2. **Complete MediaQuery hygiene**: Replace remaining `MediaQuery.of(context)` calls with specific variants to prevent unnecessary rebuilds.
3. **Add RTL test matrix**: Ensure responsive layout tests run in both LTR and RTL directions.

## Changes

### 1. ScreenUtil Retirement

**File removed:** `apps/tilawa/lib/test_support/screenutil_compat.dart`

This file was a stub providing no-op implementations of ScreenUtil patterns. It was never imported by any production or test code, making it safe to delete.

**Verification:**
- Confirmed zero imports across the codebase
- `flutter analyze` passes after deletion

### 2. MediaQuery Hygiene Completion

**Pattern:** Replace `MediaQuery.of(context).property` with `MediaQuery.propertyOf(context)`

| Before | After | Rationale |
|--------|-------|-----------|
| `MediaQuery.of(context).size` | `MediaQuery.sizeOf(context)` | Narrow rebuild scope to size changes only |
| `MediaQuery.of(context).padding` | `MediaQuery.paddingOf(context)` | Narrow rebuild scope to padding changes only |
| `MediaQuery.of(context).viewInsets` | `MediaQuery.viewInsetsOf(context)` | Narrow rebuild scope to insets changes only |

**Files changed:**
- `bottom_player_widget.dart`: 3 usages migrated
- `color_picker.dart`: 2 usages migrated
- `block_picker.dart`: 1 usage migrated
- `material_picker.dart`: 1 usage migrated
- `video_reel_composer_screen.dart`: 1 usage migrated
- `reader_page_content_renderer.dart`: 1 usage migrated
- `share_audio_config_sheet.dart`: 1 usage migrated
- `video_content_renderer.dart`: 1 usage migrated
- `tilawa_app.dart`: 1 usage migrated

**Exceptions preserved:**
- `MediaQuery.of(context)` in `color_picker/hsv_picker.dart` is acceptable as it accesses multiple properties

### 3. RTL Test Matrix

**New test utilities:** `packages/ui_kit/test/rtl_test_matrix.dart`

Provides helper functions to run widget tests in both LTR and RTL directions:

```dart
/// Runs a test callback in both LTR and RTL directions.
void testInBothDirections(
  String description,
  Future<void> Function(WidgetTester tester, TextDirection direction) body,
) {
  testWidgets('$description (LTR)', (tester) async {
    await body(tester, TextDirection.ltr);
  });
  testWidgets('$description (RTL)', (tester) async {
    await body(tester, TextDirection.rtl);
  });
}

/// Pumps a widget with the specified text direction.
Future<void> pumpWithDirection(
  WidgetTester tester,
  Widget widget,
  TextDirection direction,
) {
  return tester.pumpWidget(
    Directionality(textDirection: direction, child: widget),
  );
}
```

**Test files:**
- `test/foundation/breakpoints_test.dart` — window-size resolution and
  breakpoint constants across both directions.
- `test/foundation/content_bounds_test.dart` — max-width clamping for each
  `TilawaContentKind`, the `maxWidth` override, narrow-screen fill, and
  horizontal centering under both directions.
- `test/organisms/tilawa_adaptive_shell_test.dart` — navigation pattern by
  window size (compact/medium/expanded) and rail placement in LTR vs RTL.

## Verification Results

- **Analysis:** `flutter analyze` passes with no issues attributable to this phase
- **Tests:** `flutter test` in `packages/ui_kit` — 33/33 pass, covering both LTR and RTL
- **No regressions:** No new `MediaQuery.of(context)` calls introduced

## Exit Criteria

- [x] No `screenutil_compat.dart` file exists in the repository
- [x] Zero `MediaQuery.of(context)` calls that should use specific variants
      (except where accessing multiple properties)
- [x] Responsive layout tests run in both LTR and RTL directions
- [x] `flutter analyze` passes (modulo pre-existing issues in unrelated packages)
- [x] Responsive test suite added

## Architecture Completeness

With Phase 6 complete, the responsive architecture now fully adheres to the principles outlined in `responsive_adaptive_architecture_review.md`:

✅ **Breakpoint system**: `TilawaBreakpoints` + `BuildContext` extensions
✅ **Content max-widths**: `TilawaContentBounds` with token-backed constraints
✅ **Adaptive shell**: `TilawaAdaptiveShell` with foldable support
✅ **Grid helpers**: `TilawaContentGrid` with `maxCrossAxisExtent`
✅ **Text scaling clamp**: App-wide `[1.0, 1.4]` limit
✅ **MediaQuery hygiene**: Specific `MediaQuery.*Of(context)` variants
✅ **No global scaling**: ScreenUtil fully retired
✅ **RTL support**: Directional APIs in place with an automated RTL test matrix

## Migration Reference for Future Code

### MediaQuery Access Patterns

| If you need... | Use... | Avoid... |
|----------------|--------|----------|
| Screen size | `MediaQuery.sizeOf(context)` | `MediaQuery.of(context).size` |
| Padding (notch/status bar) | `MediaQuery.paddingOf(context)` | `MediaQuery.of(context).padding` |
| View insets (keyboard) | `MediaQuery.viewInsetsOf(context)` | `MediaQuery.of(context).viewInsets` |
| Text scale | `MediaQuery.textScalerOf(context)` | `MediaQuery.of(context).textScaler` |
| Display features (foldables) | `MediaQuery.displayFeaturesOf(context)` | `MediaQuery.of(context).displayFeatures` |
| Multiple properties | `MediaQuery.of(context)` | - |

### RTL Testing

Always use the helper for responsive widgets:

```dart
await testInBothDirections('my widget adapts', (tester, direction) async {
  await pumpWithDirection(tester, MyWidget(), direction);
  // Test logic here
  expect(find.byType(MyResponsiveComponent), findsOneWidget);
});
```
