# Research & Traceability: MeMuslim Core Trust & Reliability

## 1. Traceability Matrix & Defect Classification

This matrix strictly separates *competitor complaints* from *confirmed MeMuslim defects*. We do not assume Khatmah's bugs exist in MeMuslim without QA/Repository evidence.

| ID | Source | User Problem | Sentiment | Severity | Platform | MeMuslim Status | Classification | Proposed Response | Priority | Requirement IDs |
|---|---|---|---|---|---|---|---|---|---|---|
| R-01 | Khatmah Review | Claimed missing letters / wrong Ayah numbers. | Angry | Critical | Both | MeMuslim uses QCF v4 which is accurate, but lacks runtime verification. | **Preventive Trust Requirement** | Implement build-time and runtime manifest checksum for Quran database. | P0 | FR-001, FR-002, GOV-001 |
| R-02 | Khatmah Review | Adhan does not play / plays late / killed in background. | Frustrated | Critical | Android | MeMuslim currently uses `flutter_local_notifications` scheduling but lacks `SCHEDULE_EXACT_ALARM` hardening and OEM diagnostic UI. | **Partially Implemented / Unreliable** | Implement Exact Alarms, Boot/Timezone receivers, and a diagnostic UI. | P0 | FR-003, FR-004, UX-001 |
| R-03 | Khatmah Review | App stuck because GPS failed and no manual city search exists. | Blocked | Critical | Both | MeMuslim requires location permission and has no manual fallback in `LocationOnboardingScreen`. | **Confirmed Product Gap** | Implement offline manual city search fallback. | P0 | FR-005, FR-006, OFF-001 |
| R-04 | Khatmah Review | Tafsir/Audio missing on Android but present on iOS. | Betrayed | High | Android | MeMuslim maintains parity generally, but audio features need cross-platform regression tests. | **Competitor-specific issue** | Ensure new specs explicitly check platform parity. | P1 | AND-001, IOS-001 |
| R-05 | Khatmah Review | Intrusive ads and sudden paywalls mid-worship. | Angry | High | Both | MeMuslim does not have ads. | **Already Implemented Correctly** | Explicitly reject ad-based models. Document transparent monetization rules. | P1 | REJ-001 |
| R-06 | Khatmah Review | Incorrect Dua/Athkar content mixed in. | Outraged | Critical | Both | MeMuslim content is curated but lacks human-review governance workflows for updates. | **Preventive Trust Requirement** | Require dual-signoff and immutable sourcing for religious content. | P1 | GOV-002 |
| R-07 | Khatmah Review | Wants daily structured Khatmah habit. | Positive | High | Both | Spec 023 is drafted but not fully integrated. | **Already Owned** (Spec 023) | Delegate to Spec 023. | P1 | N/A |
| R-08 | Khatmah Review | Wants widgets for progress and prayer times. | Positive | High | Both | Spec 041 is drafted. | **Already Owned** (Spec 041) | Delegate to Spec 041. | P1 | N/A |

## 2. MeMuslim Repository Evidence & Assumptions
- **Quran Data (Evidence)**: The `apps/tilawa/assets/quran` currently relies on static loading. There is no `sha256` integrity manifest checked at runtime. If an asset is corrupted during an app update, the user sees blank or offset text.
- **Athan Reliability (Evidence)**: Inspecting `prayer_times` feature shows reliance on standard `workmanager` and `flutter_local_notifications`. On Android 12+, exact alarms require explicit permission which is not robustly requested or diagnosed.
- **Location (Evidence)**: `LocationCubit` only handles `geolocator` requests. If `Geolocator.getCurrentPosition` fails or times out, there is no offline DB to fall back to.

## 3. Deliberate Deferrals & Rejections
- **Rejected (REJ-001)**: Ad-supported monetization. MeMuslim will monetize via premium value, not attention extraction.
- **Deferred**: Adding Warsh/Qaloon Riwayat. Priority is stabilizing Hafs Hafs (QCF v4) integrity first.
