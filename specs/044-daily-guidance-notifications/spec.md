# Feature Specification: Daily Ayah & Hadith Notifications

**Feature Branch**: `042-daily-guidance-notifications`

**Created**: 2026-07-12

**Status**: Draft

**Product**: MeMuslim — أنا مسلم

**Feature Name**: Daily Guidance / نفحة اليوم

**Primary Platforms**: Android and iOS

**Initial Languages**: Arabic and English

---

## Executive Summary

MeMuslim will introduce an optional daily notification that delivers one carefully reviewed Islamic guidance item to the user. The daily item may be a Quran verse, an authentic Prophetic hadith, or a short approved explanation. The feature encourages consistent, meaningful engagement with the Quran and Sunnah without manipulative engagement techniques, guilt-based messaging, gambling-like rewards, or unsupported religious claims.

Content varies day to day within boundaries of verified Islamic sources, editorial and scholarly review, user-controlled preferences, anti-repetition rules, privacy-safe personalization, and respectful non-clickbait messaging. The feature shall be presented as **Daily Guidance** or **نفحة اليوم**, never as a game, prize, or random reward.

---

## Problem Statement

Users want to maintain a daily spiritual connection but may not consistently open the application without a gentle reminder. Existing patterns often suffer from: repetitive notifications, unsourced content, unclear hadith authenticity, decontextualized verses, guilt/fear/manipulative language, unsuitable timing, excessive repetition, broken deep links, poor user control, and religious data over-collection.

MeMuslim needs a trusted daily guidance experience that encourages voluntary engagement while preserving user choice, religious integrity, privacy, accessibility, and platform reliability.

---

## Product Vision

Provide each user with one small, trustworthy, and meaningful daily connection to the Quran or authentic Sunnah.

The experience should feel like a gentle daily spiritual reminder from a trusted Islamic application.

It must **not** feel like a gambling mechanic, loot box, retention trap, guilt-based notification, algorithm claiming to know the user's spiritual condition, or a claim that Allah specifically selected a certain message for the user.

---

## Product Principles

- **Trust Before Engagement**: Religious correctness and source integrity outweigh notification open rate, session duration, or retention.
- **User Control**: The user controls enablement, time, days, content type, sound/vibration, and topic personalization.
- **One Notification, One Purpose**: No more than one scheduled Daily Guidance notification per user-local calendar day.
- **Respectful Variation**: Content variation creates discovery, not addiction. No artificial scarcity, countdown pressure, rare-item mechanics, loss aversion, shame, or fear-based re-engagement.
- **Transparent Religious Sourcing**: Every Quran verse and hadith must have a visible, reviewable source.
- **Privacy by Default**: The system must not infer or store sensitive spiritual conclusions about the user.

---

## Target Users

- **Regular MeMuslim User**: Wants a gentle daily reminder without a structured Quran plan.
- **Quran-Focused User**: Prefers Quran verses and may want to open the Mushaf, listen to recitation, or read a short explanation.
- **Sunnah-Focused User**: Prefers authentic hadith and wants source and authenticity information.
- **Privacy-Conscious User**: Wants useful notifications without creating an account or sharing detailed religious activity.
- **Accessibility User**: Relies on screen readers, larger text, simplified interaction, or reduced motion.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Enable Daily Guidance (Priority: P1)

A MeMuslim user enables one daily Islamic reminder to maintain a small daily connection with the Quran and Sunnah.

**Why this priority**: This is the foundational flow — without opt-in, no other feature behavior is relevant. It delivers the core value of connecting users to daily guidance.

**Independent Test**: Can be fully tested by enabling the feature, granting notification permission, and verifying the next notification is scheduled at the selected local time.

**Acceptance Scenarios**:

1. **Given** Daily Guidance is disabled, **When** the user enables it and notification permission is available, **Then** the app requests permission only after explaining why it is needed.
2. **Given** the user grants notification permission, **When** setup is completed, **Then** the next eligible notification is scheduled using the user's selected local time.
3. **Given** the user denies notification permission, **When** the setup flow completes, **Then** the app clearly explains that Daily Guidance notifications cannot be delivered and provides a settings recovery path.
4. **Given** notification permission is permanently denied, **When** the user attempts to enable the feature, **Then** the app provides a direct and understandable path to system notification settings when supported.

---

### User Story 2 — Receive Daily Notification & View Content (Priority: P1)

A user receives a scheduled notification containing a Quran verse or authentic hadith, taps it, and opens the exact Daily Guidance detail screen with full source information, translation, and approved explanation.

**Why this priority**: This is the core delivery loop — scheduling, receiving, tapping, and viewing the complete item. Without this, the feature has no purpose.

