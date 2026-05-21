# Feature Specification: Product Growth & Missing Features Roadmap

**Feature Branch**: `002-product-growth-roadmap`
**Created**: 2026-04-28
**Status**: Draft
**Type**: Strategic Product Specification (Research & Planning)

---

## Executive Summary

This document is a verified, evidence-based product analysis for the Tilawa app (v0.1.4+21). It
identifies confirmed capabilities, missing features, growth opportunities, and a corrected roadmap
grounded in actual codebase inspection rather than assumption. All claims are tagged with their
verification source or explicitly marked as unverified.

Tilawa has a strong technical foundation: QCF4 Quran rendering, audio playback with reels/share,
prayer times, athkar, qibla, reciters, bookmarks, history, and a premium architecture scaffold.
However, several high-impact features are architecturally wired but not yet fully functional,
and others that would significantly expand the user base are completely absent.

The three most impactful gaps for immediate attention are:
1. **No in-app review prompt** — directly suppresses Play Store ratings and organic discovery.
2. **No video watermark/branding on reels** — the existing share viral loop has no attribution.
3. **No verse translation** — the data model is wired for it but no data is bundled or fetched.

---

## Part 1: Confirmed Current Features

All items below were verified by inspecting specific files in the codebase.

### 1.1 Quran Reader
- **Status**: Implemented
- **Evidence**: `apps/tilawa/lib/features/quran_reader/` (full Clean Architecture directory)
- `apps/tilawa/assets/data/quran.json` — 114 surahs, all ayahs, includes per-ayah `juz` metadata
- `apps/tilawa/lib/features/quran_reader/domain/entities/ayah_entity.dart` — has `juz` field
- QCF4 font loading: `load_quran_fonts_to_engine_use_case.dart`, `check_fonts_downloaded_use_case.dart`
- Search: `search_ayahs_use_case.dart`
- Last-read position: `get_last_read_position_use_case.dart`, `save_last_read_position_use_case.dart`
- Reader settings (font size, scroll mode): `load_reader_settings_use_case.dart`

### 1.2 Audio Player
- **Status**: Implemented
- **Evidence**: `apps/tilawa/lib/features/audio_player/` (full feature directory)
- Sleep timer settings: `apps/tilawa/lib/features/settings/domain/services/sleep_timer_settings.dart`

### 1.3 Reels / Share Feature
- **Status**: Implemented (video generation + screenshot sharing)
- **Evidence**:
  - `apps/tilawa/lib/features/share/data/services/video_service.dart` — ffmpeg filter graph for
    single-image and multi-image slideshow video composition
  - `apps/tilawa/lib/features/share/data/services/audio_clip_service.dart` — audio clip generation
  - `apps/tilawa/lib/features/share/data/ffmpeg/ffmpeg_kit_runner.dart` — clean adapter over
    `ffmpeg_kit_flutter_new: ^4.1.0`
  - `apps/tilawa/lib/features/share/data/services/screenshot_service.dart` — screenshot sharing
- **Gap confirmed**: No `drawtext`, watermark, or branding overlay in the video filter graph.
  Only `album="Tilawa"` is set as audio metadata (not visible to video viewers on social media).

### 1.4 Athkar
- **Status**: Partially implemented
- **Evidence**:
  - `apps/tilawa/assets/data/athkar.json` — 2 categories only: **أذكار الصباح** (morning) and
    **أذكار المساء** (evening)
  - `apps/tilawa/lib/features/athkar/data/datasources/athkar_local_datasource.dart` —
    `getCategories()` and `getAthkarByCategory(int categoryId)` fully wired
  - `apps/tilawa/lib/features/athkar/domain/constants/tasbeeh_constants.dart` — Tasbeeh counter
  - `apps/tilawa/lib/features/athkar/presentation/screens/tasbeeh_screen.dart` — Tasbeeh UI
- **Gap confirmed**: Only 2 of the ~10 athkar categories documented in docs/missing_features.md are
  present in the data file. Infrastructure fully supports adding more.

### 1.5 Athkar Notifications
- **Status**: Implemented (scheduled local notifications)
- **Evidence**: `apps/tilawa/lib/core/services/athkar_notification_service.dart` — 5
  `zonedSchedule` calls; schedules morning and evening athkar with prayer-time-relative offsets
  and fallback to fixed daily times

### 1.6 Prayer Times
- **Status**: Screen and settings implemented; adhan scheduling NOT found
- **Evidence**:
  - `apps/tilawa/lib/features/prayer_times/` — full feature directory with screen and entities
  - `apps/tilawa/lib/features/prayer_times/domain/entities/prayer_settings_entity.dart` — defines
    `PrayerNotificationSettings` for each of the 5 prayers (fajr, dhuhr, asr, maghrib, isha)
  - `apps/tilawa/lib/features/prayer_times/presentation/widgets/next_prayer_countdown_card.dart`
    — countdown widget
