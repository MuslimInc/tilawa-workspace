# Android Release QA Walkthrough

## Scope

This checklist covers Android release readiness for prayer notifications and native Adhan playback. Execute it on real devices before staged rollout. Do not mark the release GO until the result table has passing evidence for at least Pixel, Samsung, and one aggressive OEM family such as Oppo/Realme/OnePlus or Xiaomi/Redmi/Poco.

## Device Matrix

Use the table once per device/OS combination:

| Group | Case | Expected Result | Device/OS | Pass/Fail | Notes/Evidence |
|---|---|---|---|---|---|
| App state | Foreground, Adhan enabled | Notification appears at exact time, Adhan plays once, Stop works |  |  |  |
| App state | Background, Adhan enabled | Alarm fires at exact time, FGS notification shown, Adhan plays once |  |  |  |
| App state | Removed from recents | Alarm still fires unless app was force-stopped |  |  |  |
| App state | Adhan disabled, notification enabled | Notification fires, no Adhan playback service/audio |  |  |  |
| App state | Notifications disabled | No notification/audio; existing Adhan alarms cleared |  |  |  |
| System | Screen off | Notification + Adhan fire at expected time |  |  |  |
| System | Battery Saver ON | Alarm still fires; note OEM delay if any |  |  |  |
| System | Doze-like idle | Exact alarm fires; no duplicate playback |  |  |  |
| Device event | Reboot | Boot receiver re-arms pending alarms; next Adhan fires |  |  |  |
| Device event | Timezone change | Schedule recalculates; no stale timezone alarm |  |  |  |
| Device event | Manual time change | Schedule recalculates; no duplicate alarm |  |  |  |
| Permissions | POST_NOTIFICATIONS denied/revoked | Cleanup runs; no new notifications/Adhan |  |  |  |
| Permissions | POST_NOTIFICATIONS re-granted | Scheduling resumes on next refresh |  |  |  |
| Permissions | Exact alarm available | Native Adhan schedule succeeds |  |  |  |
| Permissions | Exact alarm unavailable fallback build | User permission flow shown; denied state falls back to inexact FLN |  |  |  |
| Debug/Profile | Manual 10s test in profile | Button appears and schedules one test Adhan |  |  |  |
| Release | Manual 10s test in release | Button is absent |  |  |  |

## Play Console Texts

Exact alarm declaration:

Tilawa uses exact alarms for user-enabled prayer time and Adhan alerts. Prayer reminders and Adhan playback are core user-facing alarm functionality and must occur at precise prayer times selected by the user's prayer settings.

Foreground service declaration:

Tilawa starts a short-lived `mediaPlayback` foreground service only when a user-enabled Adhan alarm fires. The service plays the bundled Adhan audio, shows a visible notification with a Stop action, and stops after playback completion or user stop.

Notification permission explanation:

Tilawa sends user-enabled prayer reminders and Adhan alerts. Users can disable notifications globally or per prayer.

Analytics/privacy explanation:

Prayer notification analytics are lightweight operational events used to monitor scheduling, playback failures, duplicate playback guards, permission cleanup, and watchdog health. Events do not include raw location, contacts, messages, or prayer calculation inputs.

## Exact Alarm Rejection Fallback

If Google Play rejects `USE_EXACT_ALARM`:

1. Replace `USE_EXACT_ALARM` with `SCHEDULE_EXACT_ALARM`.
2. Use the existing exact-alarm permission request flow.
3. If permission is denied, schedule inexact Flutter Local Notifications fallback and emit `adhan_fallback_used`.

## Coverage Status

Run:

```bash
./gradlew clean :app:testDebugUnitTest :app:jacocoTestReport
```

If Jacoco still reports class mismatches, mark the Jacoco percentage non-blocking and document: "Logic verified by Flutter + JVM unit tests; Jacoco native package coverage report is invalid due AGP/Kotlin transformed-class mismatch."

## Release Gate

Current status is NO-GO until this checklist is manually executed and the release build verification passes.