**Independent Test**: Can be fully tested by enabling Daily Guidance, waiting for the scheduled time, verifying the notification arrives, tapping it, and confirming the detail screen shows the correct item with complete source metadata.

**Acceptance Scenarios**:

1. **Given** Daily Guidance is enabled and the scheduled time arrives, **When** the notification is delivered, **Then** it shows an approved title and short excerpt without clickbait or guilt.
2. **Given** the user taps the notification, **When** the app opens, **Then** the exact associated Daily Guidance item is displayed — not a different item.
3. **Given** the detail screen is opened, **When** the item is a Quran verse, **Then** the screen shows the canonical Arabic text, surah name, surah number, verse number, approved translation, and optional explanation clearly separated from the Quran text.
4. **Given** the detail screen is opened, **When** the item is a hadith, **Then** the screen shows the approved Arabic text, source collection, reference number, authenticity grade, grading source, approved translation, and optional explanation.
5. **Given** the app was terminated, **When** the user taps the notification (cold start), **Then** the correct detail screen still opens after startup.

---

### User Story 3 — Choose Content Type (Priority: P2)

A user chooses Quran only, Hadith only, or Mixed content so the daily reminder matches their preference.

**Why this priority**: Content-type selection is a core personalization lever that directly affects user satisfaction. Mixed is the default, but users must be able to restrict if desired.

**Independent Test**: Can be tested by selecting each mode and verifying the next delivered items match the selected type.

**Acceptance Scenarios**:

1. **Given** the user selects Quran only, **When** the next daily item is selected, **Then** only a published Quran item is eligible.
2. **Given** the user selects Hadith only, **When** the next daily item is selected, **Then** only a published and authenticity-approved hadith is eligible.
3. **Given** the user selects Mixed, **When** items are selected across multiple days, **Then** the system maintains a reasonable balance between Quran and Hadith.
4. **Given** the selected mode has no valid eligible item, **When** the system prepares the notification, **Then** it uses an approved fallback from the same content mode or skips delivery rather than presenting unverified content.

---

### User Story 4 — Select Notification Time (Priority: P2)

A user chooses when the notification arrives so it does not disturb at an unsuitable time.

**Why this priority**: Time control is essential for user comfort and respecting daily routines. Without it, users may disable the feature due to poorly timed interruptions.

**Independent Test**: Can be tested by setting a time, verifying the notification arrives around that time, changing the time, and confirming no duplicate is created.

**Acceptance Scenarios**:

1. **Given** the user selects a local time, **When** Daily Guidance is enabled, **Then** notifications are scheduled according to that local time.
2. **Given** the user changes the time, **When** the preference is saved, **Then** the previous future schedule is replaced and duplicate notifications are not created.
3. **Given** the operating system delays background execution, **When** exact delivery is unavailable, **Then** the notification may arrive within an acceptable platform-controlled window without requesting inappropriate alarm permissions.
4. **Given** the user changes timezone, **When** the application detects the new timezone, **Then** future notifications follow the selected local clock time without delivering a duplicate for the same local date.

---

### User Story 5 — Receive Non-Repetitive Content (Priority: P2)

A user expects the daily content to vary so the reminder remains meaningful and not repetitive.

**Why this priority**: Repetition is one of the top reasons users disable reminders. Anti-repetition directly impacts long-term engagement and perceived value.

**Independent Test**: Can be tested by receiving notifications over multiple days and verifying no content repeats within the configured 90-day window.

**Acceptance Scenarios**:

1. **Given** an item was delivered recently, **When** a new item is selected, **Then** the recently delivered item is excluded during the configured anti-repetition window.
2. **Given** enough eligible content exists, **When** the user receives notifications over 90 days, **Then** the same content is not delivered twice during that period.
3. **Given** the eligible content corpus is smaller than the anti-repetition window, **When** all valid items have been used, **Then** the system reuses the oldest eligible item and does not fail indefinitely.
4. **Given** the user opens the feature multiple times in one day, **When** the daily item is shown, **Then** the same item is displayed throughout that user-local day.

---

### User Story 6 — View Complete Source Information (Priority: P2)

A user wants to know where the verse or hadith comes from to trust the content.

**Why this priority**: Source transparency is a core trust requirement. Without it, the feature fails its religious integrity principle.

**Independent Test**: Can be tested by opening a Quran item and verifying surah name, number, and verse number are visible; opening a hadith item and verifying collection, reference, and authenticity grade are visible.

**Acceptance Scenarios**:

1. **Given** the item is a Quran verse, **When** the detail screen is opened, **Then** the surah name, surah number, and verse number are displayed.
2. **Given** the item is a hadith, **When** the detail screen is opened, **Then** the source collection and available reference identifier are displayed.
3. **Given** the item is a hadith, **When** authenticity information is available, **Then** the approved grading and grading source are displayed.
4. **Given** source information is incomplete, **When** an editor attempts to publish the item, **Then** publication is rejected.

