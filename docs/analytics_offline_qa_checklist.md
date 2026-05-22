# Analytics offline QA checklist (Tilawa)

Use this checklist to confirm **Firebase Analytics queues events offline** and
that **native prayer/adhan** events include `client_timestamp_ms` for when the
action happened on device (not only when GA4 received the upload).

**Property:** `quran-playera-app`  
**Reports:** Exclude internal test device `CPH2529` (and any other QA handsets).

---

## Prerequisites

| Requirement | Why |
|-------------|-----|
| **Release or profile** build | Debug builds disable collection in `FirebaseAnalyticsService` (`kDebugMode`). |
| **Analytics enabled** | Firebase Console → Analytics → Data collection ON. |
| **DebugView** (optional live check) | Firebase Console → DebugView; enable debug mode on device (see below). |
| **Non-test device** | Prefer a Samsung/Redmi device, not `CPH2529`. |

### Enable DebugView on a device (Android)

```bash
adb shell setprop debug.firebase.analytics.app com.tilawa.app
```

Disable when finished:

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

---

## 1. Flutter path — schedule/cancel from UI (online → offline → online)

**Goal:** Events logged from Dart reach Firebase after connectivity returns.

1. Install **release** build on a test phone (not `CPH2529` if possible).
2. Open app → sign in or continue as guest → open **Prayer / Adhan** settings.
3. **Online:** Enable adhan for one prayer → confirm schedule succeeds.
4. Enable **airplane mode** (no Wi‑Fi / mobile data).
5. **Offline:** Toggle another prayer off (cancel) or change adhan sound
   (triggers reschedule/cancel on native channel).
6. Force-stop is **not** required; background the app 30s.
7. Disable airplane mode → wait **2–10 minutes** (SDK batch upload).
8. In **DebugView** or GA4 **Realtime**, verify (names may vary slightly):
   - `adhan_alarm_scheduled` and/or `native_adhan_schedule_success`
   - `adhan_alarm_cancelled` (with `context` if cancel-all)
   - Each event has parameter **`client_timestamp_ms`** (number, ms epoch).

**Pass:** Events appear after reconnect; `client_timestamp_ms` is present.

**Fail:** No events after 30 min online → check Play services, collection
disabled, or debug build.

---

## 2. Native path — alarm receiver / playback (no Flutter UI)

**Goal:** Events from `FirebasePrayerAnalytics` queue when the app process is
minimal.

1. Release build; schedule adhan for a prayer **~2–3 minutes** ahead (or use
   internal QA adhan test if available).
2. Optional: airplane mode **after** schedule succeeds, **before** fire time.
3. At fire time, confirm adhan plays (or notification path you expect).
4. Restore network; wait for upload.
5. Verify in DebugView / Realtime:
   - `adhan_receiver_triggered`
   - `adhan_service_started`
   - `adhan_playback_started` / `adhan_playback_completed` (if playback runs)
   - `client_timestamp_ms` on each

**Pass:** Playback funnel events present with timestamps.

**Fail:** Scheduled but no `adhan_playback_started` → product reliability issue
(track separately from offline analytics).

---

## 3. Boot / watchdog (optional)

1. Schedule several prayers online.
2. Reboot device (clears short process state).
3. After boot + network, within ~24h check for:
   - `boot_receiver_triggered`
   - `watchdog_triggered` / `watchdog_completed`
   - `native_adhan_schedule_success` (reschedule)

**Pass:** Reschedule events appear; no crash loop in Crashlytics.

---

## 4. GA4 reporting hygiene

| Task | Action |
|------|--------|
| Exclude QA device | Exploration filter: `Device model` ≠ `CPH2529` |
| Compare client vs server time | BigQuery or export: `client_timestamp_ms` vs event timestamp |
| Key events | Mark: `first_open`, `adhan_alarm_scheduled`, `adhan_playback_started`, `support_purchase_verified` |
| Cancel ≠ bug | High `adhan_alarm_cancelled` is normal preference tuning |

---

## 5. What you should **not** build for MVP

- Custom offline analytics database (Firebase SDK already queues on device).
- Using Analytics as billing/support source of truth (server verification only).

---

## 6. Parameter reference (prayer / native)

| Parameter | Type | Meaning |
|-----------|------|---------|
| `client_timestamp_ms` | long | Device time when `logEvent` was called |
| `context` | string | e.g. `cancel_all` on mass cancel |
| `prayer_name` / `prayer_key` | string | Prayer identity when provided |

Flutter events use the same `client_timestamp_ms` key via `AnalyticsParams`.

---

## Sign-off template

| Test | Device | Build | Date | Pass |
|------|--------|-------|------|------|
| 1 Flutter offline cancel/schedule | | release | | ☐ |
| 2 Native playback funnel | | release | | ☐ |
| 3 Boot reschedule (optional) | | release | | ☐ |
| DebugView `client_timestamp_ms` | | release | | ☐ |

**Tester:** _______________  
**Notes:** _______________
