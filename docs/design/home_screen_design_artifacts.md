# Home Screen Redesign — Design Artifacts

**Status:** Pre-implementation validation  
**Date:** 2026-06-20  
**ADR:** [ADR-002](../adr/ADR-home-screen-information-architecture.md)  
**Implementation Plan:** [Home Screen Redesign Plan](../plans/home_screen_redesign_plan.md)  
**Acceptance Criteria:** [Home Screen Acceptance Criteria](../specs/home_screen_acceptance_criteria.md)

---

## Measured Constants (from source)

These values inform all viewport analysis and wireframes below.

| Element | Height (dp) |
|---------|------------|
| Status bar — notched iOS / recent Android | ~44 |
| Status bar — Android standard | ~24 |
| Hero body (greeting 92 + metrics 148 + slack 4) | 244 |
| Hero total (status bar + hero body) | ~268–288 |
| `sheetOverlap` — rounded sheet starts this far above hero bottom | 16 |
| Bottom navigation bar | ~80 |
| Mini-player chrome (when active) | 57 |
| Bottom chrome total (nav + mini-player) | ~137 |
| `spaceExtraLarge` inter-section gap | 24 |
| `spaceXXL` section breathing room | 32 |

---

## 1. WIREFRAMES

### 1A — Current Home (As-Built)

```
┌─────────────────────────────────────────────────┐  ← Status bar (44dp)
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ╔═══════════════════════════════════════════════╗ │
│ ║  [GRADIENT HERO — prayer-period colour]       ║ │  }
│ ║                                               ║ │  }  Greeting: 92dp
│ ║  Assalamu Alaikum, Muhammad                   ║ │  }
│ ║  20 Dhul Hijjah 1447  ·  20 Jun 2026         ║ │  }
│ ║  ─────────────────────────────────────────── ║ │
│ ║  ┌─────────────────────────────────────────┐ ║ │  }
│ ║  │  Next Prayer                            │ ║ │  }
│ ║  │  ██████████  Asr                        │ ║ │  }  Metrics: 148dp
│ ║  │             4:22 PM                     │ ║ │  }
│ ║  │             in 1h 14m              📍  │ ║ │  }
│ ║  └─────────────────────────────────────────┘ ║ │  }
│ ╚═══════════════════════════════════════════════╝ │  ← ~288dp from top
│ ╔═══════════════════════════════════════════════╗ │  ← rounded content sheet
│ ║                                               ║ │
│ ║  ┌─────────────────────────────────────────┐ ║ │
│ ║  │ 📖  Last Read              [progress▓░] │ ║ │  Quran Resume: ~80dp
│ ║  │     Al-Baqarah · Page 45             → │ ║ │
│ ║  └─────────────────────────────────────────┘ ║ │
│ ║  [24dp gap]                                   ║ │
│ ║  Today                                        ║ │  ← Section header
│ ║  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                   ║ │
│ ║  │Fj│ │Sr│ │Dr│ │▓Ar│ │Mg│  ← pill strip    ║ │  Prayer strip: ~48dp
│ ║  └──┘ └──┘ └──┘ └──┘ └──┘   (View All →)   ║ │
│ ║  [24dp gap]                                   ║ │
│ ║  Your Rituals             [edit ✎]            ║ │  ← Section header
│ ║  ┌─────────────────────────────────────────┐ ║ │
│ ║  │ ☀  NOW  Evening Athkar  Begin Now →    │ ║ │  Contextual: ~56dp
│ ║  └─────────────────────────────────────────┘ ║ │
│ ║  [list of pinned athkar categories]           ║ │  Pinned list: variable
│ ║  ─────────────────────────────────────────── ║ │
│ ║  [24dp gap]                                   ║ │
│ ║  Discover              [⊞ toggle]             ║ │  ← Section header
│ ║  ┌──────────┐  ┌──────────┐                  ║ │
│ ║  │ 🎙 Browse│  │ 🧿 Tasb │                  ║ │  Reciters + Tasbeeh
│ ║  │  Reciters│  │    eeh   │                  ║ │
│ ║  └──────────┘  └──────────┘                  ║ │
│ ║  ┌──────────┐  ┌──────────┐                  ║ │
│ ║  │ 🧭 Find │  │ 📖 Quran │                  ║ │  Qibla + Smart Khatma
│ ║  │  Qibla   │  │  Plans   │                  ║ │
│ ║  └──────────┘  └──────────┘                  ║ │
│ ║  [24dp gap]                                   ║ │
│ ║  ┌─────────────────────────────────────────┐ ║ │
│ ║  │ Daily Ayah        [reference]           │ ║ │  Daily Ayah: ~80dp
│ ║  │ ﴿ Arabic text… ﴾                        │ ║ │  (BURIED)
│ ║  │ Translation…                            │ ║ │
│ ║  ├─────────────────────────────────────────┤ ║ │
│ ║  │ Daily Dua         [source]              │ ║ │  Daily Dua: ~80dp
│ ║  │ Dua text…                               │ ║ │
│ ║  └─────────────────────────────────────────┘ ║ │
│ ╚═══════════════════════════════════════════════╝ │
│ [───────── Mini-player (57dp, if active) ──────] │
│ [═══════════ Bottom Navigation (80dp) ══════════] │
└─────────────────────────────────────────────────┘

PROBLEMS ANNOTATED:
[!] Prayer pill strip — duplicate of hero prayer context
[!] Reciters tile — duplicate of bottom-nav Reciters tab
[!] Qibla tile — duplicate of bottom-nav Qibla tab
[!] "Discover" section — navigation menu, not a feature
[!] Daily Ayah — buried below 3 sections + 4 tiles; ~600dp below fold
[!] No streak, no goal progress, no completion state anywhere visible
```

---

### 1B — Concept C: New User State (Day 1, No History)