- **Gap confirmed**: No `zonedSchedule` or adhan scheduling code found in the `prayer_times`
  feature. The settings entity is defined but is not connected to any notification scheduling
  service. The prayer-time notification toggle UI state is unknown.

### 1.7 Premium Feature
- **Status**: Architecture implemented; payment SDK NOT integrated
- **Evidence**:
  - `apps/tilawa/lib/features/premium/` — full Clean Architecture (screen, bloc, domain, data)
  - `apps/tilawa/lib/features/premium/presentation/widgets/premium_upgrade_dialog.dart`
  - `apps/tilawa/lib/features/premium/data/datasources/premium_remote_datasource.dart` —
    `purchaseSubscription()` writes directly to Firestore with `status: 'completed'`. No payment
    provider SDK (RevenueCat, `in_app_purchase`, etc.) is called. This is a **stub**.
  - `apps/tilawa/lib/features/premium/data/services/subscription_plans_service.dart` — reads
    plans from Firestore or returns defaults

### 1.8 Navigation / Deep Links
- **Status**: GoRouter with URL-based paths; external deep link handling NOT found
- **Evidence**:
  - `apps/tilawa/lib/router/app_router.dart` — GoRouter with routes:
    `/`, `/onboarding`, `/reciter/:reciterId`, `/premium`, `/settings`, `/login`, `/downloads`,
    `/favorites`, `/athkar`, `/athkar/:categoryId`, `/qibla`, `/bookmarks`, `/splash`
  - No `app_links`, `firebase_dynamic_links`, or `uni_links` dependency found in `pubspec.yaml`

### 1.9 Notifications Infrastructure
- **Status**: FCM push notifications + local notifications implemented
- **Evidence**:
  - `apps/tilawa/lib/features/notifications/presentation/services/fcm_service.dart`
  - `apps/tilawa/lib/core/services/notification_dispatcher.dart` — uses
    `FlutterLocalNotificationsPlugin`
  - `apps/tilawa/lib/core/config/notification_config.dart`
  - `apps/tilawa/lib/core/services/notification_permission_service.dart`
  - `permission_handler: ^12.0.1` in `apps/tilawa/pubspec.yaml`

### 1.10 Other Confirmed Features
| Feature | Evidence |
|---|---|
| Bookmarks | `apps/tilawa/lib/features/bookmarks/` |
| History | `apps/tilawa/lib/features/history/` |
| Downloads | `apps/tilawa/lib/features/downloads/` |
| Reciters | `apps/tilawa/lib/features/reciters/` |
| Playlists | `apps/tilawa/lib/features/playlists/` |
| Qibla | `apps/tilawa/lib/features/qibla/` |
| Auth (Google Sign-in) | `apps/tilawa/lib/features/auth/` |
| Settings | `apps/tilawa/lib/features/settings/` |
| Onboarding (3 screens) | `apps/tilawa/lib/features/onboarding/presentation/screens/onboarding_screen.dart` |
| Theme / Color picker | `apps/tilawa/lib/features/theme/`, `apps/tilawa/lib/features/color_picker/` |
| Localization AR/EN | `apps/tilawa/lib/l10n/` |

---

## Part 2: Not Found in Codebase

These features were absent in direct codebase inspection.

| Feature | What Was Checked | Status |
|---|---|---|
| **In-app review prompt** | `pubspec.yaml` (no `in_app_review` package); no `InAppReview` class found | ❌ Not present |
| **Video watermark / branding** | `video_service.dart` filter graph; `ffmpeg_kit_runner.dart` | ❌ Not present |
| **App Links / Deep Link handler** | `pubspec.yaml`; no `app_links`, `firebase_dynamic_links`, `uni_links` | ❌ Not present |
| **Verse translation data** | `quran.json` ayah keys: `number, text, numberInSurah, juz, manzil, page, ruku, hizbQuarter, sajda` (no `translation`) | ❌ Not present |
| **Tafsir feature** | Searched all feature directories and domain entities | ❌ Not present |
| **Juz Browser UI** | Searched all feature directories; juz data is in `quran.json` and `ayah_entity.dart` | ❌ Not present |
| **Verse-by-verse audio sync** | Searched for `verseSync`, `playingAyah`, `highlightAyah` across all dart files | ❌ Not present |
| **Cloud sync (bookmarks/favorites/playlists)** | Searched for `SyncService`, `syncFavorites`, Firestore collection writes outside premium | ❌ Not present |
| **Payment SDK integration** | `purchaseSubscription()` writes to Firestore only; no RevenueCat/`in_app_purchase` | ❌ Not present |
| **Prayer adhan scheduling** | Searched `prayer_times` feature for `zonedSchedule` / notification scheduling | ❌ Not present |
| **Permission request in onboarding** | `permission_handler` not used in `onboarding_screen.dart` or any onboarding widget | ❌ Not present |
| **Extended athkar categories** | `athkar.json` has only 2 categories (morning, evening) | ❌ Not present |

