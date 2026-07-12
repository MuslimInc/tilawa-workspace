# Research & Traceability: MeMuslim Core Trust & Reliability

> **Evidence-first reconciliation (2026-07-12).** This document is rebuilt from the
> raw review rows in `docs/khatmah_reviews_deep_analysis_for_memuslim.xlsx`
> (sheet `المراجعات`, 59 rows) and cross-checked against the actual MeMuslim
> repository. Competitor reviews are treated as evidence of **user expectation,
> market pain, and trust risk — NOT as proof that MeMuslim has the same defect.**
> Derived workbook sheets (`الملخص`, `الموضوعات`, `خطة MeMuslim`) were validated
> against the raw sheet; where they disagree, the raw sheet wins and the
> discrepancy is logged in §1.

## 0. Source provenance & sampling caveat

- **Primary source**: `docs/khatmah_reviews_deep_analysis_for_memuslim.xlsx`, 5 sheets
  (`الملخص`, `المراجعات`, `الموضوعات`, `خطة MeMuslim`, `المصادر`). CSV exports of each
  exist under `docs/khatmah_*.csv`. All 5 sheets and all 59 review rows were read.
- **Sample size**: 59 reviews, dated **2024-12-20 → 2026-07-06**.
- **Sampling bias (critical)**: the sample is **extremes-only** — 19×5★ and 40×1★,
  **no 2–4★ rows at all**, hand-transcribed from Google Play screenshots (`S01–S19`).
  The workbook's own summary sheet states this. Therefore:
  - Percentages ("% of sample") measure the **curated screenshot set, not Khatmah's
    true rating distribution** (Khatmah's public average is 4.9★). Do **not** quote
    these percentages as market satisfaction.
  - Frequency counts are directional signal for *what themes recur*, not a
    statistically representative demand estimate.
- **These are Khatmah's reviews.** Every defect below is a *Khatmah* user experience.
  MeMuslim applicability is assessed separately against repository evidence.

## 1. Extraction-quality audit (raw sheet vs derived sheets)

Per-row validation of the raw sheet surfaced the following **extraction uncertainties**.
None were silently corrected; they are recorded here and flow into the classifications.

### 1.1 Missing / inferred data
| Row (م) | Reviewer | Issue |
|---|---|---|
| K30, K33, K45 | "غير ظاهر في الصورة" | Reviewer name not visible; row inferred from a partial screenshot card. |
| K36 | مصطفى الليلي | **Date missing** ("التاريخ غير ظاهر"); recency for this row is unknown. |
| K07 | Tariq Satar | Text **partial/truncated** ("جزئي"); no specific feature is verifiable from it. |
| K11, K17, K27, K30, K33, K39(sec), K45, K46 | — | Marked "كامل تقريبًا" (almost complete); wording may be lightly clipped. |

### 1.2 Rating-vs-text conflicts (the single most important extraction finding)
The raw sheet's `توافق النص مع النجوم` column flags **5 rows with clearly positive text
but a 1★ rating** — K09, K20, K23, K41, K47 (tag: *"غير متوافق (نص إيجابي مع نجمة واحدة)"*),
plus **1 mixed/request row at 1★** (K24). The workbook's summary reports "5".
- **Consequence**: the raw 1★ count (40) **overstates negative signal**. Removing the
  5 positive-text 1★ rows (and the 1 mixed) leaves **~34–35 genuinely negative 1★
  reviews**. Any statement resting on "40 one-star reviews" must be softened.
- **Root cause per the workbook**: users appear to misuse the star control. This is a
  research caveat, **not** evidence of a MeMuslim defect. It does mean sentiment must be
  derived from **text**, not stars.

### 1.3 Theme-assignment problems (raw rows re-checked)
- **`سلامة نص القرآن والبيانات الدينية` conflates four distinct problems.** The 7 rows
  tagged with this single theme (K12, K15, K22, K27, K34, K45, K46) are **not one
  defect class**:
  | Row | Actual sub-problem | Correct concept |
  |---|---|---|
  | K12 | "أخطاء وحروف ناقصة" (vague) | Glyph / rendering integrity |
  | K22 | "تحريفات للقرآن" (vague claim) | Perceived text integrity (unverified) |
  | K34 | "quran is not fully correct" (vague) | Perceived text integrity (unverified) |
  | K45 | Az-Zukhruf 22 specific wording | Text correctness (verifiable) |
  | K46 | Hud ayah **number** 47 vs 147 | Ayah **numbering / metadata**, not glyphs |
  | K27 | Juz 9/10 boundary in the Khatma | **Juz/Hizb boundary mapping** (plan data) |
  | K15 | "أدعية مسيحية في وسط الأدعية" | **Athkar/Dua content** — *not Quran text at all* |
  - The current Spec 043 Domain A treats all of these as one "Quran integrity" pipeline.
    K15 is **Athkar content governance** (different asset, different owner). K27 is
    **Khatma/Juz mapping** (touches Spec 023's plan generation). K46 is ayah-index
    metadata. These must be separated (see §4 and updated FRs).
- **`الأذان ومواقيت الصلاة` (10 rows) mixes three failure modes** the reviews state
  distinctly: total non-firing (K16, K26, K29, K31, K42), **late/incorrect timing**
  (K19, K25, K36), and **incomplete audio** (K33). Spec 043 already distinguishes the
  pipeline stages (good); the traceability keeps these separate.
- **`الموقع والصلاحيات` is a single row (K13)** — see §1.4.

### 1.4 Numeric reconciliation (my recount vs derived sheets)
| Metric | Derived sheet says | Raw recount | Verdict |
|---|---|---|---|
| Total reviews | 59 | 59 | ✅ match |
| 5★ / 1★ | 19 / 40 | 19 / 40 | ✅ match |
| Positive-text-at-1★ | 5 | 5 (+1 mixed) | ✅ (label precisely) |
| `الأذان` theme | 10 | 10 | ✅ (summary's "11" folds in location) |
| Integrity theme | 7 | 7 | ✅ count, ❌ **conflated** (see §1.3) |
| Location theme | 1 | 1 | ✅ — **N=1**, severity-driven |
| Riwayat theme | 3 | 3 (K39, K40, K56) | ✅ |
| Parity theme | 3 | 3 (K04, K10, K11) | ✅ |
| Ads/payment theme | 4 | 4 (K30, K32, K37, K38) | ✅ |
| Khatma/Wird theme | 2 | 2 (K01, K57) | ✅ — under-counts the *positive praise* embedded in general 5★ text |

## 2. Recalculated themes & weighted prioritization

### 2.1 Scoring rubric (documented formula)
Themes are **not ranked by raw frequency** (the sample is extremes-only and small).
Each theme scores 0–3 on six grounded attributes; the priority score is:

```
Score = 1.0·FreqN + 3.0·ReligiousTrust + 2.0·UserBlocking + 1.0·Recency
        + 1.5·MeMuslimApplicability − 1.0·ImplementationCost
FreqN = min(3.0, count/59 × 10)   # ~10% of sample ≈ 1.0, capped at 3
```
Weights encode the product rule stated across the workbook: **trust and
user-blocking dominate frequency.** Attribute values and rationale live in
`research-coverage.md`.

### 2.2 Ranked themes (rebuilt from raw rows)
| Rank | Theme | N | Score | Signal type | Priority |
|---|---|---|---|---|---|
| 1 | Adhan & prayer-time reliability | 10 | 21.2 | Recurring critical | **P0** |
| 2 | Quran/religious-content integrity (aggregate) | 7 | 19.7 | Existential trust | **P0** |
| 3 | Adhkar/Dua content correctness | 1 | 15.7 | **High-severity, low-frequency** | **P0 (preventive/governance)** |
| 4 | Ads / support-prompt / paywall clarity | 4 | 15.2 | Trust risk | P1 |
| 5 | Location dead-end / manual fallback | 1 | 14.7 | **High-blocking, low-frequency** + confirmed repo gap | **P0** |
| 6 | Elderly / simplicity / accessibility | 1 | 10.7 | Differentiation | P1 |
| 7 | Android/iOS parity | 3 | 10.5 | Fairness/trust | P1 |
| 8 | Khatma & daily Wird loop | 2 | 9.8 | **Retention engine** (under-counted) | P1 → **Spec 023** |
| 9 | Riwayat (Warsh/Qaloon) | 3 | 8.5 | Market fit | P2 |
| 10 | UI/UX modernization + premium look | 4 | 8.2 | Differentiation | P1 |
| 11 | Quality regression after update | 1 | 8.2 | Process control | P1 (eng process) |
| 12 | Audio/recitation playback | 1 | 8.2 | Core feature | P1 |
| 13 | App stability / crashes | 1 | 8.2 | Reliability | P1 |
| 14 | Widgets & adherence tracking (Khatma widget) | 2 | 7.8 | Retention | P1 → **Spec 041/023 (gap, see §7)** |
| 15 | All-in-one value (positive) | 3 | 6.5 | Positioning | strategy |
| 16 | Tafsir availability | 1 | 5.2 | Feature gap | P2 |
| 17 | Adhan sound customization (regional) | 1 | 3.2 | Personalization | P2 |
| 18 | Product-freshness signal | 1 | 2.7 | Perception | P2 |

`تقييم عام` (11 rows, "general praise/complaint") is **excluded from prioritization**:
it carries no product-specific signal and is a satisfaction indicator only.

### 2.3 High-severity, low-frequency risks (do NOT drop for low N)
- **Adhkar/Dua content correctness** — K15 (N=1). Existential trust; preventive.
- **Location dead-end** — K13 (N=1). Hard user block; confirmed repo gap.
- **Ayah numbering / Juz boundary** — K46, K27 (N=1 each). Corrupt citations/plans.
These are **severity-driven preventive/gap requirements**, explicitly labeled as such.

## Research Prioritization Model (transparent)

### 2.4 Dimensions
**Exact numeric formula (only these six terms are in the score):**
```
Score = 1.0·FreqN + 3.0·Trust + 2.0·Blocking + 1.0·Recency + 1.5·Applicability − 1.0·ImplRisk
```
Every candidate dimension is classified below as **[NUMERICAL]** (in the formula),
**[METADATA]** (recorded and used for judgment/classification but **not** in the score),
**[UNAVAILABLE]** (no data; excluded), or **[POLICY FLOOR]** (a hard rule independent of the
score). Earlier drafts implied Retention/Acquisition were "folded into others" — **corrected:
they are METADATA and do not affect the number.** Source tags: 🔬 research-derived,
🗄️ repository-derived, ⚖️ product judgment.

| Dimension | Class | In score? weight | Scale & values | Normalization | Source | Uncertainty handling |
|---|---|---|---|---|---|---|
| Frequency | **NUMERICAL** | ×1.0 | raw count → `FreqN` | `FreqN = min(3.0, (count/59)×10)`: 10% of sample→1.0, 30%→3.0 (cap). Puts frequency on the same 0–3 scale as Trust/Blocking. | 🔬 | Extremes-only sample → directional, never demand |
| Religious trust | **NUMERICAL + POLICY FLOOR** | ×3.0 | 0=none…3=existential | direct 0–3 | ⚖️ | High weight by policy; also a floor (below) — never demoted by a low score |
| User blocking | **NUMERICAL** | ×2.0 | 0=cosmetic…3=hard block | direct 0–3 | 🔬+⚖️ | Conservative when review text is vague |
| Recency | **NUMERICAL** | ×1.0 | 0=old…3=<3mo | direct 0–3 | 🔬 | K36 undated → cluster recency |
| Applicability to MeMuslim | **NUMERICAL** | ×1.5 | 0=N/A…3=core | direct 0–3 | 🗄️+⚖️ | Low where MeMuslim differs (e.g. ads→0–1) |
| Implementation risk | **NUMERICAL** | −1.0 | 0=trivial…3=high | subtracted | ⚖️ | Higher for riwayat/CDN-font work |
| Retention impact | **METADATA** | not in score | 0–3 | — | ⚖️ | Recorded to inform P-tier judgment; inferred, labeled |
| Acquisition impact | **METADATA** | not in score | 0–3 | — | ⚖️ | Recorded only; low confidence (widgets/UI) |
| Repository evidence strength | **METADATA (classification gate)** | not in score | 0–3 | — | 🗄️ | Drives DEF/GAP/PREV/ASSUM classification, **not** the rank |
| Helpfulness | **UNAVAILABLE** | not in score | 0–3 by votes | — | 🔬 | **Not captured in the workbook** — excluded, never guessed |

So the number is driven by six dimensions; four more are metadata/unavailable and do **not**
move the score. Any priority decision that leans on Retention/Acquisition/RepoEvidence is a
**stated product judgment**, not a formula output.

**Why trust is weighted ×3.** Religious-content and adhan-timing errors are *category-defining*
for a Quran-first app: a single confirmed error can void the value of every other feature
(a point the workbook makes explicitly). Trust weight therefore acts as a **floor** — the
model may raise a theme's priority on trust, but a low score elsewhere may **never demote a
religious-safety requirement below P0**. The scoring formula informs ordering; it does **not**
override the religious-safety requirements (integrity, adhan correctness, athkar governance),
which are P0 by policy regardless of score.

### 2.5 Sensitivity analysis
Three weightings (others ×1 throughout):
- **Model A — trust-first**: trust ×3, blocking ×2, frequency ×1.
- **Model B — balanced**: trust ×2, blocking ×2, frequency ×2.
- **Model C — frequency-first**: frequency ×3, trust ×2, blocking ×1.

| Theme | A | B | C | Swing | Reading |
|---|---|---|---|---|---|
| Adhan reliability | 1 | 1 | 1 | **0** | Robust #1 — model-invariant |
| Quran text integrity | 2 | 2 | 2 | **0** | Robust #2 — model-invariant |
| Ads/paywall clarity | 4 | 3 | 3 | 1 | Stable top-4 |
| Location dead-end | 5 | 4 | 5 | 1 | Stable — severity carries it even at N=1 |
| Android/iOS parity | 6 | 7 | 6 | 1 | Stable mid |
| Elderly/simplicity | 7 | 6 | 7 | 1 | Stable mid |
| Khatma/Wird loop | 8 | 8 | 9 | 1 | Stable — retention bet, not frequency |
| Khatma progress widget | 12 | 12 | 11 | 1 | Stable lower-mid |
| Tafsir | 13 | 13 | 13 | **0** | Robust low |
| **Adhkar/Dua content** | 3 | 5 | 4 | **2** | **Rank is trust-weighting dependent** (N=1). P0 by *policy floor*, not by robust rank. |
| Riwayat | 9 | 11 | 10 | 2 | Weighting-dependent → confirms P2 is a judgment call |
| Audio/recitation | 10 | 10 | 12 | 2 | Frequency-sensitive |
| **UI/UX modernization** | 11 | 9 | 8 | **3** | **Biggest mover** — its priority is a product decision, not a robust research conclusion |

**Conclusions.**
- **Robust (keep regardless of model)**: Adhan #1 and Quran integrity #2; Tafsir low. The
  P0 trust core does not depend on the weighting.
- **Product decisions, not robust research**: the *rank* of **UI/UX modernization**
  (frequency-driven, swing 3), **Adhkar-content** (trust-driven, swing 2 — but P0 by policy
  floor), **Riwayat** and **Audio** (swing 2). These should be decided by product intent, and
  the docs label them as such rather than presenting the number as fact.
- The religious-safety floor (§2.4) means Adhkar-content stays P0 even though its numeric
  rank is unstable.

## 3. Strategic-insight validation

Each conclusion previously asserted in the workbook/roadmap, tested against review IDs.

| Strategic claim | Supporting IDs | Contradicting | Evidence strength | Keep? |
|---|---|---|---|---|
| Users value a simple daily Quran habit | K01, K05, K23, K57 | — | **Moderate** (praise in 5★ text; theme N only 2) | Yes |
| Khatmah's strongest loop is daily Wird/Khatma progress | K01, K48, K51, K57 | — | **Moderate–inferred** (strong qualitatively, low N) | Yes — label inferred |
| Older users value simplicity | K05 | — | **Weak** (single explicit mention) | Yes — as opportunity, not demand |
| Users value all-in-one experience | K02, K41, K49 | K08 (all-in-one but hated UI) | **Moderate** | Yes, with "don't sacrifice simplicity" |
| Clean/premium UI is a differentiator | K08(neg), K52 | — | **Moderate** | Yes |
| Widgets should support the daily habit | K48, K51 | — | **Moderate** (explicit, upvoted) | Yes → §7 gap |
| Athan reliability is high-impact trust | K16,K19,K25,K26,K29,K31,K33,K36,K42,K44 | — | **Strong** (10 rows, recurring across months) | Yes |
| Quran correctness is non-negotiable | K12,K22,K34,K45,K46 (+K27) | — | **Strong for severity**, moderate for frequency | Yes |
| Android/iOS parity affects satisfaction | K04, K10, K11, K14 | — | **Moderate** | Yes |
| Intrusive ads / unclear payment reduce trust | K30, K32, K37, K38 | — | **Moderate–strong** | Yes |
| Riwayat requested, not first-release | K39, K40, K56 | — | **Moderate** (incl. 1 churn: K40) | Yes — P2 |

**Rule applied**: inferred conclusions (habit loop, elderly) are labeled *inferred/weak*
and must not be presented as direct majority user statements.

## 4. Review→Spec traceability matrix

Classification legend: **DEF**=confirmed MeMuslim defect · **GAP**=confirmed product gap
· **PART**=partially implemented · **PREV**=preventive trust requirement · **DONE**=already
implemented · **OWN**=owned by another spec · **COMP**=competitor-specific · **REJ**=rejected
· **ASSUM**=unverified assumption. *No confirmed MeMuslim defect (DEF) exists in this table —
all Khatmah defects are unverified against MeMuslim (ASSUM/PREV) until reproduced.*

| Cluster | Review IDs | Theme | User need / pain | Evidence strength | MeMuslim repo evidence | Classification | Owner / Req | Acceptance |
|---|---|---|---|---|---|---|---|---|
| Adhan not firing | K16,K26,K29,K31,K42 | Adhan | Adhan silently fails / needs app open | Strong | `AdhanScheduler.kt`+`PrayerBootReceiver.kt`+watchdog exist; **not characterized for long-run delivery** | PREV+PART | 043 FR-006/007/008 | Health UI flags perm/battery; 7–14d delivery holds |
| Adhan late / wrong time | K19,K25,K36 | Adhan | Fires minutes late vs real adhan | Strong | Calc pipeline exists; no per-prayer offset/DST diag UI | GAP(diag) | 043 FR-008 + new **FR-018** | Diag screen shows tz/method/offset |
| Adhan audio incomplete | K33 | Adhan | Audio truncated/ducked | Moderate | `AdhanPlaybackService.kt`/audible channel exist; no audio-focus contract test | PREV | 043 FR-009 | Audio-focus + completion test passes |
| Quran text wrong (vague) | K12,K22,K34 | Integrity-text | Perceived missing letters/tahreef | Strong (severity) | Text = `assets/data/quran.json` + `quran_image` JSON; **no CI integrity test** | PREV(ASSUM) | 043 FR-001/002 | Build-time manifest asserts vs source; 0 confirmed |
| Quran text wrong (specific) | K45 | Integrity-text | Az-Zukhruf 22 wording | Strong | same | PREV | 043 FR-001 + FR-005 | Ayah reproducible-check + report flow |
| **Ayah numbering** | K46 | Integrity-**metadata** | Hud 47 shown as 147 | Moderate | Ayah index metadata; not glyph text | PREV(new) | 043 **FR-003 (extend to ayah-number map)** | Ayah/surah index asserted vs source |
| **Juz/Hizb boundary** | K27 | Integrity-**mapping** / plan | Juz 9/10 boundary off in Khatma | Moderate | Boundary data feeds Khatma plan | PREV+**OWN(023)** | 043 FR-003 (data) + **Spec 023** (plan uses it) | Juz/Hizb/quarter map asserted vs source |
| **Dua/Athkar content** | K15 | **Athkar content** | Non-Islamic text amid duas | Strong (severity) | Athkar curated; **no content manifest / dual-signoff** | PREV(new, governance) | 043 **GOV-003 (new)** — *not the Quran pipeline* | Every dua sourced+reviewed; kill-switch |
| Location dead-end | K13 | Location | GPS fails, no manual entry → stuck | Strong (blocking) | `LocationCubit` GPS-only; **no offline manual city** | **GAP** | 043 FR-015/016/017 | Deny GPS → manual city → correct times, 0 network |
| Android/iOS parity | K04,K10,K11,K14 | Parity | Feature missing on Android (audio/tafsir/long-press) | Moderate | Cross-platform app; parity not gated | GAP(process) | 043 FR-011–014 + **release gate**; tafsir=Spec TBD | No core Quran feature platform-exclusive w/o plan |
| Ads / paywall / support prompt | K30,K32,K37,K38 | Monetization | Repeated support popup / surprise paywall | Moderate | **No ads in MeMuslim** (positioning) | DONE(ads) + PREV(clarity) | Roadmap positioning; §8 non-copy | No repeated post-purchase prompt; cost shown upfront |
| UI old / premium look | K08,K21,K52 | UI/UX | Dated UI, eye strain / praise for clean | Moderate | Tilawa design system + tokens exist | DONE(partly)+opportunity | Roadmap P1 (design) | Calm modern UI; dark mode; comfortable Arabic type |
| Elderly / simplicity | K05 | Accessibility | Large type, short paths | Weak | Text-scale/RTL supported | Opportunity | Roadmap P1 (a11y) | Comfort mode; WCAG AA; 200% scale |
| Touch/settings hard | K18,K21 | UI/UX | Touch/overlay/settings confusion | Weak | — | ASSUM | Roadmap P1 | Interaction tests across densities |
| Riwayat Warsh/Qaloon | K39,K40,K56 | Riwayat | Non-Hafs riwayat (Maghreb) | Moderate (1 churn) | Hafs/QCF only | GAP(strategic) | **Deferred P2** (future spec) | Riwayat data layer; Warsh when Maghreb-targeted |
| Tafsir on Android | K14 | Tafsir | Tafsir parity/availability | Weak | — | GAP | **Future spec** (not 043) | Tafsir in unified Quran baseline |
| Audio/recitation | K35, K04(sec) | Audio | Recitations fail to play | Weak | Audio pipeline + CDN | PART | **Future/Spec TBD** | Link validation + fallback + retry |
| Continuous ayah long-press | K11 | Audio/interaction | Long-press to hear ayah (iOS parity) | Weak | — | GAP | Future/parity | Documented Mushaf interactions equal per platform |
| Khatma / daily Wird | K01,K57 (+praise K05,K23) | Habit loop | Organize khatma; daily wird; relationship w/ Quran | Moderate–inferred | **Spec 023 exists** (plan, today-target, calm catch-up, continue-reading) | **OWN(023)** | Spec 023 | Start plan → wird → resume in few steps |
| Widget: khatma progress | K48,K51 | Widgets | Khatma-progress widget + adherence days | Moderate | **Spec 041 has prayer/ayah/athkar/hijri — NOT khatma-progress**; 023 is in-app only | **GAP (unowned)** — §7 | **New: assign to 041 or 023** | Wird-progress widget + gentle streak |
| Regression after update | K43,K44 | Regression | "was good, got worse"; adhan stopped after update | Weak | — | PREV(process) | 043 (upgrade/reschedule tests) | Upgrade + reschedule tests; crash-free gate |
| Stability (vague) | K28 | Stability | "not working" (undiagnosable) | Weak | — | ASSUM | 043 FR-005 (report flow) | Context-attached problem report |
| Adhan sound choice | K17 | Personalization | Regional adhan voice | Weak | — | REJ-for-now/Defer | P2 | Licensed voice library (post-reliability) |
| Adhkar expansion | K54 | Content | More daily adhkar (e.g. salah on Prophet) | Weak | Athkar feature exists | Defer P2 | Spec TBD (sourced content) | Sourced packs w/ references |
| Product freshness | K24 | Perception | Wants "newer features" | Weak | — | Defer | Roadmap | Concise What's-New per release |
| Positive/general | K02,K03,K06,K07,K41,K47,K49,K50,K53,K55,K58,K59 (+all-in-one) | General | Satisfaction signal only | n/a | — | n/a (measure in-app) | Analytics | In-app feedback event after success |

**Coverage guarantee**: every non-general theme above resolves to a mapped requirement,
another owning spec, a documented deferral, a rejection, or a labeled preventive control.
Nothing is dropped silently. Unmapped-but-noted: Tafsir and Audio-recitation are flagged
as **future-spec**, not 043 — see `research-coverage.md`.

## 5. MeMuslim repository evidence (grounding — preserved from the architecture review)

These corrections from the prior repository-grounded review **remain in force**; the
research reconciliation must not re-introduce the false premises.

- **No `quran.db` and no `assets/quran/` directory exist.** Quran data is
  `apps/tilawa/assets/data/quran.json` + `packages/quran_image/assets/data/*.json` +
  `packages/quran_qcf` fonts. Domain A must target this real topology, not a SQLite DB.
- **QCF page fonts are downloaded at runtime from a CDN**
  (`packages/quran_qcf/.../quran_font_service.dart:downloadFonts()`), so a build-time
  manifest of *bundled* assets cannot cover the rendering-critical glyphs — the exact
  surface behind K12/K22 "missing letters." Integrity must extend to the downloaded
  font archive (post-download hash, fail-closed).
- **Adhan native pipeline exists and is partly characterized already**:
  `AdhanScheduler.kt`, `AdhanReceiver.kt`, `AdhanPlaybackService.kt`,
  `PrayerBootReceiver.kt`, `PrayerNotificationsWatchdogScheduler/Worker.kt`, plus
  existing tests incl. `PrayerWatchdogCharacterizationTest.kt`, `AdhanSchedulerTest.kt`,
  `PrayerBootReceiverTest.kt`. T-A00 is **extend/audit**, not "create baseline."
- **Actual audible channel id is `com.tilawa.app.prayer_adhan_v5`** (`AdhanReceiver.kt:29`),
  not `prayer_adhan_silent_v5`. Channel ids are version-suffixed deliberately; any change
  needs a new `_v6`, never an in-place edit.
- **Offline-city prototype already built**: `cities_prototype.db` (root) matches the ADR's
  measured 3.34 MB / <1 MB compressed / ~2–2.5 ms figures. The ADR is effectively
  validated → status should move from "Proposed" to "Accepted."
- **`scripts/generate_quran_manifest.dart` already exists** — Domain A is partly started.

## 6. Classification tally
- Confirmed MeMuslim **defects (DEF)**: **0** (no MeMuslim defect reproduced).
- Confirmed **product gaps (GAP)**: Location fallback; Khatma-progress widget (unowned);
  Android/iOS parity process; (strategic) Riwayat.
- **Preventive** trust/governance: Quran text integrity, ayah-number map, Juz/Hizb map,
  Adhkar content governance, adhan reliability hardening.
- **Owned elsewhere (OWN)**: Khatma/Wird loop → Spec 023; widgets → Spec 041.
- **Competitor-specific / not applicable**: intrusive ads, repeated support popup
  (MeMuslim has no ads).
- **Deferred (P2/future)**: Riwayat, Tafsir, audio-recitation robustness, adhan voice
  library, adhkar expansion, product-freshness messaging.
- **Unverified assumptions (ASSUM)**: all vague Khatmah "it's broken" rows (K28, K34, K22).

## 7. Cross-spec reconciliation (023 & 041) — verified, not assumed

- **Spec 023 (Smart Khatma)** *does* own the daily-habit loop: plan presets, today's
  target, **calm non-punitive catch-up** (the "رحيم/no-guilt" insight), continue-reading,
  and a full analytics plan (`khatma_continue_reading`, `khatma_goal_completed`, …).
  → K01/K57 correctly map here. **Gap in 023**: no explicit *adherence-days / gentle
  streak* concept (K51) and no *continue-**listening*** (audio) progress (K35). Recommend
  amending Spec 023, not 043.
- **Spec 041 (Widget Suite)** owns Prayer (shipped), Ayah-of-day (shipped), Athkar
  (shipped), Hijri (pending), Share cards (pending). **It has NO Khatma/Wird-progress
  widget.** Reviews **K48 (upvoted) and K51** explicitly demand exactly that
  ("widgets concerning… Khatmas (daily readings)… a must"). This need is **owned by
  neither 023, 041, nor 043** → the **strongest currently unowned retention opportunity
  observed in this review sample** (an extremes-only screenshot set that cannot estimate
  total market demand). Recommendation: add a "Wird Progress" widget to **Spec 041**, fed by
  Spec 023's `KhatmaTodayTarget`. **Spec 043 does not own it** but its roadmap must name it.
- **Spec 043 dependency on 041**: 041 FR-003 requires prayer times from the same pipeline
  043 hardens; 041's prayer widget is already shipped and depends on 043's reliability +
  location work being correct. This is a real dependency, not duplication.

## 8. Deliberate deferrals & rejections
- **Rejected outright** (positioning: *calm, trustworthy, modern, accessible, ad-free*):
  ad-supported tier, repeated post-purchase support popups, guilt-based streaks,
  leaderboards / competitive worship, overloaded home grid, excessive notification pressure.
- **Deferred**: Warsh/Qaloon riwayat (P2, tie to market entry + approved source); Tafsir
  (future spec); adhan voice library (post-reliability); adhkar content expansion (sourced only).
- **Rejected engineering approach** (from architecture review, retained): full runtime
  hashing of all assets on every cold start (regresses startup; use build-time + post-update
  + post-download-font verification instead).
