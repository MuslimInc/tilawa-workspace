# MeMuslim App - Missing Features

This document outlines features that are commonly found in Quran/Islamic apps but are currently missing from MeMuslim (formerly Tilawa).

**Active team backlog (features + refactors you update often):**
[`TODO.md`](TODO.md).

**New specs added 2026-06-20 (sourced from Athkar iOS competitive analysis):**

| Spec | Feature | Priority |
| --- | --- | --- |
| [`024-worship-tracker`](../specs/024-worship-tracker/spec.md) | Daily prayer/athkar/Quran log + streak + heatmap + fasting suggestions | P1 |
| [`025-home-screen-widgets`](../specs/025-home-screen-widgets/spec.md) | Prayer times, next prayer, hijri date widgets | P1 |
| [`026-granular-reminders`](../specs/026-granular-reminders/spec.md) | 4 free reminders (morning/evening/Duha/white-days); Tahajjud + Jumu'ah + Quran goal in Support tier | P1 |
| [`027-personal-dua-collections`](../specs/027-personal-dua-collections/spec.md) | User-created du'a collections with daily reminders; PDF booklet + unlimited collections in Support tier | P2 |
| [`028-athkar-swipe-flow`](../specs/028-athkar-swipe-flow/spec.md) | One-at-a-time recitation mode for athkar categories | P2 |
| [`029-friday-section`](../specs/029-friday-section/spec.md) | Jumu'ah hub — Surah al-Kahf, salawat, sunan, hour of acceptance | P2 |

---

## ✅ Implemented Features

### Share Functionality

**Description:** Share surah links, ayat, or audio clips via social media.
*Status: Implemented in codebase.*

---

### Prayer Times

**Description:** Display accurate prayer times based on user location with customizable calculation methods and Adhan notifications.
*Status: Fully implemented and hardened. Version 1.0.0+24 resolved routing discrepancies and payload matching across all app states.*

---

## 🗂️ Post-Release Maintainability Backlog

### Theme Token Harmonization (T4)

**Release decision:** GO for current release, no pre-release implementation required.

**Why deferred:**

- No blocker found in T4 audit.
- Current theme behavior is release-viable.
- Broad harmonization now would introduce avoidable visual churn.

**Backlog items:**

- [ ] Quran Image Reader fallback/error/loading colors: make mode-aware and `ColorScheme`-derived if visual issues appear.
- [ ] Share/Reel palette: consolidate duplicated branded constants into one feature token source.
- [ ] Share/Reel branding strategy: keep branded identity unless product decides to harmonize with app primary.
- [ ] Settings semantic icon colors: decide whether they remain fixed semantic colors or become theme-derived tokens.
- [ ] Overlay/scrim constants: optional tokenization for consistency.

**Note:** Remaining work is maintainability-focused backlog and not a release blocker.

---

## 🧪 Implemented — Needs Verification

### 2. Quran Text Reader
**Description:** Display Quran text with Arabic script, allowing users to read along with audio.
*Status: Implemented in codebase, pending feature-completeness verification (e.g., Tajweed color coding).*

### 3. Bookmarks
**Description:** Allow users to save positions in surahs to resume later.
*Status: Implemented in codebase, pending feature-completeness verification.*

### 4. Listening History
**Description:** Track recently played surahs with timestamps for easy access.
*Status: Implemented in codebase, pending feature-completeness verification.*

---

## ⏳ Still Missing / Deferred

## 🟡 Medium Priority

### 5. Tafsir & Translation
**Description:** Display verse translations and tafsir (interpretations) in multiple languages.

**Key Features:**
- [ ] Multiple translation languages (English, Urdu, French, etc.)
- [ ] Multiple tafsir sources (Ibn Kathir, Jalalayn, etc.)
- [ ] Side-by-side Arabic and translation view
- [ ] Audio translations
- [ ] Search within translations

---



### 7. Extended Athkar Categories
**Description:** Add more athkar/dua categories beyond morning and evening.

**Categories to Add:**
- [ ] أذكار النوم (Sleep Athkar)
- [ ] أذكار الاستيقاظ (Waking Up Athkar)
- [ ] أذكار بعد الصلاة (After Prayer Athkar)
- [ ] أذكار الوضوء (Wudu Athkar)
- [ ] أدعية من القرآن (Duas from Quran)
- [ ] أدعية من السنة (Duas from Sunnah)
- [ ] الرقية الشرعية (Ruqyah)
- [ ] أذكار السفر (Travel Athkar)
- [ ] أذكار الطعام (Food Athkar)
- [ ] أذكار المسجد (Mosque Athkar)

---

### 8. Cloud Backup & Sync
**Description:** Sync user data across devices for logged-in users.

**Features:**
- [ ] Sync favorites
- [ ] Sync bookmarks
- [ ] Sync playlists
- [ ] Sync listening history
- [ ] Sync settings preferences
- [ ] Manual backup/restore option
- [ ] Conflict resolution

**Implementation:** Firebase Firestore user collections

---

### 9. Juz Browser
**Description:** Browse Quran by Juz (30 parts) in addition to surahs.

**Key Features:**
- [ ] List all 30 Juz
- [ ] Show surahs within each Juz
- [ ] Quick navigation to Juz
- [ ] Play entire Juz
- [ ] Download entire Juz

---