---

## Part 3: Assumptions Requiring Validation

These items could not be fully verified or denied from static analysis alone.

| Assumption | How to Validate |
|---|---|
| Prayer time notification toggle: Does a UI toggle exist that is meant to trigger scheduling? | Manual app run + inspect `PrayerNotificationSettings` state management wiring |
| Premium screen visibility: Is the premium screen reachable from the app home/menu? | Manual app run or UI flow trace through router + home screen widgets |
| Reel aspect ratio: Are generated videos 9:16 for Instagram/TikTok Story format? | Check `video_service.dart` output dimensions in `_outputVideoWidth` / `_outputVideoHeight` |
| Bookmarks sync: Do bookmarks persist to Firestore or only to local Hive/HydratedBloc? | Trace `BookmarksRepository` datasource to determine local-only vs remote storage |
| Push notification payloads: Do FCM notifications deep-link into specific screens? | Check `fcm_notification_handler_service.dart` routing logic |
| Translation API: Is there any planned or documented API integration for translations? | Check `quran_reader_repository.dart` for any translation fetch methods |
| Google Play listing: Are Arabic screenshots currently published? | Manual Play Console inspection |

---

## Part 4: Missing Features — Classified

### 4.1 In-App Review Prompt

**Why it matters**: The Play Store ranking algorithm weights ratings heavily. Without prompting
satisfied users to rate the app, organic discovery is suppressed. Apps without visible ratings
convert at lower rates from search impressions.

**Evidence**: No `in_app_review` package in `pubspec.yaml`. No `InAppReview.instance` call found.

**Suggested implementation approach**:
1. Add `in_app_review: ^2.0.9` to `apps/tilawa/pubspec.yaml`
2. Create `ReviewRequestService` in `apps/tilawa/lib/core/services/`
3. Trigger after: user completes first full surah listening session (≥3 min), or completes
   3 athkar sessions, or returns on day 3+ — whichever comes first and only once per 90 days
4. Never show during Quran reading — disrespectful to the user context

**Clean Architecture**:
- New use case: `RequestReviewUseCase` in core domain
- `ReviewRequestService` at data layer wrapping `in_app_review`
- Triggered from `AudioPlayerBloc` listener or `AthkarCubit` completion state

**Priority**: Critical
**Effort**: Small (1–2 days)
**Growth impact**: High (directly affects Play Store rating and discoverability)
**Retention impact**: Low (does not change app behavior)
**Technical complexity**: Low
**Islamic sensitivity**: Medium — must not interrupt Quran reading or active dhikr

---

### 4.2 Reel Watermark / Viral Attribution

**Why it matters**: Users who share Tilawa reels to Instagram, TikTok, and WhatsApp are the
primary organic distribution channel. Without a visible app name or download link, viewers
have no path to discover and install the app.

**Evidence**: `video_service.dart` filter graph has no `drawtext` filter. The only Tilawa
attribution is `album="Tilawa"` in audio metadata, which is invisible to social media viewers.

**Suggested implementation approach**:
1. Add `drawtext` ffmpeg filter to `video_service.dart` `_buildSingleImageCommand()` and
   `_buildSlideshowCommand()` — a subtle bottom-right attribution such as "Tilawa — تلاوة"
2. Optionally add the app's branded icon as a PNG overlay using ffmpeg `-i` input + `overlay=`
3. Make watermark style configurable (on/off, position) in share settings

**Clean Architecture**:
- Modify `VideoService._buildSingleImageCommand()` and `_buildSlideshowCommand()` to accept a
  watermark config parameter from the domain layer
- New `WatermarkConfig` entity in share domain
- `ShareRepository` passes config through from presentation settings

**Priority**: Critical
**Effort**: Small (1–2 days)
**Growth impact**: High (viral attribution with no engineering dependency on stores)
**Retention impact**: None
**Technical complexity**: Low (ffmpeg filter addition only)
**Islamic sensitivity**: Low — attribution text does not interfere with Quranic content

---

### 4.3 Verse Translation

**Why it matters**: The largest global Quran app user segment is non-Arabic speakers. Without
translation, Tilawa is inaccessible to the English, Urdu, French, Indonesian, and Turkish-speaking
Muslim communities — representing the majority of the global Muslim population.

**Evidence**:
- `ayah_entity.dart` has `String? translation` field — data model is ready
- `surah_content_entity.dart` has `WordTranslation? translation`
- `quran.json` ayah objects have NO translation key — only `text` (Arabic)
- `quran_reader_repository.dart` has no translation fetch method found

