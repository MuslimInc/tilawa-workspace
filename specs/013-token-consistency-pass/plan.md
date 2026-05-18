# Plan: Token Consistency Pass

**Feature Branch**: `013-token-consistency-pass`
**Created**: 2026-05-15

## Diagnosis (snapshot from audit)

| Anti-pattern | Hits in `apps/tilawa/lib/features` | Notes |
| ------------ | ----------------------------------- | ----- |
| `Duration(milliseconds: …)` literals | 52 | UI durations only; service/bootstrap timers stay literal. |
| `fontSize:` literals inside `TextStyle(...)` | ~67 | Concentrated in Quran reader theme, prayer-times screen, share composer. |
| `SnackBar(...)` usage | 6 files | Mixed with `ToastUtils.show*`. |
| `IconButton(...)` | 10+ files | 6 lack `tooltip:`/Semantics. |
| `GestureDetector(onTap:)` | 8 files | Several wrap visible cells without ripple feedback. |
| Hard-coded system-bar `Color(0x00000000)` | 1 file | Quran reader screen. |

## Execution order

Each sub-task is mechanical and independently testable. I'll commit logical batches (motion, type, feedback, icon-buttons, ripple, system bars) and re-run `dart analyze` between them.

### 1. Motion tokens
Walk every `Duration(milliseconds: N)` site in `apps/tilawa/lib/features/`. Replace with:
- `tokens.durationFast` (200 ms) for hovers, switches, icon flips.
- `tokens.durationMedium` (400 ms) for transitions, sheet entrances.
- `tokens.durationSlow` (600 ms) for hero / page reveals.

Sites with non-standard durations (e.g. `850 ms`) either move to a documented local `static const` or get aligned to the nearest token. Comments left where a literal must stay (controller init in `initState`).

### 2. Type tokens
Replace every `style: TextStyle(fontSize: N, …)` in product widgets with `style: theme.textTheme.bodyMedium?.copyWith(...)` (or the closest variant). Decision rule:
- `< 12` → `labelSmall`
- `12` → `labelMedium`
- `13–14` → `bodySmall`
- `15–16` → `bodyMedium`
- `17–18` → `titleSmall`
- `20+` → `titleMedium`

Exclude `quran_reader_theme.dart` (feature palette).

### 3. Feedback tokens
Replace `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)))` with:
- `ToastUtils.showSuccessToast(msg)` for success paths.
- `ToastUtils.showErrorToast(msg)` for failures.
- `ToastUtils.showToast(msg: msg)` for neutral confirmation.

If a snackbar has an action (e.g. "Undo"), leave it and add a comment explaining the in-context undo is intentional. None expected in this codebase based on the audit.

### 4. Icon-button consistency
Two-pass approach:
- Pass A — add `tooltip:` (or wrap in `Semantics(button: true, label: ...)`) to every bare `IconButton(...)` that has no a11y affordance. Minimal-invasive fix.
- Pass B — where the button is a one-off action that the kit already covers, swap to `TilawaIconActionButton`.

This keeps Pass A safe and isolated; Pass B can land in a separate commit if any goldens drift.

### 5. Touch-feedback ripples
Replace `GestureDetector(onTap: f, child: visible)` with the appropriate kit primitive:
- Row inside a card → `TilawaCard(onTap: f, child: …)`.
- Standalone tappable element → `Material(color: Colors.transparent, child: InkWell(onTap: f, …))`.
- Non-visible region (drag-to-dismiss, tap-outside-to-close) → keep as `GestureDetector`.

### 6. Quran-reader system bars
Replace the three `Color(0x00000000)` in [quran_reader_screen.dart:291-295](apps/tilawa/lib/features/quran_reader/presentation/screens/quran_reader_screen.dart#L291) with theme-driven colours so the status bar / nav bar match the page background regardless of OEM launcher.

## Risks

- **Goldens drift**: motion changes affect implicit animations inside molecule goldens. Mitigation: regenerate only the snapshot files that diff < 1 % pixel-wise.
- **AnimationController.duration in initState**: theme isn't reachable. Mitigation: document the case explicitly with an inline comment; do not introduce a fragile `addPostFrameCallback` workaround.
- **Snackbar→toast removes Material undo affordance**: confirmed no snackbar in the audit uses an action button. If one shows up, leave it.
- **IconButton→TilawaIconActionButton in `AppBar.actions`**: prior pass deliberately skipped this. Keep skipping in Pass B — only migrate IconButton sites *outside* `AppBar.actions`.

## Verification gates

After each batch:
1. `dart analyze` in `apps/tilawa` and `packages/ui_kit`.
2. `flutter test` in `packages/ui_kit` (494 expected green).
3. Spot-check affected screen if a golden regenerates.
