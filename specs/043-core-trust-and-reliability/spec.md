# Feature Specification: Core Trust & Reliability

**Initiative**: MeMuslim Daily Companion
**Scope Mode**: Option A (Independently Releasable Workstreams)

## 1. Domain A: Quran Integrity Architecture
**Note**: No confirmed Quran-content defect has been found in MeMuslim. The Khatmah
reviews behind this domain (K12, K22, K34 vague; K45 specific text; K46 ayah-number;
K27 Juz boundary — see `research.md` §4) are **evidence of trust risk, not proof of a
MeMuslim defect.** Integrity requirements are **preventive** until a repository defect is
reproduced. Current QCF assets reduce rendering risk, but QCF usage does not independently
prove text, glyph mapping, page/ayah mapping, or Juz/Hizb-boundary correctness.

**Asset-topology grounding (repository-verified).** MeMuslim has no `quran.db` and there is
no `assets/quran/` directory (corrected premise). The real Quran data surface is:
`apps/tilawa/assets/data/quran.json` (text), `packages/quran_image/assets/data/*.json`
(verse markers / ayah info), and `packages/quran_qcf` fonts — where the **QCF page fonts
are downloaded at runtime from a CDN** (`quran_font_service.dart:downloadFonts()`), not
bundled. All FRs below target this topology; a manifest of bundled assets alone cannot
cover the rendering-critical downloaded glyphs.

**Concept separation (do not conflate).** The reviews cover four *distinct* integrity
problems that require different controls and owners:
1. **Text / glyph correctness** (K12, K22, K34, K45) — FR-001/002.
2. **Ayah & surah numbering / index** (K46) — FR-003a.
3. **Juz / Hizb / page boundary mapping** (K27) — FR-003b; the *plan that consumes it* is
   owned by **Spec 023**.
4. **Athkar / Dua content** (K15) — this is **NOT Quran text**; governed separately by
   GOV-003, different asset and codeowner.

- **Authoritative Source**: King Fahd Complex (QCF v4) for Uthmanic script.
- **Validation Pipeline**:
  1. Source validation (verifying source files).
  2. Generation-time validation (when creating app assets).
  3. CI/build-time validation (asserting structural integrity).
  4. Versioned integrity manifest (bundled).
  5. Lightweight post-update validation. Full runtime hashing is ONLY performed when the versioned Quran integrity manifest changes, to prevent cold-start regressions.
- **FR-001**: Build-time script MUST generate a versioned `quran_manifest.json` containing SHA-256 hashes of the **actual bundled Quran assets** (`assets/data/quran.json` and the `quran_image` data JSON) plus text checks (114 Surahs, 6236 Ayahs — Hafs/QCF-v4 riwayah; note this count is riwayah-specific and changes if a future riwayah is added).
- **FR-001a** (**new — CDN font integrity, closes the real K12/K22 risk surface**): The app MUST verify the **downloaded QCF page-font archive** against expected per-file (or per-archive) SHA-256 hashes recorded in the manifest, immediately **after download and before first render**, and MUST fail closed (fallback to bundled Uthmanic text style, never render unverified glyphs) on mismatch. Bundled-only hashing does not satisfy this.
- **FR-002**: Runtime validation MUST perform a lightweight check when the versioned Quran integrity manifest changes (post-update, **not** on every cold start). `quranContentVersion` is persisted in SharedPreferences and compared against the bundled manifest version. **Failure-reason → behavior matrix** (resolves the throw-vs-degrade contradiction with `contracts/quran-validation-result.md`):
  | `ValidationFailureReason` | Behavior |
  |---|---|
  | `hashMismatch` (text/asset changed) | Safely degrade Mushaf view + non-fatal Crashlytics with expected/actual hashes. Do NOT hard-crash. |
  | `structuralGap` (counts/mapping) | Same as hashMismatch. |
  | `manifestMissing` / `ioError` | **MUST NOT** treat as corruption; log, and use existing readable data. |
  On success, persist the new version.