```
┌─────────────────────────────────────────────────┐  ← Status bar (44dp)
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ╔═══════════════════════════════════════════════╗ │
│ ║  [GRADIENT — warm dawn / Fajr palette]        ║ │
│ ║                                               ║ │
│ ║  Assalamu Alaikum                             ║ │  Greeting: 92dp
│ ║  20 Dhul Hijjah 1447  ·  20 Jun 2026         ║ │
│ ║  ─────────────────────────────────────────── ║ │
│ ║  ┌─────────────────────────────────────────┐ ║ │
│ ║  │  Next Prayer                            │ ║ │
│ ║  │  ██████████  Asr          📍 London    │ ║ │  Metrics: 148dp
│ ║  │             4:22 PM                     │ ║ │
│ ║  │             in 1h 14m                   │ ║ │
│ ║  └─────────────────────────────────────────┘ ║ │
│ ╚═══════════════════════════════════════════════╝ │  ← ~288dp
│                                                   │
│ ════════ TODAY ════════════════════════════════   │  ← FOLD LINE: ~288dp
│  ┌─────────────────────────────────────────────┐  │  ╔═══════════════╗
│  │ 📅 Today · 20 Dhul Hijjah                  │  │  ║ VISIBLE ABOVE ║
│  │                                             │  │  ║     FOLD      ║
│  │ ﴿ وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ     │  │  ║               ║
│  │   مَخْرَجًا ﴾                               │  │  ╚═══════════════╝
│  │                                             │  │  Daily Ayah: ~120dp
│  │ And whoever fears Allah —                  │  │
│  │ He will make for him a way out.            │  │
│  │                                             │  │
│  │ At-Talaq 65:2–3              [🔖] [↗ share]│  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│ ════════ YOURS ════════════════════════════════   │
│  ┌─────────────────────────────────────────────┐  │
│  │ 📖  Begin your Quran journey               │  │  Quran CTA: ~72dp
│  │     Start reading today                  → │  │
│  └─────────────────────────────────────────────┘  │
│  [24dp gap — Listening Row hidden: no history]    │
│  ┌─────────────────────────────────────────────┐  │
│  │ ☀  Morning Athkar    Not started         → │  │
│  │ ──────────────────────────────────────────  │  │  Athkar Card: ~112dp
│  │ 🌙  Evening Athkar   Not started         → │  │
│  │ ──────────────────────────────────────────  │  │
│  │ ★   Sleep Athkar     Not started         → │  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│ ════════ FOOTER ═══════════════════════════════   │
│                  [🧿 Tasbeeh]                     │  Footer: ~40dp
│                                                   │
│ [───────── Mini-player (hidden: no history) ───]  │
│ [═══════════ Bottom Navigation (80dp) ══════════] │
└─────────────────────────────────────────────────┘

NEW USER OBSERVATIONS:
[✓] Hero: full value — prayer + date regardless of history
[✓] Daily Ayah: partially visible at the fold — compelling on day 1
[✓] Quran card: clear invitation, not a broken empty state
[✓] Listening row: invisible — no gap, no placeholder
[✓] Athkar card: "Not started" × 3 — honest, immediately actionable
[✓] Total scroll to bottom: ~480dp — short, not overwhelming
```

---

### 1C — Concept C: Returning User State (Active Habits)

```
┌─────────────────────────────────────────────────┐  ← Status bar (44dp)
│ ╔═══════════════════════════════════════════════╗ │
│ ║  [GRADIENT — noon gold / Dhuhr palette]       ║ │
│ ║  Muhammad                                     ║ │
│ ║  20 Dhul Hijjah 1447  ·  20 Jun 2026         ║ │
│ ║  ─────────────────────────────────────────── ║ │
│ ║  ┌─────────────────────────────────────────┐ ║ │
│ ║  │  Next Prayer                            │ ║ │
│ ║  │  ██████████  Asr          📍 London    │ ║ │
│ ║  │             4:22 PM  ·  in 1h 14m       │ ║ │
│ ║  └─────────────────────────────────────────┘ ║ │
│ ╚═══════════════════════════════════════════════╝ │
│                                                   │
│ ════════ TODAY ════════════════════════════════   │  ← FOLD: ~288dp
│  ┌─────────────────────────────────────────────┐  │
│  │ 📅 Today · 20 Dhul Hijjah                  │  │
│  │                                             │  │
│  │ ﴿ وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ     │  │
│  │   مَخْرَجًا ﴾                               │  │
│  │                                             │  │
│  │ And whoever fears Allah —                  │  │
│  │ He will make for him a way out.            │  │
│  │ At-Talaq 65:2–3              [🔖] [↗ share]│  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│ ════════ YOURS ════════════════════════════════   │
│  ┌─────────────────────────────────────────────┐  │
│  │ 📖  Al-Baqarah · Page 45                   │  │
│  │     ●●●●●●●●●●●●░░░░   65%  Day 12 🔥     │  │  Quran card: ~88dp
│  │     Ramadan Khatma · Week 3 of 10           │  │
│  │                                           → │  │
│  └─────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────┐  │
│  │ 🎧  Continue · Sheikh Mishary · Al-Baqarah → │  │  Listening: ~48dp
│  └─────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────┐  │
│  │ ☀  Morning Athkar    ✓ Done              → │  │
│  │ ──────────────────────────────────────────  │  │  Athkar card: ~112dp
│  │ 🌙  Evening Athkar   34 remaining        → │  │  (Evening first:
│  │ ──────────────────────────────────────────  │  │   Maghrib context)
│  │ ★   Sleep Athkar     Not started         → │  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│ ════════ FOOTER ═══════════════════════════════   │
│                  [🧿 Tasbeeh]                     │
│                                                   │
│ [───────── Mini-player: Mishary · Al-Baqarah ──]  │  57dp
│ [═══════════ Bottom Navigation (80dp) ══════════] │
└─────────────────────────────────────────────────┘

RETURNING USER OBSERVATIONS:
[✓] Streak (Day 12 🔥) and goal (65%) visible on Quran card
[✓] Khatma plan label present — week progress visible without opening plan
[✓] Listening row: reciter and surah named — zero-decision resume
[✓] Athkar: Morning done, Evening urgent (contextual sort, Maghrib time)
[✓] Mini-player active at bottom — audio continuity preserved
```