**Suggested implementation approach**:
1. Bundle English translation (e.g., Sahih International from alquran.cloud API or bundled JSON)
   in `apps/tilawa/assets/data/quran_en.json`
2. Extend `QuranDatasource` to load translation file
3. Populate `AyahEntity.translation` from the bundled source
4. Add toggle in reader settings: show/hide translation below each ayah
5. Later: add language selection and secondary bundled translations (Urdu, French)

**Clean Architecture**:
- New `LoadTranslationUseCase` in `quran_reader/domain/usecases/`
- `QuranDatasource` extended to load separate translation asset
- `ReaderSettingsEntity` extended with `showTranslation: bool` and `translationLanguage: String`

**Priority**: Critical
**Effort**: Medium (3–5 days for English-only bundle)
**Growth impact**: Very High (unlocks non-Arabic speaking user base)
**Retention impact**: High (users can study, not just listen)
**Technical complexity**: Medium
**Islamic sensitivity**: High — translation source and accuracy must be carefully selected and
  attributed (e.g., "Translation: Sahih International")

---

### 4.4 Prayer Time Adhan Notifications (Complete the existing model)

**Why it matters**: `PrayerNotificationSettings` entity is fully defined with per-prayer
notification fields. Users who see settings for prayer notifications and enable them will expect
adhan alerts. A settings field that appears functional but does nothing is a trust-damaging bug.

**Evidence**:
- `prayer_settings_entity.dart` defines `PrayerNotificationSettings` for all 5 prayers
- No `zonedSchedule` call found in `prayer_times` feature
- `athkar_notification_service.dart` already demonstrates the scheduling pattern

**Suggested implementation approach**:
1. Create `PrayerAdhanNotificationService` in `apps/tilawa/lib/core/services/` following the
   pattern of `AthkarNotificationService`
2. Schedule per-prayer `zonedSchedule` notifications using the calculated prayer times from
   `PrayerTimesRepository`
3. Respect `PrayerNotificationSettings.isEnabled` toggle per prayer
4. Reschedule when location changes or settings change

**Clean Architecture**:
- New `SchedulePrayerNotificationsUseCase` in `prayer_times/domain/usecases/`
- `PrayerAdhanNotificationService` at `core/services/` (follows existing pattern)
- Hook into `PrayerTimesCubit` state changes to trigger reschedule

**Priority**: High
**Effort**: Medium (2–4 days)
**Growth impact**: Medium (existing users, not new users)
**Retention impact**: High (daily re-engagement touchpoint)
**Technical complexity**: Medium
**Islamic sensitivity**: Very High — adhan audio selection, volume, and timing are sensitive. Must
  respect user-selected calculation method and local timezone.

---

### 4.5 Notification Permission Request in Onboarding

**Why it matters**: `permission_handler: ^12.0.1` is already in `pubspec.yaml`.
`notification_permission_service.dart` exists. But onboarding's 3 screens make no permission
request. Users who skip the notification permission dialog (presented cold by the OS) rarely
grant it retroactively. The permission must be requested in context, explaining value first.

**Evidence**:
- `permission_handler: ^12.0.1` in `apps/tilawa/pubspec.yaml`
- `apps/tilawa/lib/core/services/notification_permission_service.dart` exists
- `apps/tilawa/lib/features/onboarding/presentation/screens/onboarding_screen.dart` — no
  `Permission.` or `requestPermission` call found

**Suggested implementation approach**:
1. Add a 4th onboarding page (or an overlay before the final CTA) explaining:
   "Get reminders for Fajr, morning Athkar, and Quran time"
2. Call `NotificationPermissionService.requestPermission()` when user accepts
3. Skip gracefully if denied — do not block onboarding completion

**Clean Architecture**:
- Extend `OnboardingCubit` with a `requestNotificationPermission()` action
- `OnboardingPage` P4 added with dedicated content widget

**Priority**: High
**Effort**: Small (1–2 days)
**Growth impact**: Medium (improves notification opt-in rate, which drives re-engagement)
**Retention impact**: High (foundational for all notification-based retention)
**Technical complexity**: Low
**Islamic sensitivity**: Low

---

### 4.6 Juz Browser / Navigation

**Why it matters**: Navigating the Quran by Juz is the most common access pattern during
Ramadan and for users doing khatm (completing the Quran). The data is fully available.

**Evidence**:
- `quran.json` has `juz` field per ayah
- `ayah_entity.dart` has `int? juz` field
- `get_start_page_for_surah_use_case.dart` — existing navigation use case pattern to follow
- No Juz-level screen or use case found in `quran_reader` feature

