# YouTube Music reference flows (Maestro)

Parity flows compare **YouTube Music** collapse/expand behavior with **Tilawa**
`QuranPlayerWidget` using identical gesture timing and screenshot names.

## Prerequisites

| App | Emulator setup |
| --- | --- |
| YouTube Music | `com.google.android.apps.youtube.music` installed, signed in, playback available |
| Tilawa | Debug build `com.tilawa.app`, signed-in session, `launchApp: clearState: false` |

## Run

From the repo root:

```sh
# Reference (YouTube Music)
maestro test .maestro/reference/youtube_music_collapse_expand_parity.yaml

# Tilawa Quran player (same scenarios)
maestro test .maestro/quran_player/quran_player_collapse_expand_parity.yaml
```

Optional screen recordings:

```sh
maestro record .maestro/reference/youtube_music_collapse_expand_parity.yaml
maestro record .maestro/quran_player/quran_player_collapse_expand_parity.yaml
```

## What each scenario checks

| ID | Gesture | YouTube Music expectation | Tilawa target |
| --- | --- | --- | --- |
| PARITY_01 | — | Mini bar visible at bottom | `quran_player_mini` on reciter screen |
| PARITY_02 | Slow swipe up 92%→8% (1500ms); optional mini swipe if still mini | Sheet tracks finger; lands expanded | Continuous `drag.update` logs; full sheet |
| PARITY_04 | Partial swipe down 22%→58% | Snaps to mini or expanded | No stuck mid-transition overlay |
| PARITY_05 | Swipe down 20%→92% | Returns to mini | `quran_player_mini` visible |
| PARITY_06 | Tap mini bar | Opens now playing | `tapOn` `quran_player_mini` |
| PARITY_07 | Quick collapse + expand | No white ghost / flicker | Same |

Screenshots: `parity_01_mini_baseline` … `parity_08_quick_cycle_end` (compare across runs).

## Tilawa debug logs

```sh
adb logcat | rg "QuranPlayer.*drag|PlayerParity"
```

## YTM playback subflow

If `ensure_youtube_music_playback.yaml` cannot start a track (locale/UI drift),
start any song manually in YouTube Music, then re-run the parity flow.

## Adjusting coordinates

Both flows use percentage swipes for 1080×2400-class phones. On other aspect
ratios, edit the shared `start`/`end` values in **both** YAML files together so
comparisons stay fair.