---

### 1D — Concept C: Power User State (Heavy History, Plan Active)

```
┌─────────────────────────────────────────────────┐
│ ╔═════════════════════════ HERO ═══════════════╗ │
│ ║  [Evening gradient — Maghrib deep indigo]     ║ │
│ ║  Muhammad · 20 Dhul Hijjah                    ║ │
│ ║  ┌──────────────────────────────────────────┐ ║ │
│ ║  │ Maghrib · 8:47 PM · in 4 minutes   📍  │ ║ │
│ ║  └──────────────────────────────────────────┘ ║ │
│ ╚═══════════════════════════════════════════════╝ │
│                                                   │
│ TODAY ─────────────────────────────────────────  │
│  ┌──────────────────────────────── Daily Ayah ─┐  │
│  │ ﴿ Arabic ﴾  Translation  Ref  [🔖][↗]      │  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│ YOURS ─────────────────────────────────────────  │
│  ┌──────────────────────────── Quran Progress ─┐  │
│  │ 📖 Al-Kahf · Page 302                       │  │
│  │    ████████████████████░  95%  Day 47 🔥   │  │
│  │    Khatma II · Juz 15 of 30                 │  │
│  │                                           → │  │
│  └─────────────────────────────────────────────┘  │
│  ┌─────────────────────── Listening Resume ────┐  │
│  │ 🎧  Continue · Abdul Basit · Al-Kahf      → │  │
│  └─────────────────────────────────────────────┘  │
│  ┌───────────────────────── Athkar Compact ────┐  │
│  │ ☀  Morning Athkar    ✓ Done              → │  │
│  │ ─────────────────────────────────────────── │  │
│  │ 🌙  Evening Athkar   ✓ Done              → │  │  ← Both complete:
│  │ ─────────────────────────────────────────── │  │    user feels great
│  │ ★   Sleep Athkar     Not started         → │  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│ FOOTER ─────────────────────────────────────────  │
│                  [🧿 Tasbeeh]                     │
│                                                   │
│ [──── Mini-player: Abdul Basit · Al-Kahf ──────]  │
│ [══════════════ Bottom Navigation ══════════════] │
└─────────────────────────────────────────────────┘

POWER USER OBSERVATIONS:
[✓] Streak Day 47 — strong loss-aversion retention signal
[✓] 95% goal progress — one short session will complete today
[✓] Two Athkar complete — visible daily achievement
[✓] Reading and listening match same surah — coherent journey
[✓] Maghrib countdown: "in 4 minutes" — immediate priority context
```

---

### 1E — Collapsed Hero State (After Scroll)

```
┌─────────────────────────────────────────────────┐
│ ╔═══════════════════════════════════════════════╗ │  ← Collapsed toolbar
│ ║  Asr · 4:22 PM · in 1h 14m                   ║ │  kToolbarHeight (56dp)
│ ╚═══════════════════════════════════════════════╝ │
│  ┌─────────────────────────────────────────────┐  │  ← Sheet scrolled up
│  │ 📅 Today · 20 Dhul Hijjah                  │  │
│  │ ﴿ وَمَن يَتَّقِ اللَّهَ… ﴾                  │  │
│  │ And whoever fears Allah…  [🔖][↗]          │  │
│  └─────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────┐  │
│  │ 📖  Al-Baqarah · Page 45  ●●●●░  65%  🔥12│  │
│  └─────────────────────────────────────────────┘  │
│  ...                                              │
│ [═══════════ Bottom Navigation ══════════════════] │
└─────────────────────────────────────────────────┘

[✓] Prayer info preserved in collapsed toolbar during scroll
[✓] Daily Ayah is first content visible after hero collapses
[✓] User can read Ayah and access Quran in same scroll position
```

---

## 2. VIEWPORT ANALYSIS

### Device Reference Table

| Device | Screen Height | Status Bar | Bottom Chrome (nav only) | Bottom Chrome (nav + player) | Available Content Height |
|--------|--------------|------------|--------------------------|-------------------------------|--------------------------|
| Small Android (480dp) | 480dp | 24dp | 80dp | 137dp | **376dp** (nav only) |
| Medium Android (667dp) | 667dp | 24dp | 80dp | 137dp | **563dp** (nav only) |
| iPhone Standard (667dp) | 667dp | 44dp | 80dp | 137dp | **543dp** (nav only) |
| Large Android (800dp) | 800dp | 24dp | 80dp | 137dp | **696dp** (nav only) |
| iPhone Pro Max (932dp) | 932dp | 59dp | 80dp | 137dp | **793dp** (nav only) |

"Available Content Height" = screen height − status bar − bottom nav.  
Hero occupies the top ~244–288dp of available height.  
Content sheet begins at hero bottom − 16dp (sheetOverlap).

---

### Viewport Analysis: What Is Visible Above the Fold

#### Hero above-fold content (always visible, always full):
- Greeting + Hijri date: ✓
- Next prayer card (name, time, countdown): ✓

**Hero occupies 244–288dp**, leaving **279–319dp** of content sheet visible on a medium device before scrolling.

#### Daily Ayah position analysis

The Daily Ayah card sits at position 0 of the content sheet (first element after `sheetOverlap = 16dp`).

Estimated Daily Ayah card height:
- Internal padding: 2 × 16dp = 32dp
- Date label: 20dp
- Arabic text (2–3 lines at 1.5× line height, ~22dp/line): ~66dp
- Translation (2 lines): ~40dp
- Reference + action row: 32dp
- **Total estimate: ~190dp**