**Suggested implementation approach**:
1. New `GetJuzListUseCase` — derives juz→page mapping from existing `quran.json`
2. New `JuzBrowserScreen` in `quran_reader/presentation/screens/`
3. Add `/juz` route to `app_router.dart`
4. Navigation from Quran Reader home (alongside surah list)

**Clean Architecture**:
- `GetJuzListUseCase` returns `List<JuzInfo>` (juz number, starting page, starting surah)
- No new data dependency — all derived from existing `quran.json`
- `JuzInfo` as a new domain entity

**Priority**: High
**Effort**: Small–Medium (2–3 days)
**Growth impact**: Medium (Ramadan seasonal spike, khatm tracker prerequisite)
**Retention impact**: High
**Technical complexity**: Low (data already exists)
**Islamic sensitivity**: Low

---

### 4.7 Extended Athkar Categories

**Why it matters**: Athkar infrastructure is fully wired to load from JSON. Only 2 of the
expected ~10 Islamic athkar categories are present. Adding data alone unlocks the feature.

**Evidence**:
- `athkar.json` has only `أذكار الصباح` and `أذكار المساء`
- `AthkarLocalDataSourceImpl.getCategories()` reads from the same JSON
- The docs/missing_features.md documents 10 expected categories (sleep, waking, after-prayer, wudu,
  travel, food, mosque, ruqyah, duas from Quran, duas from Sunnah)

**Suggested implementation approach**:
1. Add missing categories and their items to `apps/tilawa/assets/data/athkar.json`
2. No code changes required — the infrastructure reads any number of categories
3. Verify Arabic text accuracy with an Islamic scholar before shipping

**Clean Architecture**:
- Data-only change — no new use cases or entities required
- Source for athkar content: Hisnul Muslim (حصن المسلم) — widely accepted collection

**Priority**: High
**Effort**: Small (1–2 days, mainly content authoring and verification)
**Growth impact**: Medium (increases feature richness visible in screenshots)
**Retention impact**: High (more daily-use entry points)
**Technical complexity**: Very Low
**Islamic sensitivity**: Very High — content accuracy and attribution are critical

---

### 4.8 Verse-by-Verse Audio Highlighting (Sync)

**Why it matters**: This is the signature feature of Quran.com and Tarteel. It turns passive
listening into active learning. It is the single most-requested feature in Arabic Quran apps.

**Evidence**: No `playingAyah`, `verseSync`, or `highlightAyah` found anywhere in the codebase.
The audio player and Quran reader are independent features with no synchronization layer.

**Suggested implementation approach**:
1. Requires per-ayah timestamp data for each reciter (e.g., from EveryAyah.com or tarteel.ai
   open datasets)
2. New `AyahTimestampRepository` to load/cache timestamp data per reciter per surah
3. `AudioPlayerBloc` emits `currentAyahIndex` derived from position + timestamp lookup
4. `QuranReaderCubit` listens to `AudioPlayerBloc` stream and scrolls/highlights active ayah
5. Highlight rendered via a wrapper widget around each ayah's `RichText`

**Clean Architecture**:
- New cross-feature dependency: `audio_player` → `quran_reader` communication via a shared
  `CurrentPlaybackPositionStream` in core domain
- `AyahTimestampEntity` in shared domain
- Coordination via BLoC-to-BLoC listening or a mediator service

**Priority**: High (medium-term)
**Effort**: Large (2–4 weeks including data sourcing)
**Growth impact**: High (strong differentiator in store description and screenshots)
**Retention impact**: Very High (transforms casual listeners into daily learners)
**Technical complexity**: High
**Islamic sensitivity**: Low

---

### 4.9 Tafsir

**Why it matters**: Arabic-speaking users seeking deeper study are underserved without tafsir.
This is a core feature of Quran.com, Muslim Pro, and every major Quran app competitor.

**Evidence**: No tafsir feature directory, entity, or data file found in the codebase.

**Suggested implementation approach**:
1. Bundle Ibn Kathir summary (abridged) in Arabic as the first tafsir
2. Fetch from alquran.cloud API or bundle offline
3. New `TafsirFeature` following existing Clean Architecture pattern
4. Display as expandable panel below ayah in Quran Reader

**Clean Architecture**:
- New `packages/tafsir/` module or `apps/tilawa/lib/features/tafsir/` feature directory
- `GetTafsirForAyahUseCase(surahNumber, ayahNumber)` in domain
- Offline-first with bundled data, optional API for additional sources

**Priority**: Medium
**Effort**: Large (1–2 weeks)
**Growth impact**: High (study users have very high retention)
**Retention impact**: High
**Technical complexity**: Medium
**Islamic sensitivity**: High — tafsir source selection must be clearly attributed

---

### 4.10 App Store Optimization (ASO)

**Why it matters**: ASO is the highest-leverage, zero-code growth lever. A well-optimized Play
Store listing converts more impressions to installs.