---

### User Story 7 — Save or Share a Daily Item (Priority: P3)

A user saves or shares beneficial content to return to it or send it to others.

**Why this priority**: Save and share are secondary engagement actions that increase perceived value and word-of-mouth but are not required for core delivery.

**Independent Test**: Can be tested by saving an item and verifying it appears in saved content; sharing and verifying the shared output includes accurate text and source.

**Acceptance Scenarios**:

1. **Given** the user saves an item, **When** the save action succeeds, **Then** the item appears in the user's saved content.
2. **Given** the user shares an item, **When** the sharing flow opens, **Then** the shared content includes accurate text and source information.
3. **Given** an explanation is not approved for sharing, **When** the user shares the item, **Then** only the approved original content, translation, source, and MeMuslim attribution are included.
4. **Given** the user is offline, **When** the daily item has already been cached, **Then** it can still be viewed and shared using available local capabilities.

---

### User Story 8 — Disable or Pause the Feature (Priority: P2)

A user pauses or disables Daily Guidance easily to remain in control of notifications.

**Why this priority**: User control is a core principle. Users must be able to stop notifications without friction, or they will revoke all notification permission at the OS level.

**Independent Test**: Can be tested by disabling the feature and verifying no future notifications arrive; pausing until a date and verifying notifications resume after.

**Acceptance Scenarios**:

1. **Given** Daily Guidance is enabled, **When** the user disables it, **Then** future scheduled Daily Guidance notifications are cancelled.
2. **Given** the user pauses notifications until a selected date, **When** the pause period is active, **Then** no Daily Guidance notification is shown.
3. **Given** the pause period ends, **When** the next eligible day arrives, **Then** scheduling resumes without sending missed notifications.
4. **Given** the feature is disabled, **When** the user opens MeMuslim, **Then** the application does not repeatedly pressure the user to re-enable it.

---

### User Story 9 — Receive Occasion-Relevant Content (Priority: P3)

A user expects some reminders to reflect valid Islamic occasions so the daily content feels timely and useful.

**Why this priority**: Occasion relevance adds meaningful value but is an enhancement over the core daily delivery. The system works without it.

**Independent Test**: Can be tested by configuring an occasion-tagged item with a valid date window, verifying it receives priority on the correct date, and verifying it is excluded after the date window ends.

**Acceptance Scenarios**:

1. **Given** an approved date-specific content rule is active, **When** the daily item is selected, **Then** eligible occasion-specific content receives priority.
2. **Given** it is Friday according to the user's local date, **When** Friday-tagged approved content is available, **Then** the system may prioritize appropriate Friday content.
3. **Given** the Islamic date cannot be determined reliably, **When** content selection occurs, **Then** the system falls back to normal approved content.
4. **Given** a date-specific item is no longer valid, **When** its configured date window ends, **Then** it is excluded from selection.

---

### Edge Cases

- **Permission Denied**: Feature remains disabled for delivery but settings remain editable. The app may explain how to enable permission but must not repeatedly interrupt.
- **Device Restart**: Future notifications must be restored when platform behavior requires rescheduling. Restoration must not duplicate an already delivered local-date item.
- **Timezone Change**: The user's selected clock time remains the intended local time. Must prevent two notifications on one local date, late duplicates, and bulk delivery of missed reminders.
- **Daylight-Saving Changes**: Scheduling must follow the platform's valid local-time behavior. If the selected time does not exist on a DST transition day, deliver within the nearest safe window.
- **User Changes Time After Today's Delivery**: New time applies to future eligible dates. Must not send a second item on the same local date.
- **User Enables Feature After Selected Time**: Schedule starting from the next eligible day. No catch-up notification in MVP.
- **No Network at Scheduling Time**: Use a previously prepared and cached item. If no valid item exists locally, skip the day rather than send incomplete or unverified content.
- **Content Retired After Scheduling**: If retired for normal rotation, the scheduled item may remain accessible. If withdrawn for correctness/safety, cancel future delivery and show an appropriate unavailable or corrected state.
- **Corpus Exhaustion**: Reuse the oldest eligible item. Never use rejected or unreviewed content.
- **Application Reinstallation**: Local preferences and history may be lost. Reinstallation must not auto-enable notifications.
- **Multiple Devices**: Each device maintains its own local schedule in MVP. No cross-device locking required.
- **Unsupported Locale**: Use only content with approved localization. Never dynamically machine-translate Quran, hadith, or religious commentary.
- **Notification Truncation**: The excerpt must remain respectful and meaningful when shortened. Misleading truncation must not be used as notification copy.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Feature Enablement