- **FR-003a** (**new**): Build-time checks MUST validate the **ayah/surah numbering and index** against the authoritative source (covers K46: correct ayah *numbers*, not only text).
- **FR-003b**: Build-time checks MUST validate **Juz, Hizb, quarter, Page, and Sajdah boundary mappings** against the authoritative source (covers K27). The Khatma *plan* that consumes these boundaries is owned by **Spec 023**; this FR only guarantees the boundary data.
- **FR-004**: Quran domain models MUST be immutable to prevent runtime mutation. Normalization rules MUST explicitly forbid arbitrary transformations of the QCF text.
- **FR-005**: Provide a privacy-safe "Report Error" flow in the UI that attaches Surah, Ayah, App Version, without sending PII (covers K45/K46 verifiable reports and undiagnosable K28).

## 2. Domain B: Athan Reliability Architecture
**Evidence**: 10 Khatmah reviews cluster here — the **strongest and most recurring** signal
in the sample (K16,K19,K25,K26,K29,K31,K33,K36,K42,K44), spanning three distinct failure
modes: total non-firing, late/incorrect timing, and incomplete audio (`research.md` §4).
This is a *Khatmah* pain; MeMuslim's native pipeline exists but is **not yet characterized
for long-run delivery** (PART/PREV, not a confirmed MeMuslim defect).

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
MeMuslim already implements `AdhanScheduler.kt`, `AdhanReceiver.kt`, `AdhanPlaybackService.kt`, `PrayerBootReceiver.kt`, `PrayerNotificationsWatchdogScheduler.kt`/`Worker.kt` (via WorkManager), and `SCHEDULE_EXACT_ALARM`. The audible channel id is **`com.tilawa.app.prayer_adhan_v5`** (`AdhanReceiver.kt:29`) — version-suffixed on purpose; a channel change requires a **new** `_v6`, never an in-place edit. Characterization tests already exist (`PrayerWatchdogCharacterizationTest.kt`, `AdhanSchedulerTest.kt`, `PrayerBootReceiverTest.kt`), so the audit task **extends** them rather than creating a baseline. This architecture will be audited, characterized, and hardened.
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
**Evidence**: 1 review (K13). This is a **high-blocking, low-frequency** item — kept at P0
on *severity + confirmed repository gap* (MeMuslim `LocationCubit` is GPS-only with no
offline manual entry), **not** on frequency. Do not describe it as a common complaint.

The system must never trap the user in a permission loop.
- **FR-015**: **State Machine Definition**:
  - `PermissionNotRequested` -> Prompts user.
  - `PermissionGranted` -> Fetches precise location.
  - `PermissionDenied` / `PermanentlyDenied` / `Timeout` -> Transitions to `ManualCitySelection`.
  - `ManualCitySelection` -> User queries offline city DB.
  - `LocationOverride` -> User's manual selection takes precedence over cached GPS until explicitly revoked.
- **FR-016**: Manual selection MUST be powered by a resolved offline database. The ADR (`adr-offline-city-db.md`) is **Accepted** — the offline-city prototype `cities_prototype.db` already exists at repo root and matches the ADR's measured figures (3.34 MB raw / <1 MB compressed / ~2–2.5 ms lookups). GeoNames (CC-BY) with attribution.
- **FR-017**: If the app starts offline and no cached location exists, it MUST boot directly into `ManualCitySelection`.

## 4. Religious-Content Governance
- **GOV-001**: Any PR modifying the Quran text/data assets (`apps/tilawa/assets/data/quran.json`, `packages/quran_image/assets/data/*.json`) or the QCF font pipeline requires mandatory approval from a designated codeowner. *(Corrected: there is no `assets/quran/` directory in this repo.)*
- **GOV-002**: Firebase Remote Config kill switch `force_disable_quran_version` can instantly block a compromised text/font version.
- **GOV-003** (**new — covers K15, the "non-Islamic text amid duas" report**): Athkar/Dua content is governed **separately from the Quran pipeline**. Any PR modifying Athkar/Dua content requires dual codeowner sign-off, each item MUST carry a documented source reference, and a Remote Config kill switch MUST be able to disable a compromised content version. This is a **preventive** control (severity-driven, N=1); it is not evidence of a MeMuslim content defect.