**Evidence**: Cannot be verified from codebase — requires manual Play Console inspection.

**Recommended actions** (cannot be confirmed or denied from code):
1. **App subtitle**: Add a keyword-rich subtitle (30 chars) — e.g., "Quran Recitation & Athkar"
2. **Short description**: Lead with primary value proposition in Arabic and English
3. **Long description**: Feature list in both languages; mention QCF4 rendering, top reciters,
   reel sharing, prayer times, athkar — using terms users actually search
4. **Screenshots**: 5–8 screenshots showing: Quran reader page, reciter list, audio player,
   prayer times, athkar screen, share/reel — with Arabic captions on device frames
5. **Store icon**: Ensure 512×512 high-contrast icon is optimized
6. **Arabic listing**: Create Arabic-language Play Store listing alongside English

**Priority**: Critical (zero code, immediate action)
**Effort**: Small (design + copy effort, no engineering)
**Growth impact**: High (affects all discovery channels simultaneously)
**Retention impact**: None
**Technical complexity**: None
**Islamic sensitivity**: Low

---

### 4.11 Ethical Monetization → Support Tilawa

**Canonical spec (read first):** [`specs/016-support-tilawa/spec.md`](../016-support-tilawa/spec.md)

**Why it matters**: Tilawa must remain trustworthy for worship. Monetization is
**voluntary support**, not a premium subscription funnel. Core Quran, prayer, and
athkar access stay free forever.

**Historical evidence (superseded for MVP):** Legacy `features/premium` used a
Firestore stub (`purchaseSubscription()` without Play verification). MVP replaces
that pattern with **Google Play Billing + `verifySupportPurchase` Cloud Function**.
Do not reintroduce client-only Firestore completion as purchase truth.

**Product philosophy**:
- Positioning: *A respectful Quran and worship app that stays calm, beautiful,
  and ad-free because users voluntarily support it.*
- User-facing vocabulary: **Support Tilawa / Supporter** — not Premium, Pro, VIP,
  Unlock, or Upgrade.
- No intrusive monetization, worship interruption, feature gating, or dark patterns.

**MVP scope (Android)** — see spec §4:
- Google Play **consumable** one-time tiers only (`support_once_small|kind|generous`)
- Settings / About / Profile entry only; **no** reader or prayer prompts
- Lightweight server verification; **no** entitlement mirror or subscriptions in MVP
- Feature flag: `TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED`

**Post-MVP roadmap (separate specs required)**:
1. Optional monthly “sustain Tilawa” subscription (Play subscriptions + RTDN)
2. **Cloud sync** — additive perk, not a worship gate
3. **Cosmetic perks** — private Settings badge, themes (never gate Quran/prayer)
4. Early access to new reciters — only if clearly additive

**Deferred / out of policy**: RevenueCat until iOS need is proven; download quotas
as paywall; ads on worship surfaces (default: no ads).

**Priority**: Medium (MVP support behind feature flag until Play + Function verified)
**Effort**: Medium (MVP) → Large (subscriptions + entitlements later)
**Growth impact**: Medium (sustainability, not discovery)
**Retention impact**: Low if ethics are preserved; **negative** if worship is gated
**Technical complexity**: Medium (MVP billing + verify) / High (post-MVP entitlements)
**Islamic sensitivity**: Very High — ethics doc is binding via spec 016

---

### 4.12 Cloud Sync

**Why it matters**: Users who change devices or reinstall lose all bookmarks, favorites, and
playlists. Firestore infrastructure is already in place from the auth and premium features.

**Evidence**: No `SyncService`, `syncBookmarks`, `syncFavorites`, or Firestore write calls
found in the bookmarks, history, favorites, or playlists features.

**Suggested implementation approach**:
1. `CloudSyncRepository` that mirrors local HydratedBloc state to Firestore collections
2. Triggered on auth state changes (sign-in syncs down, state changes sync up)
3. Conflict resolution: last-write-wins with timestamp

**Clean Architecture**:
- New `SyncService` in `core/services/`
- Each feature's `Repository` receives an optional `CloudSyncRepository` dependency
- Sync only when user is authenticated

**Priority**: Medium
**Effort**: Large
**Growth impact**: Medium
**Retention impact**: High (reduces churn from device changes)
**Technical complexity**: High
**Islamic sensitivity**: Low

---

## Part 5: Quick Wins (Next Sprint — Q2 2026)

These items have high impact-to-effort ratios and can be completed within one sprint.