- **FR-001**: System MUST keep Daily Guidance disabled until the user explicitly enables it.
- **FR-002**: System MUST explain the notification purpose before requesting operating-system permission.
- **FR-003**: System MUST persist the user's enablement preference.
- **FR-004**: System MUST allow the feature to work without requiring account creation.
- **FR-005**: System MUST expose Daily Guidance settings from the application's notification settings area.
- **FR-006**: System MUST allow the user to disable the feature with no more than three meaningful interactions from the Daily Guidance settings screen.

#### Scheduling

- **FR-007**: Users MUST be able to select a preferred local notification time.
- **FR-008**: Users MUST be able to select enabled days of the week.
- **FR-009**: System MUST deliver no more than one Daily Guidance notification per user-local date.
- **FR-010**: System MUST NOT send notifications for disabled days.
- **FR-011**: Changing the delivery time MUST replace the existing future schedule.
- **FR-012**: Disabling the feature MUST cancel future scheduled notifications.
- **FR-013**: System MUST NOT request exact-alarm privileges solely for Daily Guidance.
- **FR-014**: System MUST tolerate normal operating-system scheduling delays.
- **FR-015**: System MUST recalculate future delivery after a relevant timezone change.
- **FR-016**: System MUST avoid duplicate delivery during daylight-saving or timezone transitions.
- **FR-017**: Missed notifications MUST NOT be delivered in bulk.
- **FR-018**: System MUST respect operating-system notification channel and interruption settings.

#### Content Preferences

- **FR-019**: Users MUST be able to select Quran only, Hadith only, or Mixed.
- **FR-020**: System MUST use Mixed as the recommended default after opt-in.
- **FR-021**: Users MAY optionally select preferred topics.
- **FR-022**: Topic selection MUST be explicit and MUST NOT be inferred from sensitive behavior.
- **FR-023**: Users MUST be able to clear all topic preferences.
- **FR-024**: System MUST continue functioning when no topic preference is selected.

#### Daily Content Selection

- **FR-025**: Only reviewed and published items MUST be eligible for delivery.
- **FR-026**: The selected daily item MUST remain stable for the same user and local date.
- **FR-027**: Opening or refreshing the detail screen MUST NOT reroll the daily item.
- **FR-028**: Selection MUST respect the user's content-mode preference.
- **FR-029**: Selection MUST exclude retired, expired, blocked, or unapproved content.
- **FR-030**: Selection MUST apply the configured anti-repetition window.
- **FR-031**: The default anti-repetition target MUST be 90 days when the eligible corpus permits.
- **FR-032**: System MUST support a controlled fallback when the eligible corpus is exhausted.
- **FR-033**: Selection MUST be deterministic enough to prevent the same daily item from changing due to repeated application launches.
- **FR-034**: Occasion relevance MAY influence selection only through approved editorial metadata.
- **FR-035**: System MUST NEVER generate replacement religious content dynamically.
- **FR-036**: System MUST NOT use engagement-maximization algorithms to select emotionally manipulative religious content.

#### Quran Content

- **FR-037**: Every Quran item MUST include the canonical Arabic text.
- **FR-038**: Every Quran item MUST include surah number and verse number.
- **FR-039**: Every Quran item MUST include a reviewed display name for the surah.
- **FR-040**: Quran text MUST NOT be edited, paraphrased, or generated.
- **FR-041**: Any displayed translation MUST come from an approved translation source.
- **FR-042**: Translation text MUST be visually distinguishable from Quran text.
- **FR-043**: A short excerpt MAY be used in a notification only when it does not distort the verse's meaning.
- **FR-044**: The full verse MUST be available on the detail screen.
- **FR-045**: Any tafsir or explanation MUST identify its approved source or editorial provenance.
- **FR-046**: The application MUST NOT label commentary as Quran text.

#### Hadith Content

- **FR-047**: Every hadith item MUST include the original approved text.
- **FR-048**: Every hadith item MUST include its source collection.
- **FR-049**: Every hadith item MUST include an available hadith number or stable source reference.
- **FR-050**: Every hadith item MUST include authenticity information when applicable.
- **FR-051**: Every authenticity grade MUST include its approved grading source.
- **FR-052**: Weak, fabricated, unverifiable, or editorially disputed hadith MUST NOT be eligible for MVP delivery.
- **FR-053**: A hadith excerpt MUST NOT remove wording that changes the intended meaning.
- **FR-054**: The complete approved hadith text MUST be available from the detail screen.
- **FR-055**: Hadith translations MUST be reviewed before publication.

#### Notification Content

