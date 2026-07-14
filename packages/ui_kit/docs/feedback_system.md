# Tilawa feedback system

**Status:** `TilawaFeedbackHost` + `TilawaToast` + `TilawaFeedback.showToast` /
`TilawaFeedback.showActionable`.

Tilawa uses a **native UI Kit feedback layer** instead of third-party toast
packages (`fluttertoast`, `toastification`, etc.) or Material `SnackBar`.
Feedback stays inside the widget tree so it can read design tokens, respect
RTL, scale with system text, and clear Comfortable Reach bottom chrome.

---

## Components

| Component | Status | Role |
|-----------|--------|------|
| `TilawaFeedbackHost` | Shipped | Root overlay host — wrap `MaterialApp.builder` child |
| `TilawaToast` | Shipped | Transient success / error / warning / info toast |
| `TilawaFeedback.showToast` | Shipped | Public API for ephemeral feedback |
| `TilawaFeedback.showActionable` | Shipped | Toast with undo / retry / update actions |
| `TilawaFeedbackAction` | Shipped | Action model for actionable toasts |
| `TilawaFeedbackService` | Shipped | `GlobalKey<NavigatorState>` entry for DI layers |
| `TilawaFeedbackInsets` | Shipped | Reports sticky-footer height so toasts float above CTAs |
| `TilawaNotice` | Deferred | Inline body callouts (`TilawaFeedbackStrip` factories) |
| `TilawaInlineErrorSummary` | Exists | `TilawaFormSubmitFooter` validation summary |

---

## Channel rules

### Field validation — inline only

- Per-field errors under inputs (`TilawaTextField`, `TilawaFieldShell`).
- Footer summary via `TilawaFormSubmitFooter` / `TilawaFormValidationMessages`.
- Scroll-to-first-error + focus via `TilawaFormValidationController`.
- **Never** toast or snackbar for validation failures.

### Success confirmation — toast

- Bookmark deleted, playlist created, settings saved, copy-to-clipboard, etc.
- Use `TilawaFeedback.showToast` with `TilawaFeedbackVariant.success`.

### Destructive undo — actionable toast

- Swipe-delete bookmark, remove favorite, delete availability slot.
- Use `TilawaFeedback.showActionable` with an undo `TilawaFeedbackAction`.
- Default duration: `kTilawaUndoToastDuration` (4 s). Pass `duration: null`
  when the user must act (required app update).

### Network / domain failure — toast

- Unexpected API errors, save failures unrelated to a specific field.
- Use `TilawaFeedbackVariant.error` (light haptic on show).

### Persistent prompts — actionable toast (`duration: null`)

- Long-running prompts that need an explicit user action.
- Use `TilawaFeedback.showActionable` with `duration: null`.
- Required app updates use a full-screen forced-update gate, not a toast.

---

## Usage

### App root (required)

```dart
MaterialApp.router(
  builder: (context, child) => TilawaFeedbackHost(child: child!),
  // ...
);
```

### Show a toast

```dart
TilawaFeedback.showToast(
  context,
  message: context.l10n.bookmarkDeleted, // caller-localized
  variant: TilawaFeedbackVariant.success,
);
```

### Show undo

```dart
TilawaFeedback.showActionable(
  context,
  message: context.l10n.bookmarkDeleted,
  variant: TilawaFeedbackVariant.success,
  dedupeKey: 'bookmark-undo-$id',
  actions: [
    TilawaFeedbackAction(
      label: context.l10n.undo,
      onPressed: () => bloc.add(RestoreBookmark(...)),
    ),
  ],
);
```

### From a service (no `BuildContext` at call site)

```dart
TilawaFeedbackService.showActionable(
  AppRouter.navigatorKey,
  message: localizedMessage,
  variant: TilawaFeedbackVariant.info,
  duration: const Duration(minutes: 5),
  actions: [...],
);
```

The UI Kit does **not** depend on app `l10n`. Pass already-localized strings.

### Sticky bottom CTA

Wrap screens with a pinned footer:

```dart
TilawaFeedbackInsets(
  bottomObstruction: footerBandHeight,
  child: TilawaFormScreenScaffold(/* ... */),
);
```

`showToast` reads obstruction from the calling `BuildContext`.

---

## Visual language

Toasts reuse **`TilawaFeedbackStrip`**:

- Surface: `colorScheme.surfaceContainerHigh`
- Semantic foreground: `success` / `warning` / `error` / `onSurfaceVariant`
- Hairline border via `TilawaFeedbackStripTokens` accent opacities
- Motion: `durationFast` fade + slight upward slide — no bounce
- Shadow: `opacityShadowStrong` + `shadowOffsetMedium`
- Actions: `TextButton` at `minInteractiveDimension` (48 dp)
- Message: max **2 lines** with ellipsis; reserved 2-line slot (`reserveMessageLines`)
- Leading: icon and spinner share `leadingSlotSize` (24 dp) for stable height
- Copy: keep toast messages short (~80 characters); long errors belong inline or in dialogs

---

## Golden tests

Alchemist goldens live in `test/goldens/tilawa_toast_goldens_test.dart` with
fixtures in `test/goldens/golden_toast_fixtures.dart`.

```bash
cd packages/ui_kit
flutter test test/goldens/tilawa_toast_goldens_test.dart
flutter test test/goldens/tilawa_toast_goldens_test.dart --update-goldens
```

PNG output: `test/goldens/goldens/macos/foundation/tilawa_toast_*.png`.

---

## Queue and dedupe

- One toast visible at a time; additional requests queue FIFO.
- `dedupeKey` skips duplicate active/queued toasts.
- Actionable toast with same `dedupeKey` replaces the active toast.
- `showToast` defaults `dedupeKey` to the message string.

---

## Why no third-party toast packages or SnackBar

| Issue | Native kit |
|-------|------------|
| Cannot read `ThemeData` at render time | Built in widget tree |
| RTL / Arabic layout | `Row` + ambient `Directionality` |
| Covers sticky CTAs | `TilawaFeedbackInsets` + Comfortable Reach |
| Conflicts with form validation policy | Explicit channel rules |
| SnackBar inverse surface fights strip language | Unified `TilawaFeedbackStrip` |
| Extra dependency + skinning work | Reuses existing strip tokens |

`fluttertoast` has been **removed** from the app. Do not add `toastification`,
`ScaffoldMessenger.showSnackBar`, or similar.

---

## Related

- [`tilawa_feedback_strip.dart`](../lib/src/molecules/tilawa_feedback_strip.dart) — strip primitive
- [`tilawa_form_validation.dart`](../lib/src/foundation/tilawa_form_validation.dart) — scroll/focus on submit
- [`specs/013-token-consistency-pass/spec.md`](../../../specs/013-token-consistency-pass/spec.md) — single feedback channel migration