| # | Feature | Priority | Effort | Key Evidence |
|---|---|---|---|---|
| QW-1 | In-app review prompt (`in_app_review` package) | Critical | Small | Package not in pubspec |
| QW-2 | Reel watermark / branding in `video_service.dart` | Critical | Small | No `drawtext` in filter graph |
| QW-3 | Notification permission in onboarding (page 4) | High | Small | `permission_handler` unused in onboarding |
| QW-4 | Extend `athkar.json` with 8+ new categories | High | Small | Only 2 categories in data file |
| QW-5 | ASO update: screenshots, subtitle, description | Critical | Small (no code) | Cannot verify from code |
| QW-6 | Juz Browser screen | High | Small–Medium | Data already in `quran.json` |

---

## Part 6: Medium-Term Roadmap (Q3–Q4 2026)

| Priority | Feature | Effort | Dependency |
|---|---|---|---|
| Critical | Verse Translation (English bundle) | Medium | `ayah_entity.dart` already has `translation` field |
| High | Prayer Adhan Scheduling | Medium | `PrayerNotificationSettings` entity already defined |
| High | Verse-by-Verse Audio Highlighting | Large | Requires timestamp data sourcing |
| Medium | Payment SDK Integration (for premium) | Large | Required before monetization launch |
| Medium | Cloud Sync (bookmarks, favorites) | Large | Firestore auth infra already present |
| Medium | Tafsir (Ibn Kathir, Arabic bundle) | Large | No existing infrastructure |

---

## Part 7: Long-Term Roadmap (2027 and beyond)

| Feature | Strategic Value |
|---|---|
| Multi-language translation (Urdu, French, Indonesian) | Unlock global Muslim markets |
| Ramadan Mode (khatm tracker, Tarawih playlist, countdown) | Seasonal 2–5× install spike |
| Home screen widget (prayer countdown, last-played reciter) | Daily active touchpoint |
| Khatm (complete Quran) tracker with progress visualization | Long-term retention driver |
| Tajweed error detection (ML-assisted, like Tarteel) | Unique differentiator |
| Multiple Quran scripts (IndoPak, Naskh variants) | Expanded script support |
| Community / social layer (shared playlists, scholar recommendations) | Network effects |

---

## Part 8: Risks and Assumptions

| Risk / Assumption | Type | Mitigation |
|---|---|---|
| Premium payment stub may confuse users if premium screen is accessible | Risk | Audit premium screen entry points; gate behind feature flag until payment SDK is integrated |
| `purchaseSubscription()` writes `status: completed` to Firestore without payment | Critical Risk | Do NOT expose premium purchase UI until real payment SDK is integrated |
| Prayer notification toggle may exist in UI but silently do nothing | Assumption | Verify via manual run; add warning/TODO comment in `PrayerTimesScreen` |
| Translation content accuracy — wrong or controversial translations can damage trust | Risk | Use widely accepted, attributed translations only (Sahih International, Pickthall) |
| Athkar content expansion requires Islamic scholar review | Assumption | Budget for scholarly review before publishing new athkar categories |
| App deep links (`/reciter/:reciterId`) work as internal navigation but not from external URLs | Assumption | Verify with `adb shell am start` test before claiming deep link support |
| Reel video aspect ratio may not match Instagram Story (9:16) | Assumption | Check `_outputVideoWidth`/`_outputVideoHeight` in `video_service.dart` |
| No analytics data is available to validate impact estimates | Context | All impact classifications in this document are qualitative (High/Medium/Low), not quantitative percentages |

---

## Part 9: Final Prioritized Action Plan

### Sprint 1 (immediate — Q2 2026)
1. **QW-5**: Update Play Store ASO (screenshots, subtitle, Arabic listing) — no code
2. **QW-1**: Add `in_app_review` and trigger after first listening session
3. **QW-2**: Add `drawtext` watermark to `video_service.dart` reel pipeline
4. **QW-3**: Add notification permission request to onboarding flow
5. **QW-4**: Expand `athkar.json` with 8+ new categories (content + review required)
6. **QW-6**: Implement Juz Browser screen

### Sprint 2 (Q3 2026)
7. Verse Translation (English bundle in `quran.json` → `ayah_entity.translation`)
8. Prayer Adhan Scheduling (complete the wired-but-unused `PrayerNotificationSettings`)
9. Audit and gate premium screen behind feature flag until payment SDK is integrated

### Sprint 3 (Q3–Q4 2026)
10. Verse-by-Verse Audio Highlighting (requires timestamp data sourcing)
11. Payment SDK integration (prerequisite for monetization)
12. Cloud Sync for bookmarks and favorites

### Long Term (2027)
13. Tafsir
14. Ramadan Mode
15. Multi-language translations
16. Khatm tracker

---

## Assumptions

- All impact estimates in this document use qualitative classifications (High/Medium/Low/Very High)
  only. No numeric percentages are included unless backed by linked research.
- "Confirmed" means verified by file path inspection or code content grep. It does not mean
  "working correctly in production" — only that the implementation exists in the codebase.
- "Not found" means a systematic search was performed and no evidence was found. It does not
  exclude dead branches or commented-out code that was not reached.
