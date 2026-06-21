# Tilawa feedback system

**Status:** Initial slice — `TilawaFeedbackHost` + `TilawaToast` + `TilawaFeedback.showToast`.

Tilawa uses a **native UI Kit feedback layer** instead of third-party toast
packages (`fluttertoast`, `toastification`, etc.). Feedback stays inside the
widget tree so it can read design tokens, respect RTL, scale with system text,
and clear Comfortable Reach bottom chrome.

---

## Components

| Component | Status | Role |
|-----------|--------|------|
| `TilawaFeedbackHost` | Shipped | Root overlay host — wrap `MaterialApp.builder` child |
| `TilawaToast` | Shipped | Transient success / error / warning / info toast |
| `TilawaFeedback.showToast` | Shipped | Public API for ephemeral feedback |
| `TilawaFeedbackInsets` | Shipped | Reports sticky-footer height so toasts float above CTAs |
| `TilawaFeedbackBanner` | Deferred | Persistent / actionable issues (offline, undo) |
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

### Network / domain failure — toast (banner later)

- Unexpected API errors, save failures unrelated to a specific field.
- Use `TilawaFeedbackVariant.error` (light haptic on show).
- Persistent offline/sync issues will move to `TilawaFeedbackBanner`.

### Persistent / actionable — banner (deferred)

- Undo affordances, required store updates, offline mode.
- Not `TilawaToast`; banner pushes content or uses a dedicated strip.

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

---

## Why no third-party toast packages

| Issue | Native kit |
|-------|------------|
| Cannot read `ThemeData` at render time | Built in widget tree |
| RTL / Arabic layout | `Row` + ambient `Directionality` |
| Covers sticky CTAs | `TilawaFeedbackInsets` + Comfortable Reach |
| Conflicts with form validation policy | Explicit channel rules |
| Extra dependency + skinning work | Reuses existing strip tokens |

`fluttertoast` has been **removed** from the app. Use `TilawaFeedback.showToast`
only. Do not add `toastification` or similar packages.

---

## Related

- [`tilawa_feedback_strip.dart`](../lib/src/molecules/tilawa_feedback_strip.dart) — strip primitive
- [`tilawa_form_validation.dart`](../lib/src/foundation/tilawa_form_validation.dart) — scroll/focus on submit
- [`specs/013-token-consistency-pass/spec.md`](../../../specs/013-token-consistency-pass/spec.md) — single feedback channel migration
