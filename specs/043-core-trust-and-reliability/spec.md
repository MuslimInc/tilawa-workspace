# Feature Specification: Core Trust & Reliability

**Initiative**: MeMuslim Daily Companion
**Scope Mode**: Option A (Independently Releasable Workstreams)

## 1. Domain A: Quran Integrity Architecture
**Note**: No confirmed Quran-content defect has been found in MeMuslim. Current QCF assets reduce rendering risk, but QCF usage does not independently prove text, glyph mapping, page mapping, search index, or audio mapping correctness. Integrity requirements are preventive until a repository defect is reproduced.

- **Authoritative Source**: King Fahd Complex (QCF v4) for Uthmanic script.
- **Validation Pipeline**:
  1. Source validation (verifying source files).
  2. Generation-time validation (when creating app assets).
  3. CI/build-time validation (asserting structural integrity).
  4. Versioned integrity manifest (bundled).
  5. Lightweight post-update validation. Full runtime hashing is ONLY performed if lightweight checks detect anomalies, to prevent cold-start regressions.
- **FR-001**: Build-time script MUST generate a versioned `quran_manifest.json` containing SHA-256 hashes and mapping verification (114 Surahs, 6236 Ayahs, page boundaries).
- **FR-002**: Runtime validation MUST perform a lightweight check post-update. If invalid, the app MUST safely degrade the view.
- **FR-003**: The app MUST perform build-time checks validating Juz, Hizb, Page, and Sajdah mappings.
- **FR-004**: Quran domain models MUST be immutable to prevent runtime mutation. Normalization rules MUST explicitly forbid arbitrary transformations of the QCF text.
- **FR-005**: Provide a privacy-safe "Report Error" flow in the UI that attaches Surah, Ayah, App Version, without sending PII.

## 2. Domain B: Athan Reliability Architecture
We aim for reliable scheduling within platform constraints, explicit degraded modes, and actionable diagnostics. There is no silent failure where the app can detect the failure.

The specification distinguishes:
1. Prayer-time calculation (Domain calculation).
2. Schedule request creation (Dart).
3. OS schedule acceptance (Native).
4. Alarm trigger (Native receiver).
5. Notification presentation (System UI).
6. Audio playback (System Audio).
7. User/OS suppression (DND, Battery Optimization).

### Android Constraints & Implementation
MeMuslim already implements `PrayerBootReceiver.kt`, `PrayerNotificationsWatchdogScheduler.kt` (via WorkManager), and `SCHEDULE_EXACT_ALARM`. This architecture will be audited, characterized, and hardened.
- **FR-006**: MUST observe and report exact alarm permission state (`canScheduleExactAlarms()`) and explicitly handle Android 14+ behavior. If denied, gracefully fallback to inexact alarms and warn the user.
- **FR-007**: MUST maintain and harden existing `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, and `TIMEZONE_CHANGED` receivers.
- **FR-008**: MUST provide `AdhanHealthCheckScreen` to expose permission states and OEM battery optimization deeply linked to settings.
- **FR-009**: Audio playback MUST request `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` to handle Bluetooth/Headset interruptions gracefully.

### iOS Constraints & Implementation
- **FR-011**: MUST rely on `UNUserNotificationCenter` scheduled local notifications. Acknowledge the 64 notification limit.
- **FR-012**: Audio is limited to 30 seconds. The system MUST provide an abridged Athan audio file.
- **FR-013**: Timezone changes on iOS MUST schedule a `BGAppRefreshTask` to recalculate.
- **FR-014**: MUST manage user expectations regarding iOS limits (e.g., volume control is system-level, silent mode suppresses audio).

## 3. Domain C: Location Fallback State Machine
The system must never trap the user in a permission loop.
- **FR-015**: **State Machine Definition**:
  - `PermissionNotRequested` -> Prompts user.
  - `PermissionGranted` -> Fetches precise location.
  - `PermissionDenied` / `PermanentlyDenied` / `Timeout` -> Transitions to `ManualCitySelection`.
  - `ManualCitySelection` -> User queries offline city DB.
  - `LocationOverride` -> User's manual selection takes precedence over cached GPS until explicitly revoked.
- **FR-016**: Manual selection MUST be powered by a resolved offline database (Pending ADR approval).
- **FR-017**: If the app starts offline and no cached location exists, it MUST boot directly into `ManualCitySelection`.

## 4. Religious-Content Governance
- **GOV-001**: Any PR modifying `assets/quran/` requires mandatory approval from a designated codeowner.
- **GOV-002**: Firebase Remote Config kill switch `force_disable_quran_version` can instantly block a compromised text version.

## 5. Non-Functional Requirements
- **OFF-001**: Manual location and Quran validation MUST require zero network requests.
- **PERF-001**: Integrity checks MUST NOT meaningfully regress cold start (< 100ms impact).