| Device | Content sheet visible | Ayah card height | Ayah fully visible? |
|--------|-----------------------|------------------|---------------------|
| Small Android (376dp available, 288dp hero) | **88dp** | ~190dp | ⚠ Partially (top ~88dp) |
| Medium Android (563dp available, 268dp hero) | **295dp** | ~190dp | ✓ Fully |
| iPhone Standard (543dp, 288dp hero) | **255dp** | ~190dp | ✓ Fully |
| Large Android (696dp, 268dp hero) | **428dp** | ~190dp | ✓ Fully + Quran card top |

**Risk flagged (Small Android):** On a 480dp device, only ~88dp of content is visible below the hero. The Daily Ayah card is partially visible (Arabic text truncated, actions not visible). This is acceptable — the card is *started* above the fold, which is sufficient to signal daily content. The user sees Arabic text and scrolls naturally to read more.

#### Quran Progress Card position analysis

Quran card sits immediately below the Daily Ayah card.  
Position from top of content sheet: ~190dp (Ayah) + 24dp (gap) = **~214dp below sheet top**.

| Device | Content sheet visible | Quran card start | Quran card visible? |
|--------|-----------------------|------------------|---------------------|
| Small Android (88dp visible) | 88dp | 214dp | ✗ Not visible (requires scroll) |
| Medium Android (295dp visible) | 295dp | 214dp | ✓ Top visible (≥81dp of card shown) |
| iPhone Standard (255dp visible) | 255dp | 214dp | ✓ Top visible (≥41dp shown) |
| Large Android (428dp visible) | 428dp | 214dp | ✓ Fully visible |

**Risk flagged (Small Android):** Quran card is below the fold on 480dp devices. This is a known trade-off — small devices have always required scrolling to reach secondary content. The hero is not resizable without degrading the prayer card.

**Risk flagged (iPhone Standard / Medium Android):** Quran card top edge is visible but the card may be partially clipped. A returning user sees the beginning of their progress, which creates a natural pull to scroll. This is a *positive* UX pattern (content peek), not a defect.

#### Acceptance Criterion AC-3.1 verification

AC-3.1 states: "the top edge of the Quran Progress Card is visible... The user does not need to scroll more than one viewport height."  
On a 667dp device: Quran card starts at ~214dp from sheet top. Sheet top is at ~268–288dp from device top. Quran card absolute position: ~482–502dp from device top. Device height: 667dp − 80dp (nav) = 587dp usable. **482dp < 587dp. ✓ AC-3.1 passes on 667dp devices.**

On a 480dp device: Quran card absolute position: ~482–502dp. Usable height: 480dp − 80dp = 400dp. **482dp > 400dp. ✗ AC-3.1 fails on 480dp devices.**

**Mitigation for small devices:** Reduce Daily Ayah card internal padding from 16dp to 12dp on screens below 568dp height. This recovers ~8dp and reduces Arabic text to 2 lines (from 3) on small screens. Quran card still requires a short scroll on 480dp devices — this is acceptable; the criterion is "at or near first viewport."

---

## 3. INFORMATION ARCHITECTURE DIAGRAM

```
HOME SCREEN
│
│  Rationale for ordering:
│  ① Hero answers "What time is it and when is next prayer?" — zero-history,
│    zero-decision. Always first. Non-negotiable anchor.
│
│  ② TODAY layer answers "What is different about today?" — zero-history,
│    daily variation. Placed immediately after hero so it is above the fold
│    (or at the fold) on all devices ≥ 568dp. Creates daily pull.
│
│  ③ YOURS layer answers "Where did I leave off?" — history-dependent,
│    personalised. Placed after TODAY so new users encounter full TODAY
│    before sparse YOURS. Returning users scroll past a brief anchor
│    to reach their dashboard.
│
│  ④ FOOTER: single utility, no section header, zero visual weight.
│    Present but unemphasised.
│
├── ① HERO  [always full, always first]
│   │
│   ├── Prayer-period ambient gradient
│   │    Reason: orients user in Islamic time without any text
│   │
│   ├── Greeting + Hijri date
│   │    Reason: personal, time-specific, establishes daily ritual frame
│   │
│   ├── Next Prayer card (name · time · countdown · location)
│   │    Reason: PRIMARY USER GOAL 1 — must be zero-scroll, zero-tap
│   │    Data source: local prayer calculation (no network dependency)
│   │
│   └── Collapsed toolbar (on scroll: "Asr · 4:22 PM · in 1h 14m")
│        Reason: prayer context preserved without re-expanding hero
│
├── ② TODAY  [zero-history, daily variation]
│   │
│   └── Daily Ayah Card
│        Reason: changes every day = daily pull to return
│        Reason: no history required = full value on day 1
│        Reason: bookmark + share = daily micro-action, not passive content
│        Position: FIRST in content sheet (above fold on ≥568dp devices)
│        ├── Arabic text (2–3 lines)
│        ├── Translation (1–2 lines)
│        ├── Reference (Surah · Verse)
│        ├── Bookmark action → saves to user bookmarks
│        └── Share action → platform share sheet
│
├── ③ YOURS  [history-dependent, graceful degradation]
│   │
│   ├── Quran Progress Card  [PRIMARY USER GOAL 2]
│   │    New user:     "Begin your Quran journey →"
│   │    Active user:  Resume position + streak + goal % + plan label
│   │    Position:     ~214dp below sheet top; top edge visible at fold
│   │                  on ≥667dp devices
│   │    Degradation:  New-user CTA is an invitation, not an empty state
│   │    Tap target:   Opens QuranReader at last position (or surah index)
│   │
│   ├── Listening Row  [PRIMARY USER GOAL 3]
│   │    Conditional:  INVISIBLE when no listening history exists
│   │                  No placeholder, no empty state, no gap
│   │    Active:       "🎧 Continue · [Reciter] · [Surah] →"
│   │    Tap target:   Resumes audio via player entry pipeline
│   │    Position:     Immediately below Quran card
│   │
│   └── Athkar Compact Card  [PRIMARY USER GOAL 4]
│        Always visible: three rows, always present
│        Row ordering: time-contextual (most urgent category first)
│        │   Morning → first at Fajr time
│        │   Evening → first at Maghrib time
│        │   Sleep   → first after Isha
│        ├── [Icon] Morning Athkar  [✓ Done / N remaining / Not started]  →
│        ├── [Icon] Evening Athkar  [✓ Done / N remaining / Not started]  →
│        └── [Icon] Sleep Athkar    [✓ Done / N remaining / Not started]  →
│             Tap any row: opens AthkarDetailsRoute for that category
│             Completion refreshes when returning from Athkar screen
│
└── ④ FOOTER  [single utility, no section framing]
    │
    └── Tasbeeh
         Reason: only major Islamic tool without a bottom-nav tab
         Presentation: single icon link, minimal visual weight
         No section header ("Tools" / "Utilities" header removed — KISS)
```

