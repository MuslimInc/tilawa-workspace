# Android Closed Testing — Quran audio QA

Scope: **Android only**. Run on at least one phone (API 26+) and one emulator before promoting a build.

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

## Notes

- Repeat **one** / **all** follow existing repeat-mode controls.
- Cold-start full resume metadata CTA is **out of scope** for this pass.
- iOS: `UIBackgroundModes` → `audio` in `apps/tilawa/ios/Runner/Info.plist` (requires full rebuild, not hot reload).

