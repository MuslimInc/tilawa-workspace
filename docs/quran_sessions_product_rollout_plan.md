# Quran Sessions — Product Rollout Plan (Option D)

## Phase 0 — Ship UX + flags (now)

- Option D UI: Profile teaching section, Learn Quran empty state (`TilawaIllustratedState`), remove inverted become-teacher card.
- Feature flags wired; **defaults:** apply off, booking off.
- Analytics events for apply funnel + empty state.
- Documentation: ADR-004, write model, admin checklist.

**Exit:** `dart analyze` clean; widget/unit tests for flags + empty state.

---

## Phase 1 — MVO ops (beta)

- Deploy Firestore rules + `reviewTeacherApplication` CF.
- Train operator on list/approve scripts.
- Seed 5–15 curated teachers in launch markets (parallel to open apply).
- Enable `TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED=true`.
- Enable `TILAWA_LAUNCH_TEACHER_APPLICATION_DISCOVERABILITY=profileAndEmptyState`.

**Exit:** Median review time within SLA; pending queue stable.

---

## Phase 2 — Marketplace activation

- Approved supply in target cities.
- Enable `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true`.
- Student marketing with honest catalog density.

---

## Phase 3 — Scale

- OTP verification (ADR-003 deferred).
- In-app admin review UI (optional).
- External teacher landing / SEO.

---

## Flag defaults (production suggestion)

| Flag | Default |
|------|---------|
| `QURAN_SESSIONS_ENABLED` | true |
| `TEACHER_APPLICATION_ENABLED` | false until Phase 1 |
| `TEACHER_APPLICATION_DISCOVERABILITY` | profileAndEmptyState when apply on |
| `QURAN_SESSIONS_BOOKING_ENABLED` | false until Phase 2 |
