# Quran Sessions — Admin Config Seed & Validation

**Last updated:** 2026-07-03  
**Until Admin Panel UI ships**, use scripts + manual verification below.

---

## 1. Seed scripts

Run from `functions/` with `GOOGLE_APPLICATION_CREDENTIALS` or `gcloud auth application-default login`.

| Doc | Script | Dry run | Apply |
|-----|--------|---------|-------|
| `quran_session_platform_config/global` | `scripts/seedPlatformConfig.ts` | `npm run seed:platform-config -- --mode <mode>` | `npm run seed:platform-config:apply -- --mode <mode>` |
| `quran_session_market_configs/{country}` | `scripts/seedMarketConfigs.ts` | `npm run seed:market-configs` | `npm run seed:market-configs:apply` |

`seedPlatformConfig.ts` **requires** `--mode closed-testing | video-qa` and
refuses to run without it, so a QA configuration can never be re-seeded by
mistake. See [§ Closed-testing gate](#closed-testing-gate--required-platform-config)
for which mode applies when.

Market seed data source: `docs/seed/quran_session_market_configs.json`

---

## 2. Required fields (fail closed)

### Platform — `quran_session_platform_config/global`

| Field | Required | Notes |
|-------|----------|-------|
| `quranTutorBookingMode` | yes | `autoConfirm` \| `requiresTutorApproval` |
| `sessionMode` | yes | `videoOnly` \| `freeBeta` |
| `childAgeThreshold` | yes | positive number |
| `enabledCallProviders` | recommended | RTC rollout |

**Deprecated (ignored):** `requireGuardianApprovalForChildren`

### Market — `quran_session_market_configs/{countryCode}`

| Field | Required | Notes |
|-------|----------|-------|
| `isEnabled` | yes | market rollout |
| `minSessionPrice` | yes | authoritative fee floor |
| `currencyCode` | yes | non-empty |
| `cities[]` with matching `cityId` | yes | city enable + optional price override |

Validation: `functions/src/quranSessions/sessionPolicyResolver.ts`  
Enforced at booking: `loadBookingEligibilityContext` → `assertBookingPolicyConfigured`.  
Error code: `policy_not_configured`.

---

## Closed-testing gate — required platform config

> Part of the official
> [closed-testing rollout runbook](closed-testing-rollout-runbook.md) — see it
> for the full sequence and promotion policy.

`quran_session_platform_config/global` in `quran-playera-app` **must hold these
exact values before inviting Learn Quran closed testers** (Play builds exclude
the native Agora/LiveKit SDKs, so the config must not expose RTC providers the
client cannot join; `videoOnly` would also reject external-meeting bookings
server-side):

| Field | Required value for closed testing |
|-------|-----------------------------------|
| `enabledCallProviders` | `["external", "mock"]` |
| `sessionMode` | `"freeBeta"` |
| `quranTutorBookingMode` | `"requiresTutorApproval"` |

Apply with:

```sh
cd functions
npm run seed:platform-config -- --mode closed-testing          # dry run
npm run seed:platform-config:apply -- --mode closed-testing    # write
```

⚠️ **Sequencing:** the doc currently holds the MeMuslim staging **video-qa**
values (`["mock","agora"]` + `videoOnly`, verified 2026-07-04) because staging
shares this Firebase project. Flip to `closed-testing` only **after the Agora
staging QA round is finished** — the flip breaks in-app Agora video joins for
staging QA builds. To restore the QA setup later, re-seed with
`--mode video-qa`.

Verify after applying (read-only):

```sh
cd functions && NODE_PATH=./node_modules node -e '
const a=require("firebase-admin");a.initializeApp({projectId:"quran-playera-app"});
a.firestore().doc("quran_session_platform_config/global").get()
 .then(s=>console.log(JSON.stringify(s.data(),null,2)));'
```

---

## 3. Manual rollout (staging → production)

1. Staging: platform seed dry run → apply; market seed for pilot countries → apply.
2. Verify test booking succeeds; omit a required field and confirm `policy_not_configured`.
3. Production: repeat seeds; verify docs in console.
4. Enable teacher whitelist per market if soft-launching.

---

## 4. Tests

```sh
cd functions && npm test -- test/quranSessions/sessionPolicyResolver.test.ts
cd functions && npm run test:integration
```

Integration helper: `functions/test-integration/support/emulator.ts` → `seedDefaultBookingPolicy()`.

---

## 5. Launch gate execution log (2026-07-03)

| Step | Result |
|------|--------|
| `npm run seed:platform-config` | Dry-run OK — payload in §2 of `production-readiness-checklist.md` |
| `npm run seed:market-configs` | Dry-run OK — 3 countries, 19 cities |
| `npm run seed:*:apply` | **Not run** — requires explicit ops approval per environment |
| Policy validation tests | `npm test` includes `sessionPolicyResolver.test.ts` — pass |

**Target project for apply scripts:** `quran-playera-app` (from `FIREBASE_PROJECT_ID`).

**Credentials:** `gcloud` application-default login available locally; `GOOGLE_APPLICATION_CREDENTIALS` unset.
