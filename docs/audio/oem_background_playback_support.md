# Support playbook — Quran playback stops in background (OEM)

Use when a user reports continuous Quran listening that **stops after a fixed
interval** (often ~15 minutes), especially on Xiaomi / Redmi / MIUI, Oppo,
Vivo, Huawei, or Transsion (Infinix/Tecno).

## Triage (symptoms → cause)

| Symptom | Likely cause | App bug? |
|---------|--------------|----------|
| Must reopen app and **re-select reciter + surah** | Process killed (OEM battery / LMK / low storage) | Usually **no** — device policy |
| Media notification **disappears** before audio stops | Foreground media session lost / process death | Device / storage first |
| Audio pauses; same track still in mini-player; sleep timer was set | Sleep timer (15 / 30 / 60 min presets) | **No** — expected |
| Stops only when paused / after pause | `androidStopForegroundOnPause: true` (paused FGS drops priority) | Expected while paused; not a “while playing” bug |

Do **not** treat “every 15 minutes” alone as proof of a sleep-timer bug. The
sleep timer only runs after the user sets it; on expiry the bloc pauses and
keeps `currentAudio` (see
`apps/tilawa/test/features/audio_player/presentation/bloc/audio_player_bloc_test.dart`).

## Device facts to collect

1. App version + build (Settings footer).
2. Manufacturer / ROM (e.g. Redmi Note 9S, MIUI 14, Android 12).
3. Free storage (About phone → Storage). Flag if free space **&lt; ~4 GB**.
4. Was sleep timer active?
5. During failure: was the **media playback notification** still visible?

## User steps (reply checklist)

1. Update to the latest store build.
2. Free storage (target **≥ 5–10 GB** free).
3. App battery: **Unrestricted** / no restrictions (MIUI: Battery saver → No
   restrictions).
4. MIUI / OEM: enable **Autostart** for MeMuslim / أنا مسلم; lock the app in
   Recents.
5. Confirm sleep timer is off in the player.
6. Retest: play ≥ 20 minutes in background with the media notification visible.

Prayer alerts setup already flags Xiaomi/Redmi/Poco (and other OEMs in
`_autostartOems`) for manual autostart guidance. That flow is for prayer
delivery, but the same OS settings protect long audio sessions.

## Engineering notes (do not over-claim in CHANGELOG)

- Stack: `TilawaAudioServiceConfig` → `audio_service` +
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` + ongoing notification while playing
  (`AppStartupTasks.initializeAudioService`).
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` is **commented out** in
  `AndroidManifest.xml`; the prayer wizard battery step is also disabled.
  Re-enabling either is a product / Play-policy decision — not a silent fix.
- Recent FLUTTER-9 work (`TRIM_MEMORY_BACKGROUND` ignored) reduces OPPO unlock
  ANRs; it is **not** a verified fix for MIUI 15-minute audio kills.
- Manual QA matrix:
  [android_closed_testing_qa.md](android_closed_testing_qa.md)
  (**Long background (OEM)**, **Low free storage**, **Sleep timer 15 min**).
