# Research & Traceability: MeMuslim Core Trust & Reliability

## 1. Traceability Matrix & Defect Classification

This matrix strictly separates *competitor complaints* from *confirmed MeMuslim defects*. We do not assume Khatmah's bugs exist in MeMuslim without QA/Repository evidence.

| ID | Source | User Problem | Severity | Platform | MeMuslim Status | Classification | Proposed Response | Requirement IDs |
|---|---|---|---|---|---|---|---|---|
| R-01 | Khatmah Review | Claimed missing letters / wrong Ayahs. | Critical | Both | No confirmed defect. Uses QCF v4. | **Preventive Trust Requirement** | Build-time validation, manifest generation, and lightweight post-update checks. | FR-001, FR-002, GOV-001 |
| R-02 | Khatmah Review | Adhan fails/late/killed. | Critical | Android | Native architecture exists (`PrayerBootReceiver`, WorkManager). Needs characterization. | **Unverified Assumption (Needs QA)** | Audit current architecture, harden existing exact-alarms, add Health UI. | FR-006, FR-008 |
| R-03 | Khatmah Review | GPS failed, stuck in loop. | Critical | Both | Requires location permission; no offline manual fallback. | **Confirmed Product Gap** | Implement offline manual city search fallback and Location ADR. | FR-015, FR-016 |
| R-04 | Khatmah Review | iOS/Android disparity. | High | Android | Parity generally maintained. | **Competitor-specific issue** | Ensure explicit cross-platform tests. | N/A |
| R-05 | Khatmah Review | Intrusive ads / sudden paywalls. | High | Both | No ads present. | **Already Implemented Correctly** | Explicitly reject ad-based models. | N/A |
| R-06 | Khatmah Review | Incorrect Athkar content. | Critical | Both | Curated, but lacks automated integrity manifest. | **Preventive Trust Requirement** | Require dual-signoff and validation for content. | GOV-002 |

## 2. MeMuslim Repository Evidence & Existing Architecture Audit
- **Quran Data**: Assets exist under `assets/quran/`. No automated test suite for page/glyph/audio mapping mapping is currently running on CI. **Action**: Implement CI checks.
- **Athan Reliability (Android)**: 
  - *Evidence*: `AndroidManifest.xml` already requests `SCHEDULE_EXACT_ALARM`.
  - *Evidence*: `com/tilawa/app/prayer/PrayerBootReceiver.kt` exists and re-arms alarms on `BOOT_COMPLETED`, `TIMEZONE_CHANGED`, etc.
  - *Evidence*: `PrayerNotificationsWatchdogScheduler.kt` uses `WorkManager` for fallback rescheduling.
  - *Classification*: **Harden**. Do not replace. We must add a characterization task (`T-A00`) to benchmark this pipeline, add observability, and build the user-facing Health Check UI (`T-A02`).
- **Location**: `LocationCubit` handles geolocation. **Action**: An ADR is required to select the offline city data source before implementing the fallback feature.

## 3. Deliberate Deferrals & Rejections
- **Rejected**: Full runtime hashing of all SQLite databases on every cold start (Regresses startup performance; deferred to build-time + post-update validation).
- **Deferred**: Adding Warsh/Qaloon Riwayat. Priority is proving Hafs Hafs (QCF v4) integrity first.
