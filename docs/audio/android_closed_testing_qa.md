# Android Closed Testing — Quran audio QA

Scope: **Android only**. Run on at least one phone (API 26+) and one emulator
before promoting a build.

Support triage for OEM “stops every N minutes” reports:
[oem_background_playback_support.md](oem_background_playback_support.md).

## Device QA checklist

| Scenario | Steps | Pass criteria |
|----------|-------|---------------|
| **Process kill** | Play surah → swipe app away from recents → reopen | No ghost mini-player; optional resume from notification if session still alive |
| **Notification** | Play → background app → use notification play/pause/next | Controls respond; tap body opens expanded player |
| **Bluetooth** | Connect BT headset → play/pause/skip from headset | Audio routes correctly; controls work |
| **Offline** | Download surah → airplane mode → play download | Plays without network; loading indicator while buffering |
| **Track end (queue)** | Queue 2+ surahs → let first finish | Auto-advances to next surah; mini-player updates |
| **Track end (single)** | Play one surah to end | Session stops; no stuck “playing” UI |
| **Loading UX** | Start network stream on slow connection | Mini + expanded play button shows spinner while loading/buffering |
| **Init failure** | (Dev) force `AudioService.init` failure | Error toast; app remains usable |
| **Long background (OEM)** | On Xiaomi/Redmi/MIUI (or Oppo/Vivo): play a long surah or queue → leave app in background / screen off for **≥ 20 minutes** without touching sleep timer | Playback continues; media notification stays visible; reopening app does **not** require re-picking reciter + surah |
| **Low free storage** | Device with **&lt; 4 GB** free (or simulate heavy fill) → long background play as above | Prefer pass; if audio dies, confirm process death (cold start / empty queue) and free space before filing an app bug |
| **Sleep timer 15 min** | Set sleep timer to 15 minutes → let it fire | Audio pauses; **same** reciter/surah remain in session (mini-player / expanded player still show the track). Contrast with OEM kill, which clears the session |

## Notes

- Repeat **one** / **all** follow existing repeat-mode controls.
- Cold-start full resume metadata CTA is **out of scope** for this pass.
- iOS: `UIBackgroundModes` → `audio` in `apps/tilawa/ios/Runner/Info.plist`
  (requires full rebuild, not hot reload).
- While playing, Android uses `TilawaAudioServiceConfig` (`audio_service`
  ongoing notification + `androidStopForegroundOnPause`) and
  `foregroundServiceType=mediaPlayback` in the manifest. That does **not**
  override MIUI autostart / battery “Restricted” / near-full storage LMK.
  Contract test: `test/shared/audio/tilawa_audio_service_config_test.dart`.
- Battery-optimization exemption is **not** prompted in the first-run prayer
  wizard today (`prayer_alerts_setup_pending_steps.dart` keeps that step
  commented). OEM autostart guidance still surfaces for Xiaomi/Redmi/etc. via
  prayer alerts setup when `oemRequiresAutostart` is true.
