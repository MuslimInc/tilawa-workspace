# Research Coverage Report — Spec 043

Generated from raw rows of `docs/khatmah_reviews_deep_analysis_for_memuslim.xlsx`
(sheet `المراجعات`), independently recounted on 2026-07-12. See `research.md` for the
narrative and traceability; this file is the quantitative ledger.

## 1. Corpus
- **Total raw reviews analyzed**: 59 (1 header + 59 data rows; xlsx `المراجعات` = 60 non-empty rows).
- **Date range**: 2024-12-20 → 2026-07-06 (K36 has no visible date).
- **Source**: hand-transcribed from 19 Google Play screenshots (`S01–S19`), sheet `المصادر`.
- **Sampling**: **extremes-only** — 5★ and 1★ only, no 2–4★. Not representative of Khatmah's
  true rating distribution (public avg 4.9★). Use for *pattern* discovery, not satisfaction %.

## 2. Distributions (recounted)
| Dimension | Values |
|---|---|
| Stars | 5★ = 19 · 1★ = 40 · (2–4★ = 0) |
| Language | Arabic = 38 · English = 20 · Arabic/English = 1 |
| Sentiment (text) | Positive = 19 · Negative = 28 · Negative/request = 5 · Mixed/request = 6 · Mixed/negative = 1 |
| Text-star agreement | Aligned = 52 · Partly = 1 · **Positive-text-at-1★ = 5** · Partly-misaligned = 1 |
| Text completeness | Complete/near-complete = 58 · Partial = 1 (K07) |
| Data gaps | Missing date = 1 (K36) · Anonymous reviewer = 3 (K30,K33,K45) |

**Adjusted negative signal**: 40 one-star − 5 positive-text − 1 mixed ≈ **34–35 genuinely
negative** 1★ reviews.

## 3. Theme counts (main theme, raw)
| Theme | N | %of59 |
|---|---|---|
| تقييم عام (general — excluded from prioritization) | 11 | 18.6% |
| الأذان ومواقيت الصلاة (Adhan) | 10 | 16.9% |
| سلامة نص القرآن والبيانات الدينية (integrity, **conflated**) | 7 | 11.9% |
| التصميم وتجربة الاستخدام (UI/UX) | 4 | 6.8% |
| الإعلانات/الدعم/الدفع (monetization) | 4 | 6.8% |
| القيمة الشاملة (all-in-one) | 3 | 5.1% |
| تكافؤ Android/iOS (parity) | 3 | 5.1% |
| القراءات والروايات (riwayat) | 3 | 5.1% |
| الختمة والورد اليومي (khatma/wird) | 2 | 3.4% |
| الويدجت والتتبع (widgets) | 2 | 3.4% |
| Each of: elderly, location, tafsir, adhan-custom, daily-value, product-freshness, stability, audio, regression, athkar | 1 each | 1.7% each |

## 4. Weighted priority scores
Formula: `Score = 1.0·FreqN + 3.0·Trust + 2.0·Blocking + 1.0·Recency + 1.5·Applicability − 1.0·Cost`,
`FreqN = min(3, count/59×10)`. Attributes (0–3) grounded in review evidence.

| Theme | N | Trust | Block | Rec | Applic | Cost | **Score** | Priority |
|---|---|---|---|---|---|---|---|---|
| Adhan reliability | 10 | 3 | 3 | 3 | 3 | 3 | **21.2** | P0 |
| Quran/content integrity (agg) | 7 | 3 | 2 | 3 | 3 | 2 | **19.7** | P0 |
| Adhkar/Dua correctness | 1 | 3 | 1 | 2 | 3 | 2 | **15.7** | P0 (governance) |
| Ads/paywall clarity | 4 | 2 | 1 | 3 | 3 | 1 | **15.2** | P1 |
| Location dead-end | 1 | 1 | 3 | 2 | 3 | 1 | **14.7** | P0 |
| Elderly/simplicity | 1 | 0 | 2 | 3 | 3 | 1 | **10.7** | P1 |
| Android/iOS parity | 3 | 1 | 2 | 2 | 2 | 2 | **10.5** | P1 |
| Khatma/Wird loop | 2 | 0 | 2 | 3 | 3 | 2 | **9.8** | P1 → Spec 023 |
| Riwayat | 3 | 1 | 1 | 3 | 2 | 3 | **8.5** | P2 |
| UI/UX modernization | 4 | 0 | 1 | 3 | 3 | 2 | **8.2** | P1 |
| Regression control | 1 | 0 | 2 | 2 | 2 | 1 | **8.2** | P1 (process) |
| Audio/recitation | 1 | 0 | 2 | 2 | 2 | 1 | **8.2** | P1/future |
| Stability/crashes | 1 | 0 | 2 | 2 | 2 | 1 | **8.2** | P1 |
| Khatma-progress widget | 2 | 0 | 1 | 3 | 3 | 2 | **7.8** | P1 → Spec 041 (gap) |
| All-in-one (positive) | 3 | 0 | 0 | 3 | 2 | 0 | **6.5** | strategy |
| Tafsir | 1 | 0 | 1 | 2 | 2 | 2 | **5.2** | P2/future |
| Adhan voice choice | 1 | 0 | 0 | 1 | 2 | 1 | **3.2** | P2 |
| Product freshness | 1 | 0 | 0 | 2 | 1 | 1 | **2.7** | P2 |