### 10. Surah Position Bookmarking
**Description:** Save specific timestamp positions within a surah.

**Key Features:**
- [ ] Long-press to bookmark current position
- [ ] Multiple bookmarks per surah
- [ ] Quick jump between bookmarks
- [ ] Bookmark notes/labels

---

### 11. Audio Equalizer
**Description:** Audio EQ settings for enhanced listening experience.

**Key Features:**
- [ ] Preset EQ profiles (Voice, Bass Boost, Clear)
- [ ] Custom equalizer bands
- [ ] Save custom presets

---

### 12. Reciter Following/Subscription
**Description:** Follow favorite reciters for updates.

**Key Features:**
- [ ] Follow/unfollow reciters
- [ ] Notifications for new content
- [ ] Following feed/list

---

## 🟠 Low Priority

### 13. Home Screen Widget
**Description:** iOS/Android home screen widgets.

**Widget Types:**
- [ ] Prayer times widget
- [ ] Daily ayah widget
- [ ] Athkar reminder widget
- [ ] Quick play widget
- [ ] Qibla widget

**Dependencies:** `home_widget` package

---

### 14. Daily Ayah/Athkar
**Description:** Display a random daily ayah or athkar on the home screen.

**Key Features:**
- [ ] Random ayah of the day
- [ ] Daily athkar rotation
- [ ] Share daily content
- [ ] Notification with daily content

---

### 15. Khatma Tracker
**Description:** Track progress of completing the full Quran.

**Key Features:**
- [ ] Create new khatma (completion goal)
- [ ] Track listened surahs/juz
- [ ] Progress percentage
- [ ] Estimated completion date
- [ ] Multiple active khatmas
- [ ] Khatma history

---

### 16. Listening Statistics
**Description:** Show listening statistics and streaks.

**Key Features:**
- [ ] Daily listening time
- [ ] Weekly/monthly statistics
- [ ] Most played surahs
- [ ] Most played reciters
- [ ] Listening streak counter
- [ ] Achievement badges

---

### 17. CarPlay & Android Auto
**Description:** Vehicle infotainment system integration.

**Key Features:**
- [ ] Browse reciters in car
- [ ] Playback controls
- [ ] Voice commands
- [ ] Simplified UI for driving

---

### 18. Watchlist / Listen Later
**Description:** Mark surahs to listen later.

**Key Features:**
- [ ] Add to watchlist button
- [ ] Watchlist screen
- [ ] Remove after listening option

---

### 19. Audio Visualization
**Description:** Visual waveform or animation during playback.

**Key Features:**
- [ ] Waveform visualization
- [ ] Animated artwork
- [ ] Particle effects

---

### 20. Offline Quran Text
**Description:** Pre-bundled Quran text for offline reading.

**Key Features:**
- [ ] Full Quran text bundled in app
- [ ] No internet required for reading
- [ ] Optimized asset size

---

### 21. Surah Notes
**Description:** Add personal notes to surahs.

**Key Features:**
- [ ] Add notes to any surah
- [ ] Rich text formatting
- [ ] Search notes
- [ ] Export notes

---

### 22. Ramadan Mode
**Description:** Special features during Ramadan.

**Key Features:**
- [ ] Taraweeh schedule
- [ ] Suhoor/Iftar times
- [ ] Daily Quran reading plan
- [ ] Ramadan-specific athkar
- [ ] Laylat al-Qadr reminders

---

### 23. Islamic Calendar
**Description:** Hijri calendar with Islamic events.

**Key Features:**
- [ ] Hijri date display
- [ ] Islamic holidays/events
- [ ] Event notifications
- [ ] Monthly calendar view

---

## 📊 Implementation Priority Matrix

| Feature | User Impact | Dev Effort | Priority Score |
|---------|-------------|------------|----------------|
| Cloud Sync | Medium | Medium | 🟡 7/10 |
| Extended Athkar | Medium | Low | 🟡 6/10 |
| Tafsir/Translation | High | High | 🟡 6/10 |
| Juz Browser | Low | Low | 🟡 5/10 |
| Home Widgets | Medium | Medium | 🟠 5/10 |
| Daily Ayah | Low | Low | 🟠 4/10 |
| Statistics | Low | Medium | 🟠 4/10 |
| Khatma Tracker | Low | Medium | 🟠 4/10 |
| CarPlay/Auto | Low | High | 🟠 3/10 |

---

## 🚀 Suggested Implementation Phases

### Phase 1: Core Enhancements (1-2 months)
- Extended Athkar Categories

### Phase 2: Major Features (2-3 months)
- Cloud Backup & Sync
- Juz Browser

### Phase 3: Reading Experience (3-4 months)
- Tafsir & Translation
- Offline Quran Text

### Phase 4: Engagement Features (Ongoing)
- Statistics & Streaks
- Khatma Tracker
- Home Screen Widgets
- Daily Ayah/Athkar

### Phase 5: Platform Extensions
- CarPlay & Android Auto
- Audio Visualization
- Ramadan Mode

---

## 📝 Notes

- All features should support both Arabic (RTL) and English (LTR) layouts
- Premium features should be clearly marked
- Consider accessibility (VoiceOver, TalkBack) for all new features
- New features should follow existing architecture (BLoC pattern, clean architecture)
- All strings should be localized in both Arabic and English

---

*Last Updated: May 8, 2026*