---

## 4. USER JOURNEY MAPS

### Journey A — New User: App Launch → First Meaningful Action

**User profile:** First launch or cleared data. No reading history. No listening history. No completed Athkar.

```
[Launch]
    │
    ▼  0 seconds
┌─────────────────────────────────────────┐
│  HOME — Hero                            │
│  Asr · 4:22 PM · in 1h 14m             │ ← Value delivered: prayer context
│  20 Dhul Hijjah 1447                   │
└─────────────────────────────────────────┘
    │  Zero taps, zero scroll
    ▼  ~1 second (screen renders)
┌─────────────────────────────────────────┐
│  TODAY — Daily Ayah (at/near fold)      │
│  ﴿ وَمَن يَتَّقِ اللَّهَ ﴾              │ ← Value delivered: daily content
│  And whoever fears Allah…               │   specific to today
│  At-Talaq 65:2–3        [🔖] [↗]       │
└─────────────────────────────────────────┘
    │  Zero taps. Optional: tap [🔖] to bookmark.
    ▼  ~2 seconds
┌─────────────────────────────────────────┐
│  [Short scroll — ~80dp]                 │
│  YOURS — Quran Card                     │
│  "Begin your Quran journey →"           │ ← Decision point: start Quran?
└─────────────────────────────────────────┘
    │  TAP (1 tap)
    ▼  ~3 seconds
┌─────────────────────────────────────────┐
│  Quran Index / Surah Selector           │ ← FIRST MEANINGFUL ACTION
│  User selects Al-Fatiha                 │
└─────────────────────────────────────────┘

Metrics:
  Taps to value:        0 (prayer visible immediately)
  Taps to first action: 1 (Quran card tap)
  Scroll distance:      ~80dp
  Time to value:        < 2 seconds (prayer + Ayah visible)
  Time to first action: ~3 seconds
```

---

### Journey B — Returning User: Resume Quran

**User profile:** Active reader, Day 12 streak, reading Al-Baqarah page 45, 65% of today's goal complete.

```
[Launch]
    │
    ▼  0s — Hero renders immediately (local data)
┌─────────────────────────────────────────┐
│  Asr in 1h 14m  ·  Day 12 🔥           │ ← Prayer + streak visible
└─────────────────────────────────────────┘
    │  Zero taps, zero scroll
    ▼  ~1s — content sheet loads
┌─────────────────────────────────────────┐
│  Daily Ayah (familiar anchor)           │ ← Quick glance, no action needed
└─────────────────────────────────────────┘
    │  Short scroll (~190dp + 24dp gap)
    ▼  ~1.5s
┌─────────────────────────────────────────┐
│  📖 Al-Baqarah · Page 45               │
│  ████████████░░░░  65%   Day 12 🔥    │ ← Progress immediately visible
│  Ramadan Khatma · Week 3              → │
└─────────────────────────────────────────┘
    │  TAP (1 tap)
    ▼  ~2.5s
┌─────────────────────────────────────────┐
│  Quran Reader — Al-Baqarah, Page 45     │ ← RESUMED
└─────────────────────────────────────────┘

Metrics:
  Taps:           1
  Scroll:         ~214dp (Daily Ayah height + gap)
  Time to resume: ~2.5 seconds
  Decision cost:  Zero — card shows exact position, no ambiguity
```

---

### Journey C — Audio User: Continue Listening

**User profile:** Regular listener. Last played Sheikh Mishary, Al-Baqarah. No active Quran reading (reader-agnostic user).

```
[Launch]
    │
    ▼  0s
┌─────────────────────────────────────────┐
│  Hero — prayer context                  │
└─────────────────────────────────────────┘
    │
    ▼  ~1s
┌─────────────────────────────────────────┐
│  Daily Ayah — brief glance              │
└─────────────────────────────────────────┘
    │  Scroll (~214dp for Quran card + ~88dp Quran card height + 24dp gap)
    ▼  ~2s — total scroll ~326dp
┌─────────────────────────────────────────┐
│  📖 Al-Baqarah · Page 45 (Quran card)  │
│  🎧 Continue · Sheikh Mishary · Al-Baq→│ ← Listening row visible together
└─────────────────────────────────────────┘
    │  TAP Listening row (1 tap)
    ▼  ~3s
┌─────────────────────────────────────────┐
│  Audio resumes · Mini-player appears    │ ← RESUMED
└─────────────────────────────────────────┘

Metrics:
  Taps:          1
  Scroll:        ~326dp
  Time to audio: ~3 seconds
  Note: user sees Quran card before Listening row — if they also read,
  both are visible at the same scroll position (positive UX adjacency)
```

---

### Journey D — Athkar User: Daily Completion

**User profile:** Committed to daily Athkar. Morning done. Evening pending. After Maghrib.