- **FR-056**: Notification titles and bodies MUST use approved editorial templates.
- **FR-057**: Notification content MUST avoid clickbait.
- **FR-058**: Notification content MUST avoid guilt, shame, or spiritual judgment.
- **FR-059**: Notification content MUST NOT claim that Allah selected a specific message for the user.
- **FR-060**: Notification content MUST NOT claim a guaranteed reward, forgiveness, healing, wealth, or outcome.
- **FR-061**: Notification text MUST remain understandable when truncated by the operating system.
- **FR-062**: Notification MUST identify MeMuslim through normal application branding without excessive promotional copy.
- **FR-063**: Notification copy MUST support right-to-left and left-to-right layouts.
- **FR-064**: Notification MUST NOT expose private user information on the lock screen.

#### Navigation and Detail Screen

- **FR-065**: Every notification MUST contain a stable reference to its selected item.
- **FR-066**: Tapping a notification MUST open the exact associated detail screen.
- **FR-067**: If the application is terminated, notification navigation MUST still resolve correctly after startup.
- **FR-068**: If the user is unauthenticated, public Daily Guidance content MUST remain accessible.
- **FR-069**: If the referenced item has been retired after delivery, the application MUST display a safe archived representation or an explanatory unavailable state.
- **FR-070**: The detail screen MUST display source information without requiring an additional tap.
- **FR-071**: The detail screen MUST provide save and share actions.
- **FR-072**: Quran items MAY expose Open in Mushaf and Listen actions.
- **FR-073**: Hadith items MAY expose related-source navigation.
- **FR-074**: The application MUST NOT automatically play audio when a notification is opened.

#### History and Saved Content

- **FR-075**: The system SHOULD maintain a local history of recently delivered items.
- **FR-076**: The user MUST be able to revisit a reasonable number of recent Daily Guidance items.
- **FR-077**: The system MUST distinguish delivered, opened, saved, and shared states internally without presenting worship scoring.
- **FR-078**: Deleting local application data MAY reset local Daily Guidance history.
- **FR-079**: Account-based cross-device history is outside MVP scope.
- **FR-080**: Saved items MUST NOT be removed merely because the editorial item is no longer selected for new users, unless content was withdrawn for integrity or safety reasons.

#### Offline Behavior

- **FR-081**: The application MUST cache sufficient approved data for the next scheduled item whenever practical.
- **FR-082**: A previously prepared notification MUST remain openable without a network connection when its content is cached.
- **FR-083**: If the exact content is unavailable offline, the app MUST display a clear offline state and MUST NOT silently show a different verse or hadith.
- **FR-084**: The application MUST NEVER fabricate missing source information while offline.
- **FR-085**: Network recovery MUST restore the intended item without requiring the user to re-enable the feature.

#### Pause and Disablement

- **FR-086**: The user MUST be able to disable Daily Guidance.
- **FR-087**: The user SHOULD be able to pause notifications temporarily.
- **FR-088**: A pause MUST NOT create a backlog of missed notifications.
- **FR-089**: Re-enabling MUST schedule only future eligible notifications.
- **FR-090**: Disabling Daily Guidance MUST NOT disable unrelated prayer, Athkar, Quran-plan, or system notifications.

#### Content Administration

- **FR-091**: Content MUST support Draft, In Review, Approved, Published, Retired, and Rejected states.
- **FR-092**: Only Published items MUST be eligible for delivery.
- **FR-093**: Publishing MUST require all mandatory source fields.
- **FR-094**: Publishing a hadith MUST require approved authenticity metadata.
- **FR-095**: Editors MUST be able to configure supported languages.
- **FR-096**: Editors MUST be able to configure content type and topic tags.
- **FR-097**: Editors MUST be able to configure optional valid date windows.
- **FR-098**: Editors MUST be able to retire an item from future selection.
- **FR-099**: Material edits to published religious text MUST require re-review.
- **FR-100**: The system MUST maintain an audit trail for publication, retirement, and material content changes.
- **FR-101**: The system MUST identify the reviewer or review authority for each approved content revision.
- **FR-102**: The content system MUST prevent accidental publication of incomplete items.
- **FR-103**: Emergency withdrawal MUST remove an item from future selection.
- **FR-104**: Emergency withdrawal MUST NOT replace an already delivered item with unrelated content without explaining the change.

#### Analytics and Privacy

- **FR-105**: Analytics MUST be limited to product-quality and feature-usage needs.
- **FR-106**: Analytics MUST NOT include full Quran or hadith text.
- **FR-107**: Analytics MAY use stable content identifiers and non-sensitive content-type metadata.
- **FR-108**: The system MUST NOT create inferred spiritual-health profiles.
- **FR-109**: The system MUST NOT infer sensitive conditions from notification interaction.
- **FR-110**: Topic preferences SHOULD remain local in MVP unless synchronization is explicitly approved.
- **FR-111**: The system MUST NOT sell or share Daily Guidance engagement data for advertising.
- **FR-112**: The feature MUST comply with the application's consent and analytics configuration.
- **FR-113**: Users who reject analytics consent MUST still be able to use Daily Guidance.
- **FR-114**: Logs MUST NOT contain full notification bodies, Quran text, hadith text, or unnecessary user identifiers.