- Content accuracy for athkar, translation, and tafsir requires Islamic scholarly review
  before shipping — this is a product requirement, not just a legal one.
- This spec does not prescribe UI designs or UX flows. Each quick win will require its own
  implementation task once approved.

---

## User Scenarios & Testing

### User Story 1 — In-App Review Prompt (Priority: P1)

A user has been using Tilawa daily for 3+ days and has completed at least one full surah
listening session. The app surfaces a native OS review dialog (via `in_app_review`).

**Independent Test**: Can be tested by mocking the "3 sessions completed" trigger and
verifying the review dialog appears once and never re-appears within 90 days.

**Acceptance Scenarios**:
1. **Given** user has completed 3+ listening sessions, **When** app foregrounds on day 3+,
   **Then** review dialog is shown once via `InAppReview.requestReview()`
2. **Given** review dialog was already shown, **When** trigger fires again within 90 days,
   **Then** review dialog is NOT shown
3. **Given** user is actively reading Quran, **When** trigger fires,
   **Then** review dialog is deferred until Quran reader is closed

---

### User Story 2 — Reel Watermark (Priority: P1)

A user creates and shares a reel. The exported MP4 has a subtle "Tilawa — تلاوة" text
overlay in a corner that is visible when played on social media.

**Independent Test**: Generate a reel and inspect the MP4 with VLC or ffprobe to confirm
watermark text is rendered in the video frames.

**Acceptance Scenarios**:
1. **Given** user exports a reel, **When** the MP4 is played, **Then** "Tilawa — تلاوة"
   is visible in a corner at readable opacity
2. **Given** user has disabled watermark in settings (if toggle implemented),
   **When** reel is exported, **Then** no watermark appears
3. **Given** watermark font is missing on device, **When** reel is exported,
   **Then** export does not fail (fallback gracefully)

---

### User Story 3 — Verse Translation (Priority: P2)

A non-Arabic speaking user opens Surah Al-Fatiha in the Quran reader and sees the English
translation below each ayah.

**Independent Test**: Open Quran reader with translation toggle ON and verify English text
appears below ayah 1 of Al-Fatiha.

**Acceptance Scenarios**:
1. **Given** translation is enabled in reader settings, **When** Quran reader opens,
   **Then** English translation is displayed below each Arabic ayah
2. **Given** app is offline, **When** translation is enabled,
   **Then** bundled translation is shown (no network required)
3. **Given** translation is disabled in settings, **When** Quran reader opens,
   **Then** no translation text is shown

---

### Edge Cases

- What happens if `in_app_review` is unavailable (simulator or Play Store version too old)?
  → Fall back gracefully; never crash
- What happens if `drawtext` ffmpeg filter fails (font not found on device)?
  → Export succeeds without watermark; log warning; do not show user error
- What happens if `athkar.json` is malformed after content update?
  → App falls back to showing "no categories" rather than crashing
- What happens if translation bundle is missing or corrupt?
  → Show Arabic text only; do not block Quran reader launch
- RTL: All new screens must support RTL (Arabic) layout
- Low memory: New data loading (translation JSON) must not cause OOM on 2GB RAM devices

---

## Requirements

### Functional Requirements (Sprint 1 scope)

- **FR-001**: System MUST display native OS review prompt after user meets engagement threshold
  (minimum 3 completed listening sessions) and MUST NOT repeat within 90 days
- **FR-002**: System MUST embed visible app attribution text in all exported reel videos
- **FR-003**: System MUST request notification permission during onboarding with contextual
  explanation before triggering the OS permission dialog
- **FR-004**: App MUST include at least 10 athkar categories with accurate, attributed Islamic
  content in `athkar.json`
- **FR-005**: System MUST provide a Juz Browser screen allowing users to navigate to any of
  the 30 Juz and begin reading from the correct page
- **FR-006**: System MUST display ayah translation (English) in the Quran reader when enabled
  in settings, using bundled offline data

### Key Entities

- **ReviewTriggerState**: tracks sessions completed, last review prompt date
- **WatermarkConfig**: watermark text, position, opacity, font, enabled/disabled
- **JuzInfo**: juz number, starting page, starting surah number and name
- **AyahTranslation**: surah number, ayah number, language code, translation text

---

## Success Criteria

- **SC-001**: In-app review prompt is shown to eligible users and is never shown during active
  Quran reading
- **SC-002**: All exported reels include visible Tilawa attribution text
- **SC-003**: Onboarding includes a notification permission request page with accept/decline
- **SC-004**: Athkar feature displays at least 10 categories populated with verified content
- **SC-005**: Juz Browser lists all 30 Juz and navigates to the correct Quran reader page
- **SC-006**: Verse translation renders correctly in RTL/LTR contexts and is available offline