```
[Launch]
    │
    ▼  0s
┌─────────────────────────────────────────┐
│  Hero — "Maghrib in 4 minutes"          │ ← Urgency established by hero
└─────────────────────────────────────────┘
    │  Prayer card creates Athkar intent
    ▼  ~1s
┌─────────────────────────────────────────┐
│  Daily Ayah — quick glance              │
└─────────────────────────────────────────┘
    │  Scroll (~430dp: Ayah + Quran card + Listening row + gap)
    ▼  ~2s
┌─────────────────────────────────────────┐
│  🌙 Evening Athkar   34 remaining  →   │ ← Evening sorted FIRST
│  ☀  Morning Athkar   ✓ Done        →  │   (Maghrib time contextual sort)
│  ★  Sleep Athkar     Not started   →  │
└─────────────────────────────────────────┘
    │  TAP Evening row (1 tap)
    ▼  ~3s
┌─────────────────────────────────────────┐
│  Evening Athkar detail screen           │ ← STARTS PRACTICE
└─────────────────────────────────────────┘
    │  Completes Evening Athkar (~4 minutes)
    ▼
┌─────────────────────────────────────────┐
│  Returns to Home                        │
│  🌙 Evening Athkar   ✓ Done        →  │ ← COMPLETION VISIBLE
│  ☀  Morning Athkar   ✓ Done        →  │
│  ★  Sleep Athkar     Not started   →  │
└─────────────────────────────────────────┘

Metrics:
  Taps:            1
  Scroll:          ~430dp
  Time to Athkar:  ~3 seconds
  Post-completion: Completion state visible without re-opening
  Note: Scroll distance is highest of all four journeys. See Risk R-03.
```

---

## 5. PHASE PREVIEW MOCKUPS

### Phase 1 Preview: After Removals Only

*What Home looks like after Phase 1 is complete and nothing else has changed.*

```
┌─────────────────────────────────────────────────┐
│ ╔═══════════════════ HERO ════════════════════╗ │
│ ║  [Gradient] Muhammad · 20 Dhul Hijjah       ║ │
│ ║  ┌──────────────── Next Prayer ───────────┐ ║ │
│ ║  │  Asr  4:22 PM  in 1h 14m  📍 London  │ ║ │
│ ║  └────────────────────────────────────────┘ ║ │
│ ╚═══════════════════════════════════════════════╝ │
│                                                   │
│  ┌─────────────────────────────────────────────┐  │  ← Quran card (unchanged)
│  │ 📖  Last Read / Start Reading             → │  │
│  │     Al-Baqarah · Page 45                   │  │
│  └─────────────────────────────────────────────┘  │
│  [24dp gap]                                       │
│  Your Rituals                [edit ✎]             │  ← Section header (unchanged)
│  ┌─────────────────────────────────────────────┐  │
│  │ ☀  NOW  Evening Athkar  Begin Now →        │  │  ← Contextual card (unchanged)
│  └─────────────────────────────────────────────┘  │
│  [pinned athkar list]                             │  ← Pinned list (unchanged)
│  [24dp gap]                                       │
│  ┌─────────────────────────────────────────────┐  │
│  │ Daily Ayah  ·  Daily Dua                    │  │  ← Buried (unchanged position)
│  └─────────────────────────────────────────────┘  │
│                    [🧿 Tasbeeh]                   │  ← Relocated to footer
│                                                   │
│ [════════════ Bottom Navigation ════════════════] │
└─────────────────────────────────────────────────┘

PHASE 1 DELTA:
[✓ REMOVED] Prayer Day Strip (5 prayer pills)
[✓ REMOVED] Reciters tile
[✓ REMOVED] Qibla tile
[✓ REMOVED] Smart Khatma tile (or moved into Quran card, Phase 3)
[✓ REMOVED] "Discover / Explore" section header
[✓ REMOVED] Grid ↔ list toggle
[✓ MOVED]   Tasbeeh → minimal footer link
[= UNCHANGED] Everything else

STATUS: Screen is simpler but Daily Ayah is still buried.
        Phases 2–5 complete the redesign.
```

---

### Phase 2 Preview: Daily Ayah Promoted

```
┌─────────────────────────────────────────────────┐
│ ╔════════════════════ HERO ════════════════════╗ │
│ ║  [Gradient] Muhammad · 20 Dhul Hijjah        ║ │
│ ║  ┌───────────── Next Prayer ───────────────┐ ║ │
│ ║  │  Asr  4:22 PM  in 1h 14m         📍   │ ║ │
│ ║  └────────────────────────────────────────┘ ║ │
│ ╚═══════════════════════════════════════════════╝ │
│ ──────────────── TODAY ──────────────────────── │  ← NEW SECTION INTRODUCED
│  ┌─────────────────────────────────────────────┐  │
│  │ 📅 Today · 20 Dhul Hijjah                  │  │
│  │ ﴿ وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ ﴾   │  │  ← PROMOTED: now above Quran
│  │ And whoever fears Allah…                   │  │
│  │ At-Talaq 65:2–3             [🔖] [↗ share] │  │  ← NEW: interactive
│  └─────────────────────────────────────────────┘  │
│ ──────────────── YOURS ──────────────────────── │
│  ┌─────────────────────────────────────────────┐  │
│  │ 📖  Last Read / Start Reading             → │  │  ← Quran card (unchanged)
│  └─────────────────────────────────────────────┘  │
│  [Your Rituals section — unchanged from Phase 1]  │
│  [Tasbeeh footer]                                 │
│ [════════════ Bottom Navigation ════════════════] │
└─────────────────────────────────────────────────┘

PHASE 2 DELTA from Phase 1:
[✓ MOVED]    Daily Ayah from bottom → top of content sheet
[✓ ADDED]    Bookmark + Share actions on Daily Ayah
[✓ ADDED]    TODAY / YOURS visual layer separation (section labels or dividers)
[✓ REMOVED]  Daily Ayah from old buried position
[= UNCHANGED] All other elements
```

---

### Phase 3 Preview: Quran Progress Enhanced