#### Accessibility and Localization

- **FR-115**: All controls MUST have meaningful screen-reader labels.
- **FR-116**: Arabic Quran and hadith text MUST be read in the correct direction.
- **FR-117**: Mixed Arabic and Latin source references MUST render correctly.
- **FR-118**: The detail screen MUST support system text scaling without clipping critical content.
- **FR-119**: Core actions MUST remain usable at the application's supported maximum text scale.
- **FR-120**: Meaning MUST NOT rely on color alone.
- **FR-121**: Motion and celebration effects MUST respect reduced-motion preferences.
- **FR-122**: The feature MUST NOT use excessive animation for religious content.
- **FR-123**: Notification and detail-screen copy MUST be localized rather than mechanically concatenated.
- **FR-124**: Unsupported translations MUST be omitted rather than generated automatically.

### Key Entities

- **DailyGuidanceItem**: One approved deliverable content item. Includes identifier, content type (Quran/Hadith), publication status, original Arabic text, notification excerpt, short explanation, topic and occasion tags, available locales, valid date window, publication and retirement timestamps, revision number, source metadata, and review metadata.

- **QuranSourceMetadata**: Quran-specific source information. Includes surah number, surah Arabic name, ayah start/end, Quran text source identifier, translation source identifiers, and optional tafsir source identifier.

- **HadithSourceMetadata**: Hadith-specific source information. Includes collection name, book/chapter, reference number, authenticity grade, grading authority, and source edition.

- **DailyGuidancePreferences**: User-controlled notification behavior. Includes enabled state, preferred local time, enabled weekdays, content mode (Quran/Hadith/Mixed), preferred topics, preferred locale, paused-until date, last timezone, and last updated timestamp.

- **DailyDeliveryRecord**: Prevents duplication and preserves item stability. Includes local date, item identifier, item revision, scheduled/delivered/opened timestamps, delivery status, selection reason, and timezone at selection.

- **ContentReviewRecord**: Editorial approval tracking. Includes item identifier, revision, review status, reviewer identifier, review authority, review timestamp, notes, source/translation validation flags, and approval flags for notification and sharing.

### State Models

#### Feature State

`disabled` → `permissionRequired` → `enabled` (or `permissionDenied`)

States: `disabled`, `permissionRequired`, `permissionDenied`, `enabled`, `paused`, `temporarilyUnavailable`

#### Content Publication State

`draft` → `inReview` → `approved` → `published` → `retired`

Rejected items may return to Draft only through explicit editorial revision.

#### Delivery State

States: `notPrepared`, `selected`, `scheduled`, `delivered`, `opened`, `cancelled`, `skipped`, `failed`

Delivery failures must not cause a second visible notification if the first delivery may already have succeeded.

---

## Content Selection Policy

The selection engine follows this conceptual order:

1. Determine the user's local date.
2. Confirm Daily Guidance is enabled for the current weekday.
3. Confirm a notification has not already been delivered for the same local date.
4. Load only published and currently eligible items.
5. Filter by the user's selected content mode.
6. Filter by supported language and approved localization availability.
7. Apply optional explicit topic preferences.
8. Apply valid date-window and occasion rules.
9. Exclude recently delivered content within the anti-repetition window.
10. Balance content categories where multiple candidates remain.
11. Resolve the final candidate using a stable deterministic selection method.
12. Persist the selected item for the current local date.
13. Schedule or display the notification.
14. Record delivery state without storing unnecessary religious interaction details.

**Selection Stability**: The same user-local date must map to the same selected item after commitment. The item must not change due to refreshing, reopening, restarting, or repeated scheduling.

**Mixed-Mode Balance**: Avoid long accidental sequences of one content type. Target balanced rotation across a rolling period without rigid daily alternation that could conflict with occasion content.

**Anti-Repetition**: Target 90-day window. When corpus is exhausted, reuse the oldest eligible item; never select retired or unapproved content; record fallback occurrence for monitoring.

---

## Content Governance

### Quran Requirements

Every Quran record must include: canonical Arabic verse text, surah number, surah Arabic name, approved localized surah name, verse number, source/version identifier, approved translation identifier, review status, review date, reviewer/authority, and publication status. Optional: approved short explanation, approved notification excerpt, topic tags, occasion tags.

### Hadith Requirements

Every Hadith record must include: approved Arabic text, approved translation, collection name, book/chapter, hadith number or stable reference, authenticity grade, grading source, reviewer/authority, review date, and publication status. Optional: approved short explanation, approved notification excerpt, topic tags, occasion tags.

