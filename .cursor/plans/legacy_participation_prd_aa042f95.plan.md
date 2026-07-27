---
name: Legacy Participation PRD
overview: PRD approved. Engineering SPEC lives at specs/045-sadaqah-jariyah/spec.md — implement against that document.
todos:
  - id: scholar-legal-gate
    content: Scholar review of default title/intro; titles changeable via config without app release
    status: pending
  - id: write-spec
    content: Author specs/045-sadaqah-jariyah/spec.md from approved PRD
    status: completed
  - id: mvp-scope-lock
    content: "MVP: list + cards + WhatsApp + admin; config titles; Storage path; slug auto; no deathDate"
    status: completed
  - id: ux-copy-pass
    content: AR/EN defaults + sheet; app falls back to bundled defaults if config missing
    status: completed
  - id: firestore-admin
    content: dedications + app_config/sadaqah_jariyah; admin upload to Storage; slug unique
    status: completed
  - id: whatsapp-template
    content: Prefill WhatsApp template + intention line; phone from config
    status: completed
  - id: onboarding-removal
    content: Remove Abu Hudhaifa onboarding page 3; founding portrait via Storage or bundled asset
    status: completed
  - id: implement-sj-checklist
    content: Execute SJ-01…SJ-42 in specs/045-sadaqah-jariyah/spec.md §15
    status: completed
isProject: false
---

# MeMuslim — Sadaqah Jariyah

**PRD status:** FINAL / APPROVED (product frozen)  
**Engineering reference:** [`specs/045-sadaqah-jariyah/spec.md`](../../specs/045-sadaqah-jariyah/spec.md)

Do not redesign product here. Implement from the SPEC (architecture, domain, Firestore/Storage, admin, Flutter UI, tests, SJ-01…SJ-42 checklist).

Product decisions remain as captured in the prior PRD body in git history / conversation; SPEC §0 locks them for engineering.

## Implementation status (2026-07-27)

Engineering MVP shipped on `feat/sadaqah-jariyah`:

- Backend rules/indexes/storage + seed
- App domain/data/UI + Settings/Support entry + launch flag + deep-link redirect
- Admin CRUD/config/photo/private ops
- Unit + widget tests; analytics events
- Rules test file added (`functions/test-rules/sadaqahJariyah.rules.test.ts`) — local run needs JDK 21+

**Still human gates (not code):**

- **SJ-40** Manual acceptance vs PRD checklist
- **SJ-41** / `scholar-legal-gate` — scholar/copy sign-off before prod flag on
- Set live WhatsApp number in admin config (`whatsappE164` currently empty in seed)