```
│ ──────────────── TODAY ──────────────────────── │
│  [Daily Ayah Card — as Phase 2]                  │
│ ──────────────── YOURS ──────────────────────── │
│  ┌─────────────────────────────────────────────┐  │
│  │ 📖  Al-Baqarah · Page 45                   │  │  ← ENHANCED
│  │     ████████████░░░░  65%   Day 12 🔥     │  │  ← NEW: streak + goal
│  │     Ramadan Khatma · Week 3 of 10           │  │  ← NEW: plan label
│  │                                           → │  │
│  └─────────────────────────────────────────────┘  │
│  [Listening row — absent until Phase 4]           │
│  [Athkar — still old pinned list from Phase 1]   │
│  [Tasbeeh footer]                                 │
```

---

### Phase 4 Preview: Continue Listening Added

```
│ ──────────────── YOURS ──────────────────────── │
│  [Quran Progress Card — as Phase 3]               │
│  ┌─────────────────────────────────────────────┐  │
│  │ 🎧  Continue · Sheikh Mishary · Al-Baqarah → │  │  ← NEW ELEMENT
│  └─────────────────────────────────────────────┘  │
│  [Athkar — still old pinned list]                 │
│  [Tasbeeh footer]                                 │
```

---

### Phase 5 Preview: Athkar Compact Card (Final State)

```
│ ──────────────── YOURS ──────────────────────── │
│  [Quran Progress Card — as Phase 3]               │
│  [Listening Row — as Phase 4]                     │
│  ┌─────────────────────────────────────────────┐  │
│  │ 🌙  Evening Athkar   34 remaining        → │  │  ← REPLACED: contextual
│  │ ──────────────────────────────────────────  │  │    sort (Maghrib time)
│  │ ☀   Morning Athkar   ✓ Done             → │  │
│  │ ──────────────────────────────────────────  │  │
│  │ ★   Sleep Athkar     Not started        → │  │
│  └─────────────────────────────────────────────┘  │
│  [Tasbeeh footer]                                 │
│ [════════════ Bottom Navigation ════════════════] │

FINAL STATE: All phases complete. This is Concept C.
```

---

## 6. UX RISK ASSESSMENT

### R-01: Daily Ayah Below Fold on Small Devices

| Attribute | Value |
|-----------|-------|
| Risk | On 480dp devices, Daily Ayah card is partially cut off (~88dp visible from ~190dp total) |
| Severity | **Medium** |
| Likelihood | Low-Medium (480dp devices are <15% of active Android users as of 2024) |
| User impact | New user on small device may not see the full Today anchor without scrolling |

**Mitigation:**
- Reduce Daily Ayah internal padding from 16dp → 12dp when `MediaQuery.size.height < 568`.
- Cap Arabic text at 2 lines (instead of 3) on small screens.
- Ensure the card top edge is always fully visible — only content below the fold is clipped, never the card header.
- Accept: a short scroll to see the full card is not a failure state.

---

### R-02: Quran Card Below Fold on Small Devices

| Attribute | Value |
|-----------|-------|
| Risk | On 480dp devices, Quran Progress Card requires scrolling to reach |
| Severity | **Low** |
| Likelihood | Low (same 480dp device population) |
| User impact | Returning user must scroll to access primary goal 2 |

**Mitigation:**
- This is an inherent constraint of the hero height on small screens. The hero cannot be reduced without degrading the prayer card.
- Accept on small devices. Acceptance criterion AC-3.1 is explicitly scoped to "667px height or greater."
- Monitor analytics: if scroll depth to Quran card is low on small devices, consider a compact hero variant for devices below 568dp.

---

### R-03: Athkar Journey Has Longest Scroll Distance

| Attribute | Value |
|-----------|-------|
| Risk | Athkar Compact Card is the third element in the Yours layer (~430dp from sheet top on returning user with listening history) |
| Severity | **Medium** |
| Likelihood | High (every Athkar-first user experiences this scroll) |
| User impact | Users whose primary daily action is Athkar must scroll past Quran card and Listening row |

**Mitigation:**
- Time-contextual row ordering within the Athkar card partially compensates: the most urgent category is highlighted first. A user after Maghrib sees "Evening Athkar 34 remaining" as the card's top row, which creates urgency without reducing scroll distance.
- Consider: if analytics show that Athkar is the most-used primary action (more than Quran resume), swap the Athkar card and Quran card positions in the Yours layer. This is a data-driven decision to make post-launch, not before.
- Do not act on this risk before launch — reordering before data risks optimising for the wrong user segment.

---

### R-04: Pinned Athkar Feature Removal (Phase 5)

| Attribute | Value |
|-----------|-------|
| Risk | Phase 5 removes the ability to pin arbitrary athkar categories to Home |
| Severity | **Medium-High** |
| Likelihood | Unknown (adoption data not reviewed before this document) |
| User impact | Users who have customised their pinned Athkar list lose that configuration on Home |

**Mitigation:**
- Before implementing Phase 5, query analytics for "pinned athkar edit" event frequency. If >5% of DAU have ever modified their pinned list, the pinning feature has meaningful adoption and its removal needs communication.
- The three canonical categories (Morning, Evening, Sleep) cover the daily practice of the large majority of users. Custom pinning of, e.g., "Friday Surah" or "Quranic Supplications" is a power-user behaviour.
- Consider: keep pinning as a feature within the Athkar tab, remove it only from Home. This preserves the capability while simplifying Home.
- If pinning is removed from Home, add a brief in-app notification on first launch after Phase 5: "Your Athkar on Home now shows Morning, Evening, and Sleep at a glance."

---

### R-05: Continue Listening Row — Flash on Cold Launch

| Attribute | Value |
|-----------|-------|
| Risk | Last-played state loads asynchronously; row may appear then disappear (flicker) if it loads empty then populates |
| Severity | **Medium** |
| Likelihood | Low (if state source is synchronous local storage) |
| User impact | Row flickers, creating visual instability |