## 5. Coverage accounting (two separate ledgers — do NOT combine)

> **The previous version summed overlapping counts and exceeded the theme total. Fixed:**
> Table A below is **exclusive** — every theme has exactly **one** primary disposition and the
> totals reconcile to the theme count. Table B is **overlapping** — secondary relationships a
> theme may *also* have; **its counts must never be summed** with Table A. Source of truth for
> both: `theme-ledger.csv` (primary) and `review-ledger.csv` (per-review), checked by
> `scripts/validate_speckit_043.dart`.

### Table A — Exclusive final disposition by theme (reconciles exactly)
| Primary disposition | Themes | Count |
|---|---|---|
| **Spec 043** | adhan-reliability, integrity-text, integrity-number, integrity-boundary, athkar-content, location-fallback, parity, stability-report | **8** |
| **Spec 023** | khatma-wird-loop, continue-listening, gentle-adherence | **3** |
| **Spec 041** | widget-progress | **1** |
| **Future spec** | riwayat, tafsir, audio-recitation | **3** |
| **Deferred** | ui-ux-modernization, accessibility-elderly, adhan-voice, product-freshness | **4** |
| **Competitor-specific** | monetization-ads | **1** |
| **Non-actionable** | general-praise | **1** |
| **Rejected** | *(no standalone theme; rejected behaviors captured as non-copy in spec.md §8)* | **0** |
| **TOTAL** | | **21** |

Reconciliation: 8 + 3 + 1 + 3 + 4 + 1 + 1 + 0 = **21 themes** ✅ (matches `theme-ledger.csv`).

### Table B — Secondary relationships (overlapping; NOT summed)
| Theme | Secondary relationship(s) |
|---|---|
| widget-progress (041) | **depends_on** Spec 023 summary contract; **supporting_evidence** K48,K51 |
| integrity-boundary (043) | **cross_spec_ux**: Spec 023 plan consumes the boundary data |
| adhan-reliability (043) | **preventive_control** (no confirmed MeMuslim defect) |
| integrity-text/number (043) | **preventive_control** |
| athkar-content (043) | **preventive_control** (governance, GOV-003) |
| continue-listening (023) | **already_partially_implemented**: Home resume + history exist |
| gentle-adherence (023) | **already_partially_implemented**: `quranEngagementStreakDays` (listening streak) exists |
| khatma-wird-loop (023) | **already_implemented (MVP)**: plan/today-target/catch-up shipped |
| monetization-ads (COMP) | **non_copy_positioning** (spec.md §8) |
| parity (043) | **future_enhancement**: tafsir/audio parity tracked in future specs |

### Per-review coverage (from `review-ledger.csv`, exclusive status)
| Status | Count |
|---|---|
| mapped_043 | 23 |
| mapped_023 | 3 |
| mapped_041 | 2 |
| competitor_specific | 4 |
| deferred | 8 |
| future_spec | 5 |
| non_actionable | 13 |
| extraction_uncertain | 1 |
| **TOTAL** | **59** |

Reconciliation: 23+3+2+4+8+5+13+1 = **59** ✅. Confirmed-MeMuslim-defects (DEF): **0**.

## 8. Unresolved extraction uncertainties
1. K36 date unknown → recency for that adhan row inferred from cluster.
2. K30, K33, K45 reviewers anonymous (partial screenshots) → text used, identity not.
3. K07 text truncated → excluded from feature-level claims.
4. Positive-text-at-1★ (K09,K20,K23,K41,K47 + mixed K24) → sentiment taken from text.
5. Vague integrity/stability claims (K22,K28,K34) cannot be verified → ASSUM only.

## 9. Coverage statement
**Covered with documented exclusions.** All 17 non-general themes are mapped, deferred,
rejected, or routed to an owning spec; `تقييم عام` (11 rows) is intentionally excluded as
non-actionable satisfaction signal; 5 extraction uncertainties remain and are logged.
No meaningful review remains unmapped. **Not** claimed as "fully covered" because the
sample is extremes-only and cannot estimate true market demand.