### Mandatory Editorial Prohibitions

Content must never include: fabricated/unverifiable hadith, unapproved weak hadith, edited Quran text, misleading verse fragments, commentary presented as revelation, unsupported medical/financial/supernatural guarantees, sectarian attacks, political campaigning, personal religious verdicts, clickbait language, shame-based messaging, or claims such as "Allah chose this verse for you," "Ignore this and you will lose your blessing," "Share this to receive reward," "Read this and your problem will definitely disappear," "Only special users received this message," or "Come back before the reward expires."

### Recommended Tone

Content should feel: calm, trustworthy, hopeful, clear, respectful, concise, non-judgmental, and spiritually beneficial.

---

## Notification Channel

Daily Guidance uses a dedicated notification category/channel:

- **Arabic name**: نفحة اليوم
- **English name**: Daily Guidance
- **Arabic description**: آية أو حديث صحيح في الوقت الذي تختاره
- **English description**: One Quran verse or authentic hadith at your selected time

The channel must be separate from Prayer, Athkar, Quran-plan, Live-session, Promotional, and Administrative notification categories.

---

## UX Requirements

### First-Time Invitation

Non-blocking card, settings entry, or onboarding step. Must explain: at most one notification per selected day, user chooses time, can be disabled at any time. Notification permission requested only after the user confirms intent.

### Setup Screen

Includes: feature description, enable toggle, notification time, content-type selector, weekday selector, optional topic selection, notification-permission status, preview example, privacy note, and save action.

### Settings Entry

Navigation path: `Settings → Notifications → Daily Guidance`

### Home Integration

The Home screen may include a Daily Guidance card showing today's selected item. The card must use the same committed daily item as the notification — must not independently select a second item.

### Empty and Error States

- **No item available**: "Today's guidance is not available right now. Please try again later."
- **Offline and not cached**: "Connect to the internet to load today's guidance."
- **Permission disabled**: "Notifications are disabled for MeMuslim. Enable them in your device settings to receive Daily Guidance."

### Success Feedback

After enabling: "Daily Guidance is ready. Your next reminder will arrive at the selected time." Avoid celebratory effects implying religious achievement for enabling a notification.

---

## Non-Functional Requirements

### Reliability

- No more than one visible Daily Guidance notification per local date.
- Preference changes take effect without requiring reinstallation.
- Previously committed daily selections remain stable.
- Scheduling failure does not crash application startup.
- Daily Guidance failure does not block unrelated features.
- Notification navigation works from cold start, warm start, and background states.

### Performance

- Opening a cached item feels immediate.
- Content selection does not block the Home screen.
- Scheduling avoids unnecessary network calls.
- Avoid repeated downloads of unchanged content.
- Bounded storage for content lists and history.
- Startup does not wait for Daily Guidance initialization.

### Battery and Background Usage

- No continuous background execution.
- No frequent polling.
- Platform-appropriate scheduling.
- No repeated device wakes for unchanged content.
- Network refreshes batched with existing app refresh workflows.

### Security

- Remote content treated as untrusted until validated.
- Client does not treat editable remote fields as executable instructions.
- Administrative operations require authorization.
- Audit records protected against unauthorized modification.
- Deep links validate item identifiers.
- Invalid/manipulated identifiers open a safe error state.

### Privacy

- Works without advertising identifiers.
- Engagement events avoid full religious text.
- No inferred religious profile.
- Notification previews exclude sensitive personal data.
- Feature operates when optional analytics are disabled.

### Accessibility

- All major flows support screen readers.
- Quran diacritics remain readable.
- Larger text does not hide source information.
- Tap targets meet sizing rules.
- Arabic RTL and English LTR tested independently.
- Supports reduced motion.
- Haptic feedback subtle and non-essential.

---

## Analytics Events

Privacy-safe events:

- `daily_guidance_setup_viewed`, `daily_guidance_enabled`, `daily_guidance_disabled`
- `daily_guidance_permission_requested`, `daily_guidance_permission_granted`, `daily_guidance_permission_denied`
- `daily_guidance_preferences_updated`
- `daily_guidance_item_selected`, `daily_guidance_notification_scheduled`, `daily_guidance_notification_opened`
- `daily_guidance_detail_viewed`, `daily_guidance_item_saved`, `daily_guidance_item_shared`
- `daily_guidance_open_mushaf`, `daily_guidance_listen_started`
- `daily_guidance_delivery_failed`, `daily_guidance_content_unavailable`, `daily_guidance_repeat_fallback_used`

**Permitted properties**: Content item identifier, content type, application locale, delivery status, scheduling strategy, failure category, occasion-tagged flag, cached flag.

