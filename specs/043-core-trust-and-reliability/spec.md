# Feature Specification: Core Trust & Reliability

**Initiative**: MeMuslim Daily Companion
**Scope Mode**: Option A (Independently Releasable Workstreams)

## 1. Domain A: Quran Integrity Architecture
We do not rely on vague client-side checksums. Integrity is guaranteed via build-time validation and runtime immutability.
- **Authoritative Source**: King Fahd Complex (QCF v4) for Uthmanic script. Version: `1.0.0-qcf4`.
- **FR-001**: Build-time script MUST generate `quran_manifest.json` containing SHA-256 hashes for all SQLite/JSON data files, plus metadata (6236 Ayahs, 114 Surahs).
- **FR-002**: Runtime validation MUST check the manifest hash against the bundled database file before loading the Mushaf. If invalid, the app MUST trigger an emergency content rollback to the bundled asset or disable the view safely.
- **FR-003**: The app MUST perform a fast runtime check validating Juz 1-30 boundary indices and Surah mappings are continuous without gaps.
- **FR-004**: Quran domain models MUST be immutable. Runtime mutation of religious text is strictly forbidden.
- **FR-005**: Provide a privacy-safe "Report Error" flow in the UI that attaches Surah, Ayah, App Version, and Data Hash without sending user PII.

## 2. Domain B: Athan Reliability Architecture
### Android Constraints & Implementation
- **FR-006**: MUST request and handle `android.permission.SCHEDULE_EXACT_ALARM`. If denied, gracefully fallback to inexact alarms and warn the user.
- **FR-007**: MUST implement `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIMEZONE_CHANGED`, and `LOCALE_CHANGED` broadcast receivers to reschedule alarms.
- **FR-008**: MUST respect OEM battery optimization by providing an actionable deep-link to settings via `AdhanHealthCheckScreen`.
- **FR-009**: Audio playback MUST request `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` to handle Bluetooth/Headset interruptions gracefully.
- **FR-010**: Prevent duplicate Athans by persisting the last triggered `prayer_id` locally.

### iOS Constraints & Implementation
- **FR-011**: MUST rely on `UNUserNotificationCenter` scheduled local notifications (up to the 64 notification limit, covering ~12 days of 5 daily prayers).
- **FR-012**: Audio is limited to 30 seconds for local notifications. The system MUST provide an abridged Athan audio file specifically for iOS background alerts.
- **FR-013**: Timezone changes on iOS MUST schedule a background task (`BGAppRefreshTask`) to recalculate and reschedule local notifications.

## 3. Domain C: Location Fallback State Machine
The system must never trap the user in a permission loop.
- **FR-014**: **State Machine Definition**:
  - `PermissionNotRequested` -> Prompts user.
  - `PermissionGranted` -> Fetches precise location.
  - `PermissionDenied` / `PermanentlyDenied` / `Timeout` -> Transitions to `ManualCitySelection`.
  - `ManualCitySelection` -> User queries offline city DB.
  - `LocationOverride` -> User's manual selection takes precedence over cached GPS until explicitly revoked.
- **FR-015**: Manual selection MUST be powered by an offline database (bundling ~50k cities with coordinates and timezones).
- **FR-016**: If the app starts offline and no cached location exists, it MUST boot directly into `ManualCitySelection`.

## 4. Religious-Content Governance
- **GOV-001**: Content Update Workflow: Any PR modifying `assets/quran/` requires mandatory approval from a designated "Religious Reviewer" codeowner.
- **GOV-002**: Kill Switch: Firebase Remote Config flag `force_disable_quran_version` can instantly block a compromised text version and force an app update.

## 5. Non-Functional Requirements
- **OFF-001**: Manual location and Quran integrity validation MUST require zero network requests.
- **SEC-001**: Manifest hashes MUST NOT be manipulatable via SharedPreferences.
- **RTL-001**: Diagnostic UIs and Location Search MUST support Right-To-Left Arabic layouts.
