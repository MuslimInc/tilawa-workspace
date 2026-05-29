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
  --device emulator-5554
```

## Subflows

| File | Purpose |
|------|---------|
| `subflows/ensure_main_shell.yaml` | Reach main shell after launch |
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