**Mitigation:**
- Read last-played state from synchronous local storage (Hive) before first frame. If synchronous read is not possible, keep the row invisible until state is confirmed present or absent — never show a loading state.
- Acceptance criterion AC-4.5 explicitly tests for this: "row either appears immediately or appears after a brief delay without first appearing and then disappearing."
- Implementation must use a `FutureBuilder` or stream that does not emit an intermediate empty state. The initial value of the cubit state must be "unknown" (hidden row), not "empty" (hidden row), not "loading" (placeholder row).

---

### R-06: Athkar Completion State Staleness

| Attribute | Value |
|-----------|-------|
| Risk | User completes Athkar in sub-screen; returns to Home; compact card still shows "N remaining" |
| Severity | **High** (if it occurs, it directly contradicts the dashboard's value proposition) |
| Likelihood | Medium (depends on whether `HomeAthkarCompactCubit` listens to a stream or fires a one-shot query) |
| User impact | User loses trust that the card reflects reality; stops relying on it |

**Mitigation:**
- `HomeAthkarCompactCubit` must subscribe to an athkar completion **stream** from the athkar repository, not query once on init.
- Alternatively, call `context.read<HomeAthkarCompactCubit>().refresh()` from the `HomeScreen`'s `didChangeDependencies` or `RouteAware.didPopNext` lifecycle hook.
- Acceptance criterion AC-5.6 explicitly tests the completion-then-return flow.
- This is the single highest-priority implementation correctness requirement in Phase 5.

---

### R-07: New-User Yours Layer Appears Sparse

| Attribute | Value |
|-----------|-------|
| Risk | On day 1, the Yours layer shows: "Begin journey" CTA (no data), no Listening row, three "Not started" Athkar rows. The section feels thin. |
| Severity | **Low-Medium** |
| Likelihood | High (every new user experiences this) |
| User impact | New user may perceive the app as not having much to offer |

**Mitigation:**
- The Today layer (Daily Ayah) is always full — it provides emotional weight that compensates for a sparse Yours layer.
- The "Begin your Quran journey" CTA must be visually intentional — not a placeholder, but a styled invitation with a clear arrow affordance.
- The Athkar card showing three "Not started" rows is not an empty state — it is a checklist with three actionable items. The rows must look actionable (chevrons, tappable surfaces) not inactive.
- After the user completes their first Quran session and first Athkar category, the Yours layer fills immediately. The first session should be the goal of onboarding, which operates independently of Home.

---

### R-08: Accessibility — Athkar Card Row Tap Target Size

| Attribute | Value |
|-----------|-------|
| Risk | Each row in the Athkar Compact Card must meet minimum tap target size (48dp × 48dp per Material and Apple HIG) |
| Severity | **Medium** |
| Likelihood | Medium (compact rows risk being too short if not explicitly sized) |
| User impact | Users with motor impairments fail to tap the correct row |

**Mitigation:**
- Enforce `minHeight: 48` on each row's tap target via `ConstrainedBox` or `SizedBox`.
- Ensure each row uses an `InkWell` or `GestureDetector` with a hit-test box that extends to the full row width.
- Do not rely on the text label size as the tap target — the entire row (including empty space) must be tappable.

---

### R-09: Prayer Calculation Cold Start

| Attribute | Value |
|-----------|-------|
| Risk | Hero shows "Detecting..." or error state on first launch while prayer calculation initialises or location is unavailable |
| Severity | **Low** |
| Likelihood | Low (existing behaviour, not changed by this redesign) |
| User impact | Hero appears broken on first launch |

**Mitigation:** This risk predates the redesign and is handled by the existing hero's failure and loading states. Not a new risk introduced by Concept C.

---

### Risk Summary Table

| ID | Risk | Severity | Likelihood | Phase |
|----|------|----------|-----------|-------|
| R-01 | Daily Ayah below fold on small devices | Medium | Low-Med | 2 |
| R-02 | Quran card below fold on small devices | Low | Low | 3 |
| R-03 | Athkar journey longest scroll distance | Medium | High | 5 |
| R-04 | Pinned Athkar removal breaks power users | Medium-High | Unknown | 5 |
| R-05 | Continue Listening row flicker | Medium | Low | 4 |
| R-06 | Athkar completion state staleness | **High** | Medium | 5 |
| R-07 | New-user Yours layer feels sparse | Low-Med | High | All |
| R-08 | Athkar row tap target too small | Medium | Medium | 5 |
| R-09 | Prayer calculation cold start | Low | Low | Pre-existing |

---

## 7. FINAL RECOMMENDATION BEFORE IMPLEMENTATION

### Architecture is confirmed. Begin Phase 1.

The wireframes, viewport analysis, and journey maps confirm that the approved Concept C architecture is sound. No blocking issues were identified.

**Four items to carry into implementation as hard constraints:**

1. **Daily Ayah card must use adaptive padding on small screens** (R-01). Implement a `height < 568dp` breakpoint that reduces internal padding to 12dp and caps Arabic text at 2 lines.

2. **Athkar Compact Card must subscribe to a completion stream, not a one-shot query** (R-06). This is the highest-risk implementation correctness requirement. If the stream subscription is not feasible in Phase 5, implement a `didPopNext` refresh hook as the fallback — but the stream is strongly preferred.

3. **Athkar row minimum tap target: 48dp height** (R-08). Enforce in the widget, not as a review afterthought.

4. **Audit pinned Athkar adoption before deleting the feature in Phase 5** (R-04). Check analytics before removing user-set configuration. This is a data gate, not a design gate — Phase 5 should not proceed to production without this check.

**One item to defer to post-launch:**

- R-03 (Athkar scroll distance): If analytics show Athkar is the majority primary action, swap Athkar card and Quran card in the Yours layer. This decision requires real user data and should not be pre-optimised.

**Phase 1 is safe to begin.** It is purely subtractive, all risks are downstream, and rollback is a clean git revert.