## 5. Non-Functional Requirements
- **OFF-001**: Manual location and Quran validation MUST require zero network requests. *(Note: the QCF font **download** in FR-001a is inherently networked; its integrity check runs post-download and is exempt from OFF-001.)*
- **PERF-001**: The **post-update** integrity pass (FR-002) MUST run asynchronously off the UI thread and MUST NOT meaningfully regress startup (< 100ms perceived impact). It does not run on normal cold starts.

## 6. Success Metrics *(evidence-linked)*
Metrics measure the problems users actually expressed; none logs precise religious behavior
tied to an identifiable user (see privacy rules in the contracts).
- **SM-001** (Adhan, K16…K44): `adhan_delivered.latency_ms` p95 within agreed margin; scheduled→delivered success rate measured over 7–14 days without opening the app.
- **SM-002** (Adhan health): Adhan-related 1★ review rate trends down post-release; `adhan_health_check_viewed` → settings-fix completion rate.
- **SM-003** (Location, K13): **permission dead-end rate** (GPS-denied sessions that reach correct prayer times) → target near-zero; manual-city adoption among GPS-denied users.
- **SM-004** (Integrity, K12/K45/K46/K27): **0 confirmed** Quran text/number/boundary mismatches in production; `quran_error_reported` triage SLA < 24h.
- **SM-005** (Athkar governance, K15): 0 confirmed content-integrity incidents; content kill-switch reachable.
- **SM-006** (Habit loop — *owned by Spec 023*, tracked here for coherence): D1/D7/D30 retention; daily Wird completion; continue-reading usage.
- **SM-007** (Crash-free users) ≥ 99.5%; no regression cluster after an update (K43/K44).
- **SM-008** (Monetization clarity, K30/K32/K37/K38): monetization-related 1★ rate; zero repeated post-purchase support prompts.

## 7. Missed Product Opportunities (from the reviews, routed — not implemented here)
- **Khatma / Wird progress widget** (K48 upvoted, K51) — the **strongest currently unowned
  retention opportunity observed in this extremes-only review sample** (cannot estimate total
  market demand): Spec 041 ships Prayer/Ayah/Athkar/Hijri widgets but **no Khatma-progress
  widget**, and Spec 023 is in-app only. → **Add to Spec 041**, fed by Spec 023's `KhatmaTodayTarget`.
- **Gentle adherence streak / "days committed"** (K51) — → **amend Spec 023** (calm,
  non-punitive; no guilt mechanics).
- **Continue-listening (audio) progress** (K35) — → **amend Spec 023**.
- **Comfort mode for elderly** (K05) — larger type, high contrast, short paths → Roadmap P1 a11y.
- **User religious-content report flow** (K45, K46, K28) — covered by FR-005 (kept in 043).
- **Riwayat (Warsh/Qaloon)** (K39,K40,K56) / **Tafsir** (K14) / **adhan voice library**
  (K17) — deferred to future specs (P2); rationale in `research.md` §8.

## 8. Deliberate Non-Copy Decisions
MeMuslim positioning: *a Quran-first daily companion that is calm, trustworthy, modern,
accessible, and ad-free.* The following Khatmah behaviors/requests are **deliberately NOT
copied**, each tied to positioning:
- **Intrusive ads** (K38) and **repeated post-purchase support popups** (K30, K37) — violate *calm* and *trustworthy*; MeMuslim stays ad-free with transparent, upfront pricing.
- **Surprise mid-journey paywall** (K32) — violates *trustworthy*; free vs paid disclosed before a long plan starts.
- **Guilt-based streaks / punitive recovery** — violates *calm*; Spec 023 uses non-punitive catch-up.
- **Leaderboards / competitive worship mechanics** — violates *calm* and worship dignity.
- **Overloaded home grid** — violates *simple*; home is a time-ordered daily journey, not a feature catalog.
- **Excessive notification pressure** — only worship-relevant, user-controlled notifications.
- **Unverified religious content** — GOV-001/003 forbid it; never ship content without a source + review.
- **Platform-exclusive core Quran features** (the parity complaints K04/K10/K11/K14) — avoided by a parity release gate, not by matching Khatmah's inconsistency.