**Prohibited properties**: Full Quran/hadith text, full explanation, user-entered private notes, inferred spiritual condition, notification body, sensitive behavioral labels.

---

## Non-Goals

The initial version shall not include: coins/points/loot boxes/prize wheels, financial/random prize rewards, competitive worship leaderboards, shame-for-inactivity notifications, claims about reward amounts, divine message selection claims, AI-generated Quran/hadith/translations/rulings, AI-generated authenticity grading, user-generated religious content, open community commentary, personalized religious rulings, psychological profiling, multiple promotional notifications per day, automatic activation without consent, weak/fabricated hadith, unreviewed tafsir, political/sectarian content, controversial jurisprudence, full study courses, mandatory account creation, or preference sync unless separately approved.

---

## MVP Scope

Explicit opt-in, one notification per enabled local day, user-selected notification time, weekday selection, Quran/Hadith/Mixed mode, reviewed Arabic content, approved English localization, 90-day anti-repetition target, stable daily selection, notification deep linking, Daily Guidance detail screen, source and authenticity details, save and share, Open in Mushaf for Quran items, local recent-item history, basic offline caching, dedicated notification channel, privacy-safe analytics, editorial publication status, content retirement, publication audit trail, cold-start notification navigation, RTL/LTR/accessibility/text-scaling support.

---

## Future Enhancements

User-selected themes, optional audio recitation, Home-screen widgets, wearable delivery, cross-device preference sync, personalized topic rotation, seasonal editorial collections, Ramadan/Friday-specific content, children/family content packs, multilingual expansion, admin preview rendering, editorial scheduling calendar, A/B testing of respectful wording, user topic feedback, optional private reflection notes, accessibility-specific presentation, Quran reading plan integration.

---

## Explicitly Prohibited Designs

Gambling/loot-box mechanics, scarcity or expiration pressure, spiritual shaming, divine selection claims, AI-generated religious text, competitive worship scoring, secret rare content, emotional manipulation, advertising-driven personalization, automated reward claims, and any design that treats Islamic content as a gamified commodity.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of published items include required source metadata at the time of publication.
- **SC-002**: 100% of delivered hadith items have approved authenticity metadata.
- **SC-003**: 0 unreviewed religious items are eligible for production delivery.
- **SC-004**: 0 dynamically generated Quran or hadith texts are delivered.
- **SC-005**: Material content corrections can be traced through an audit record.
- **SC-006**: Users can enable, customize, pause, and disable the feature within 3 interactions from the settings screen.
- **SC-007**: Disabling Daily Guidance cancels all future Daily Guidance deliveries within one scheduling cycle.
- **SC-008**: Users who reject analytics can still use the complete feature without degradation.
- **SC-009**: Notification permission is requested contextually, not automatically on first launch.
- **SC-010**: The same daily item remains stable after repeated application launches on the same local date.
- **SC-011**: No duplicate visible notification is generated for the same user-local date under supported test scenarios including timezone and time changes.
- **SC-012**: Notification tapping resolves the exact associated content from terminated, background, and foreground application states.
- **SC-013**: Content does not repeat inside the configured 90-day anti-repetition window when sufficient eligible content exists.
- **SC-014**: All notification excerpts remain meaningful when truncated.
- **SC-015**: All displayed translations and explanations are approved.
- **SC-016**: Retired and rejected items are excluded from new selections.
- **SC-017**: The complete setup and detail flows are operable with supported screen readers.
- **SC-018**: Critical content remains readable at the application's supported maximum text scale.
- **SC-019**: Arabic RTL and English LTR layouts pass visual review.
- **SC-020**: Healthy opt-in rate without manipulative activation design.
- **SC-021**: Sustainable notification-open rate without guilt or shame-based messaging.
- **SC-022**: No increase in notification-related complaints after feature launch.

---

## Assumptions

- Users have a device capable of receiving local notifications (Android 8+ / iOS 14+).
- The application already has a notification infrastructure that supports channel creation and local scheduling.
- An existing content management or data seeding pipeline can be extended to support the Daily Guidance content schema.
- The Mushaf reader and recitation features already exist in the app for "Open in Mushaf" and "Listen" actions.
- The save/favorites infrastructure already exists in the app for "Save" actions.
- The sharing infrastructure already exists in the app for "Share" actions.
- Arabic and English are the initial supported languages; additional languages will be added through future reviewed localization.
- Content will be initially seeded by editorial staff and can be expanded over time.
- The anti-repetition window of 90 days assumes a sufficient initial corpus of at least 90 reviewed items.
- GoRouter is the routing solution for deep-link handling from notifications.
- BLoC is the state management solution for the feature's presentation layer.
- The app follows Clean Architecture boundaries per the workspace constitution.
