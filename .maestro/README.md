# Maestro E2E flows (Tilawa)

## Prerequisites

1. App installed as `com.tilawa.app` on a device or emulator.
2. **One-time setup:** launch the app manually, complete onboarding, and sign in
   with Google so the main shell (`reciters_tab`) is reachable.
3. Run flows with `launchApp: clearState: false` so auth and onboarding stay
   completed (all flows except `splash_screen.yaml`).

## Run

```bash
maestro test .maestro/reciters_search.yaml --device emulator-5554
maestro test .maestro/reciters_browse.yaml .maestro/reciters_search.yaml \
  .maestro/reciters_favorites.yaml .maestro/reciters_rtl.yaml \
  .maestro/reciters_alphabet_scrollbar.yaml \
  --device emulator-5554
maestro test .maestro/reciters_alphabet_scrollbar.yaml \
  .maestro/reciters_alphabet_scrollbar_rtl.yaml \
  --device emulator-5554
```

## Subflows

| File | Purpose |
|------|---------|
| `subflows/ensure_main_shell.yaml` | Reach main shell after launch |
| `subflows/ensure_tilawa_card_demo.yaml` | Settings → TilawaCard nested tap demo |
| `subflows/ensure_reciters_alphabet.yaml` | Reciters loaded + A–Z rail visible |
| `subflows/ensure_reciters_screen.yaml` | Open Reciters tab + dismiss permissions |
| `subflows/alphabet_scrub_gestures.yaml` | Tap/scrub/drift off-rail while selecting |
| `subflows/alphabet_deselect.yaml` | Double-tap same letter to deselect |
| `subflows/alphabet_filter_chip.yaml` | Hide rail → chip → restore rail → clear chip |
| `subflows/alphabet_reset_filters.yaml` | Clear stale filters before scenarios |
| `subflows/alphabet_clear_all.yaml` | Search + letter → Clear all |
| `quran_player/subflows/dismiss_permissions.yaml` | Android permission dialogs |
| `quran_player/subflows/start_playback.yaml` | Open reciter 10, play surah 001 |
| `quran_player/subflows/expand_player.yaml` | Expand mini-player |

Focused mini-player flows:

| File | Purpose |
|------|---------|
| `quran_player/quran_player_mini_open.yaml` | Mini appears → tap expand → collapse → mini |
| `quran_player/quran_player_mini_dismiss.yaml` | Close + swipe-down dismiss; mini reopens on playback |
| `quran_player/quran_player_reexpand.yaml` | Expand → collapse → re-expand cycle |

Subflows include `appId: com.tilawa.app` (required by Maestro 2.5+).

## TilawaCard nested tap (debug demo)

**UX rule:** Nested controls inside a tappable card own their interaction area.
Enabled controls handle their own action; disabled controls are dead zones. The
parent card should only navigate from blank or non-interactive card areas.

Press-scale feedback is covered by widget tests (`tilawa_card_test.dart`); these
Maestro flows assert observable tap routing only.

| File | Scenario |
|------|----------|
| `tilawa_card_nested_enabled_control.yaml` | Play / delete / favorite → nested result, not parent |
| `tilawa_card_nested_disabled_control_dead_zone.yaml` | Disabled control → stays `idle` |
| `tilawa_card_blank_area_parent_navigation.yaml` | Blank body → `parent navigated` |
| `tilawa_card_decorative_area_parent_navigation.yaml` | InkWell(null) / GestureDetector → parent |

**Demo screen:** Settings → Developer → *TilawaCard nested tap demo* (debug /
profile builds only). Route: `/debug/tilawa-card`.

**Subflow:** `subflows/ensure_tilawa_card_demo.yaml` (after `ensure_main_shell`).

**Semantics ids:** `apps/tilawa/lib/features/ui_kit_debug/tilawa_card_demo_semantics_ids.dart`

```bash
maestro test .maestro/tilawa_card_nested_enabled_control.yaml \
  .maestro/tilawa_card_nested_disabled_control_dead_zone.yaml \
  .maestro/tilawa_card_blank_area_parent_navigation.yaml \
  .maestro/tilawa_card_decorative_area_parent_navigation.yaml \
  --device emulator-5554
```

Requires a signed-in session (`launchApp: clearState: false`) like other shell
flows. Install a **debug** or **profile** build — the demo route redirects to
home in release mode.

## Reciters alphabet index (Android-style scrubber)

| File | Purpose |
|------|---------|
| `reciters_alphabet_scrollbar.yaml` | Full LTR coverage via subflows below |
| `reciters_alphabet_scrollbar_rtl.yaml` | Same scenarios, RTL layout (rail on leading edge) |

### Scenario coverage

| Scenario | Subflow |
|----------|---------|
| Rail visible after data load + toggle | `ensure_reciters_alphabet` |
| Tap top / bottom / middle of rail | `alphabet_scrub_gestures`, `alphabet_filter_chip` |
| Scrub down / up through index | `alphabet_scrub_gestures` |
| Long press-drag through full track | `alphabet_scrub_gestures` |
| Finger drifts off rail while scrubbing | widget tests (Maestro cannot assert mid-gesture) |
| Double-tap same letter → deselect | `alphabet_deselect` |
| Hide rail → letter filter chip persists | `alphabet_filter_chip` |
| Re-show rail → chip hides, selection kept | `alphabet_filter_chip` |
| Clear letter via filter chip | `alphabet_filter_chip` |
| Search + letter → Clear all | N/A — search hides letter rail |
| Favorites + letter → Clear all | `alphabet_clear_all` |

Run LTR and RTL **one at a time** on the same device (parallel runs interfere):

```bash
maestro test .maestro/reciters_alphabet_scrollbar.yaml --udid emulator-5554
maestro test .maestro/reciters_alphabet_scrollbar_rtl.yaml --udid emulator-5554
```

Overlay bubble during active press is covered by widget tests
(`tilawa_alphabet_scrollbar_test.dart`); Maestro cannot assert mid-gesture.

Identifiers: `reciter_semantics_ids.dart` (`reciters_alphabet_scrollbar`,
`reciters_alphabet_letter_selected`, `reciters_letter_filter_chip`,
`reciters_clear_all_filters`).

## Quran player UX regression (planned)

After Phase B device QA, extend flows to guard the root-overlay architecture:

| Check | Intent |
|-------|--------|
| Expand from reciter detail | `/player` push; shell stays mounted |
| Collapse via back / drag | `pop`; no white flash between surfaces |
| Bottom nav | Hidden or dimmed per chrome policy during expanded |
| Rapid expand/collapse | No stuck phase; mini player recovers |

See `docs/architecture/player-migration-roadmap.md` for the full QA checklist.
Architecture: `docs/architecture/player-entry-pipeline.md`.
