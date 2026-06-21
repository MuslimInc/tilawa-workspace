# Quran Sessions — Market Config Architecture & Product Rationale

> **Status:** Accepted (MVP)  
> **Audience:** Engineering, product, ops  
> **Scope:** Country/city catalog, pricing bounds, and enabled-market policy for Quran Sessions  
> **Related:** [market config sources](quran_sessions_market_config_sources.md) · [Firestore data model](quran_sessions_firestore_data_model.md) · [query optimization](firestore_query_optimization.md) · [backend migration](quran_sessions_backend_migration.md) · [roadmap §10](quran_sessions_roadmap.md#10-pricing--market-configuration) · [ADR-002](adr/002-quran-sessions-backend-agnostic-architecture.md)

---

## Executive summary

Quran Sessions treats **market configuration** (countries, cities, currency, timezone, pricing bounds, commission) as **backend-owned product policy**, not as a geodata lookup problem. The Flutter app reads a curated, **enabled-markets-only** catalog from Firestore (`quran_session_market_configs/{countryCode}/cities/{cityId}`). External geo APIs are excluded from the **runtime** path; they may feed **offline seed/import** jobs only.

**Recommendation:** Keep Firestore as the runtime source of truth with `isEnabled` gating. Expand markets by admin seeding (curated cities + Tilawa-specific fields), optionally hybridizing country metadata from REST Countries at import time. Defer third-party city APIs to a future **admin-side datasource** if bulk import is needed — never to Profile Completion pickers on device.

MVP ships **EG / SA / AE** (22 documents: 3 countries + 19 cities). This matches teacher supply, payment validation order (Egypt/EGP first per [roadmap](quran_sessions_roadmap.md)), and eligibility rules that require explicit user-selected location — not device locale or GPS.

---

## 1. Why not external geo APIs at runtime?

Third-party geo services solve **reference data** problems. Quran Sessions needs **operational market policy**: which countries we legally/commercially serve, which cities have teacher density, Arabic display names, per-market price floors/ceilings, commission, age overrides, and phone-prefix alignment for teacher applications.

Calling REST Countries, GeoNames, GeoDB Cities, or Google Places from the mobile app at profile-completion or booking time introduces failures and mismatches that do not map to product requirements.

### REST Countries

| Aspect | Assessment |
|--------|------------|
| **Provides** | ISO codes, names, flags, currencies, calling codes, timezones (country-level) |
| **Missing** | Cities, Tilawa pricing fields, `isEnabled`, Arabic curation, teacher-market linkage |
| **Runtime risk** | Extra network hop on cold start / profile gate; no SLA in client contract; stale vs Firestore policy |
| **When OK** | **Seeding only** — enrich country documents before merge-write to Firestore |

### GeoNames

| Aspect | Assessment |
|--------|------------|
| **Provides** | Large city lists, admin divisions, population |
| **Missing** | Product policy fields; quality Arabic labels; curation for Quran-teaching markets |
| **Runtime risk** | ~1k credits/day on free tier; attribution; noisy results (thousands of settlements per country); search UX unlike a 10–20 city curated list |
| **When OK** | **Admin import** — suggest city candidates for human review; never auto-enable all results |

### GeoDB Cities (RapidAPI)

| Aspect | Assessment |
|--------|------------|
| **Provides** | Filterable city search API |
| **Missing** | Same policy gap as GeoNames; licensing tied to RapidAPI plan |
| **Runtime risk** | Third-party uptime and quota become profile-completion blockers; API keys in client are unacceptable |
| **When OK** | **Server-side tooling** behind `MarketConfigRemoteDataSource` admin implementation if internal ops need search |

### Google Places / Geocoding

| Aspect | Assessment |
|--------|------------|
| **Provides** | Autocomplete addresses, POIs, geocoding |
| **Missing** | Stable `cityId` slugs for Firestore subcollections and teacher `pricing/{marketId}` keys |
| **Runtime risk** | Cost per session; ToS restrictions; users pick addresses not **markets**; conflicts with [location rule](quran_sessions_roadmap.md#33-profile-fields) (explicit market selection, no GPS/locale trust) |
| **When OK** | **Not recommended** for market config. Possible future use: optional address for in-person offerings (post-MVP, different feature) |

### Cross-cutting runtime objections

1. **Profile gate reliability** — Country/city pickers run on first Quran Sessions entry. External API failure becomes `MarketCatalogEmptyFailure`-class UX or empty dropdowns; Firestore read is one indexed query with predictable rules ([security draft](security/quran_sessions_firestore_rules_draft.md)).
2. **Policy coupling** — `ValidateBookingEligibilityUseCase` checks `MarketConfig.isEnabled`, `CityConfig.isEnabled`, and `resolveTeacherPrice(countryCode, cityId)`. External catalogs know nothing about teacher pricing subdocs or commission.
3. **Arabic-first product** — MVP cities use curated `cityName` / `cityNameAr` (see [`DefaultMarketCatalog`](../packages/quran_sessions/lib/src/data/seed/default_market_catalog.dart)). Geo APIs return inconsistent Arabic transliterations.
4. **Backend-agnostic boundary** — [ADR-002](adr/002-quran-sessions-backend-agnostic-architecture.md) keeps Firebase out of domain/BLoC. Runtime geo APIs would leak HTTP concerns into presentation or require ad-hoc caching in the app layer.
5. **Security** — Client-side API keys for GeoDB/Places are extractable. Server-side proxy adds infra without MVP benefit.

### When external APIs *are* appropriate

| Phase | Allowed use |
|-------|-------------|
| **One-off / periodic seed** | REST Countries → country metadata fields; GeoNames → candidate city list for manual curation |
| **Admin tooling (future)** | Cloud Function or script using Admin SDK + geo API to draft documents; human sets `isEnabled`, pricing, `sortOrder` |
| **Tests / fake backend** | In-memory [`CatalogMarketConfigRemoteDataSource`](../packages/quran_sessions/lib/src/data/datasources/catalog_market_config_remote_data_source.dart) — no network |

See operational detail in [quran_sessions_market_config_sources.md](quran_sessions_market_config_sources.md).

---

## 2. Why not a full global import to Firestore?

Importing all ~195 countries and tens of thousands of cities into `quran_session_market_configs` is technically feasible but **product-incorrect** for Tilawa's marketplace model.

### Product mismatch

- **Teacher matching** — Eligibility step 4b requires paid teachers to have pricing in the student's market (`TeacherNotInMarketFailure` if missing). Listing every country implies students can register where we have **zero verified teachers** and no payment rail.
- **Payments deferred, market-sequenced** — [Roadmap](quran_sessions_roadmap.md#11-payments): Egypt/EGP validated end-to-end first; multi-currency settlement deferred. A global country list advertises availability we cannot fulfill.
- **Explicit location rule** — Students must **choose** country/city; we do not infer from Google account country or device locale. A 195-country dropdown increases error rate (wrong country selection) without increasing addressable demand on day one.
- **Operational markets ≠ ISO registry** — A "market" bundles currency, timezone default, min/max session price, platform commission, and phone validation context. Most ISO countries would be `isEnabled: false` anyway — paying storage and index cost for dormant rows.

### Firestore and ops mismatch

Rough scale if naively imported:

| Entity | Order of magnitude | MVP (EG/SA/AE) |
|--------|-------------------|----------------|
| Country docs | ~195 | 3 |
| City docs | 10⁴–10⁵+ (GeoNames-class) | 19 |
| Composite indexes | Same 2 indexes regardless of row count | 2 |
| Seed/maintenance | Full re-import or diff tooling | Single JSON + idempotent Admin script |

Problems at global scale:

- **Storage** — Firestore charges per document; 50k+ city docs are cheap in isolation but costly in **operational noise** (backup, audit, accidental enablement).
- **Subcollection reads** — App loads cities **per selected country** (`getCitiesByCountryCode`), not full scan. Global import does not help runtime latency; it only bloats admin surfaces.
- **Index fan-out** — Listing enabled countries remains `where(isEnabled==true).orderBy(sortOrder)` — scanning index entries grows with **enabled** rows, not total imported rows, *if* most stay disabled. Still, importers must guarantee `isEnabled: false` default — one script bug enables Libya with zero teachers.
- **Maintenance** — Geo datasets change (admin renames, spellings). Without a sync pipeline, imported data rots; with sync, Tilawa-specific fields (`minSessionPrice`, Arabic names) need merge logic.
- **Security rules** — Rules expose read access to enabled docs. More documents increase risk of misconfigured `isEnabled` or direct doc-ID guessing ([rules draft](security/quran_sessions_firestore_rules_draft.md)).

**Conclusion:** Global import optimizes for a problem we do not have (exhaustive city search worldwide) and creates problems we cannot staff yet (ops, payments, teacher supply per market).

---

## 3. Approach comparison

| Dimension | **Firestore-managed enabled markets** (chosen) | **External API at runtime** | **Full global Firestore import** | **Limited enabled markets only** (subcase of Firestore-managed) |
|-----------|--------------------------------------------------|------------------------------|-----------------------------------|----------------------------------------------------------------|
| **Runtime reliability** | High — single backend, offline cache possible | Low — quota, latency, third-party outages | High read path, fragile ops | Highest — minimal doc set |
| **Product control** | Full — pricing, commission, enablement | None — reference data only | Illusory — most rows unusable without teachers/payments | Full — launch only where ready |
| **Arabic UX** | Curated labels | Inconsistent | Mixed unless manually curated | Curated for launch markets |
| **Teacher/pricing alignment** | Same store as `pricing/{marketId}` semantics | Disconnected | Same as Firestore if curated per city | Strong — only listed markets bookable |
| **Client complexity** | Repository + indexed queries | HTTP clients, caching, key mgmt | Same as Firestore-managed | Lowest |
| **Firestore cost (reads)** | O(enabled countries) + O(cities in selected country) per session | API cost + optional Firestore | Same query shape; higher storage | Minimal (MVP: 22 docs) |
| **Firestore cost (storage/index)** | Low — tens to hundreds of docs | N/A in Firestore | High doc count; same 2 composite indexes | Minimal |
| **Expansion cost** | Seed script + enable flag + teacher/pricing setup | New API integration per vendor | Heavy merge/sync tooling | Incremental per market |
| **Compliance / attribution** | None | GeoNames attribution, API ToS | Depends on import source | None |
| **MVP fit** | ✅ | ❌ | ❌ | ✅ |

**Note:** "Limited enabled markets only" is not a separate architecture — it is the **policy** applied to the Firestore-managed model via `isEnabled` and curated seed data.

---

## 4. Product strategy: global launch vs enabled markets

### What "market" means in Tilawa

A market is the tuple **(countryCode, cityId)** driving:

- Student profile fields (`countryCode`, `cityId`, `currencyCode`, `timezone`) — [roadmap §3.3](quran_sessions_roadmap.md#33-profile-fields)
- Display currency via `SessionPrice` / `PriceFormatter` (no exchange-rate conversion in MVP)
- Booking eligibility (`MarketNotEnabledFailure`, `TeacherNotInMarketFailure`)
- Teacher list pricing resolution (`resolveTeacherPrice(teacherId, countryCode, cityId)`)
- Future payment settlement and commission (`minSessionPrice`, `maxSessionPrice`, `platformCommissionPercent` on country doc)

Country and city are **first-class product choices**, not geographic discovery.

### Global launch vs phased enablement

| Strategy | Description | Fit for Quran Sessions |
|----------|-------------|------------------------|
| **Global launch** | All ISO countries visible; operations catch up later | Poor — breaks eligibility narrative; students book markets with no teachers or payments |
| **Enabled markets only** | Only `isEnabled: true` countries/cities appear in pickers | ✅ Matches MVP and safety model |

### Inferred rollout (from MVP scope and roadmap)

1. **MVP (now)** — **EG, SA, AE** seeded ([`DefaultMarketCatalog`](../packages/quran_sessions/lib/src/data/seed/default_market_catalog.dart), [seed JSON](seed/quran_session_market_configs.json)): 19 cities weighted toward population centers and Gulf teaching demand. Payments roadmap emphasizes **Egypt/EGP first**; SA/AE prepare GCC expansion with SAR/AED pricing bounds.
2. **Market entry checklist (per new country)** — Enable country doc → curate cities (not bulk import) → seed verified teachers → set `quran_teacher_profiles/{id}/pricing/{marketId}` → validate phone rules in `PhoneNormalizer` → payment provider support for currency → flip `isEnabled`.
3. **City expansion within market** — Add subcollection doc, `sortOrder`, Arabic/English names; no app release if Firestore-driven.
4. **Post-MVP** — Jordan, Kuwait, etc. align with existing phone-validation countries in teacher application flow; each still requires ops checklist, not automatic GeoNames enablement.
5. **Not on critical path** — Exchange-rate display, multi-currency settlement, GPS/locale suggestions (optional hint only, never auto-persist).

Teacher matching implication: **student city filters marketplace pricing**, not teacher GPS. Teachers without pricing for `(EG, cairo)` do not appear as bookable paid options for that student even if physically in Cairo.

---

## 5. Firestore implications

### Document topology (recap)

```
quran_session_market_configs/{countryCode}          # e.g. EG
  └── cities/{cityId}                               # e.g. cairo
```

Direct `doc(countryCode).get()` for O(1) country config; cities loaded scoped to country — **no collectionGroup city scan**. See [data model](quran_sessions_firestore_data_model.md) and [sources doc](quran_sessions_market_config_sources.md).

### Query patterns and MVP value

| Operation | Query | MVP read cost |
|-----------|-------|---------------|
| Profile completion — countries | `where(isEnabled==true).orderBy(sortOrder)` | ≤3 docs |
| Profile completion — cities | Subcollection filter + order | ≤10 docs per country (EG max) |
| Booking eligibility | `getMarketConfig(countryCode)` + city doc | 1–2 docs |
| List all markets (admin/home) | Same as countries + optional full market fetch | Rare; cache-friendly |

Indexes (deploy via [`firestore.indexes.json`](../firestore.indexes.json)):

1. `quran_session_market_configs`: `isEnabled` + `sortOrder`
2. `cities` collection group fields: `isEnabled` + `sortOrder` on subcollection

Documented in [firestore_query_optimization.md](firestore_query_optimization.md). At MVP scale, market config queries should **not** appear in Query Insights top offenders.

### Worldwide import — hypothetical load

If all countries were imported but only ~10 enabled:

- **Storage** — Paying for ~195 + thousands of disabled city docs with no UX benefit.
- **Indexes** — Enabled-country query only indexes matching entries; disabled rows still consume storage and complicate seed scripts.
- **Maintenance** — Every geo API update requires idempotent merge into Tilawa fields; risk of overwriting `minSessionPrice` or Arabic names.
- **Security** — Larger surface for accidental public reads if rule bugs expose disabled markets by ID enumeration.

### MVP value of current design

- **22 documents** — Trivial to seed, diff in code review, and snapshot in [seed JSON](seed/quran_session_market_configs.json).
- **Idempotent Admin SDK seed** — `npm run seed:market-configs:apply` ([sources doc](quran_sessions_market_config_sources.md)).
- **Client writes blocked** — Catalog changes are ops-controlled, not user-generated.
- **Empty catalog fails loudly** — `MarketCatalogEmptyFailure` rather than silent empty dropdown ([sources doc](quran_sessions_market_config_sources.md#verify-in-the-app)).

---

## 6. Clean Architecture — evolving to all countries without touching UI

Boundary stack ([ADR-002](adr/002-quran-sessions-backend-agnostic-architecture.md), [backend migration](quran_sessions_backend_migration.md)):

```
presentation (ProfileCompletionBloc, pickers)
    → GetMarketConfigUseCase
        → MarketConfigRepository (interface, domain)
            → MarketConfigRepositoryImpl (package/data)
                → MarketConfigRemoteDataSource (interface)
                    → FirestoreMarketConfigDataSource (app) | CatalogMarketConfigRemoteDataSource (fake)
```

### Stable domain contract

[`MarketConfigRepository`](../packages/quran_sessions/lib/src/domain/repositories/market_config_repository.dart) exposes:

- `getSupportedCountries()` — enabled countries, sorted
- `getCitiesByCountryCode(countryCode)` — enabled cities in one country
- `getMarketConfig(countryCode)` — pricing bounds + nested city configs
- `getSupportedMarkets()` / `getCityConfig(...)` — same semantics

Use cases and BLoCs depend on **entities** (`MarketCountry`, `MarketCity`, `MarketConfig`) — not on Firestore paths or ISO dataset versions.

### Swapping data sources

| Goal | Change surface |
|------|----------------|
| Add Firestore in production | Register `MarketConfigRepositoryImpl(FirestoreMarketConfigDataSource)` in `QuranSessionsFirebaseModule` |
| Fake / tests | `CatalogMarketConfigRemoteDataSource` → reads [`DefaultMarketCatalog`](../packages/quran_sessions/lib/src/data/seed/default_market_catalog.dart) |
| Replace Firestore with REST backend | New datasource implementing same interface; register in DI — **no BLoC edits** ([migration guide](quran_sessions_backend_migration.md)) |
| Add admin geo search (future) | New **server-side** import tool or Cloud Function; still writes Firestore documents consumed by existing datasource |

### Seed pipelines (expansion without app release)

1. **Curated** — Edit `DefaultMarketCatalog` + `docs/seed/quran_session_market_configs.json`; run Admin seed script.
2. **Hybrid country metadata** — Script fetches REST Countries → maps to DTO → merge-write with `isEnabled: false` default and Tilawa overrides.
3. **City candidates** — Script fetches GeoNames → outputs review CSV → human picks → seed enabled cities only.
4. **Third-party API datasource (later)** — Only if product requires dynamic city search in **admin UI**; implementation stays in `apps/tilawa/.../data/` or Functions, not in `ProfileCompletionScreen`.

Repository impl ([`MarketConfigRepositoryImpl`](../packages/quran_sessions/lib/src/data/repositories/market_config_repository_impl.dart)) already maps DTOs → domain and centralizes empty-catalog failure — unchanged when doc count scales from 22 to 22 000 **as long as** query contracts hold (enabled-only lists, country-scoped cities).

### What would force domain changes

Intentional product shifts only, e.g.:

- Pagination cursors for city lists (unlikely — curated lists stay small)
- Hierarchical regions (country → governorate → city) — new entity fields and repository methods
- Client-side city search across all markets — new use case; still not raw GeoNames in UI

None are MVP requirements.

---

## 7. Recommendation

### Decision

**Adopt Firestore-managed, enabled-markets-only catalog with curated cities as the runtime source of truth.** Keep external geo APIs **off the client**; allow **optional hybrid seed** from REST Countries (country metadata) and GeoNames (city **candidates** after human curation). Revisit a third-party API only as a **backend/admin datasource** if ops volume justifies automated drafting — never as the Profile Completion runtime path.

### Rationale (condensed)

1. **Product** — Markets gate teachers, pricing, currency, and future payments; geo APIs do not encode that policy.
2. **UX** — Short curated city lists in Arabic beat exhaustive global search for a worship-context onboarding flow.
3. **Reliability** — Profile gate and booking eligibility must not depend on RapidAPI quota or Places billing.
4. **Cost & ops** — 22-document MVP vs 10⁴+ doc global import; incremental enablement matches [roadmap](quran_sessions_roadmap.md) payment sequencing.
5. **Architecture** — Repository + datasource swap already implemented; expansion is **data + ops**, not feature rewrites.

### Implementation anchors (current)

| Artifact | Role |
|----------|------|
| [`DefaultMarketCatalog`](../packages/quran_sessions/lib/src/data/seed/default_market_catalog.dart) | Version-controlled curated seed |
| [`docs/seed/quran_session_market_configs.json`](seed/quran_session_market_configs.json) | Firestore import / Admin SDK payload |
| [`functions/scripts/seedMarketConfigs.ts`](../functions/scripts/seedMarketConfigs.ts) | Idempotent production seed |
| [`MarketConfigRemoteDataSource`](../packages/quran_sessions/lib/src/data/datasources/market_config_remote_data_source.dart) | Swappable backend contract |
| App Firestore datasource | [`firestore_market_config_repository.dart`](../apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_market_config_repository.dart) |

### Anti-patterns to reject

- Calling GeoNames/Places from Flutter for country/city pickers
- Importing all GeoNames cities into Firestore with `isEnabled: true`
- Hardcoding EG/SA/AE in presentation widgets (violates [roadmap currency/location rules](quran_sessions_roadmap.md#33-profile-fields))
- Storing market policy in client-side JSON assets for production (bypasses ops enablement)

### Next documentation / ops steps

- Link new markets to teacher seed + pricing subdocs before enablement
- When Query Insights is available, confirm market queries stay negligible vs teacher discovery ([firestore_query_optimization.md](firestore_query_optimization.md))
- If admin UI is built, prefer Firestore writes + existing read path over new client geo dependencies

---

## Document map

| Question | Primary doc |
|----------|-------------|
| Field layout, seed commands | [quran_sessions_market_config_sources.md](quran_sessions_market_config_sources.md) |
| Collection schemas | [quran_sessions_firestore_data_model.md](quran_sessions_firestore_data_model.md) |
| Indexes & monitoring | [firestore_query_optimization.md](firestore_query_optimization.md) |
| DI / fake vs Firebase | [quran_sessions_backend_migration.md](quran_sessions_backend_migration.md) |
| Feature status | [quran_sessions_roadmap.md](quran_sessions_roadmap.md) |
| Layer boundaries | [ADR-002](adr/002-quran-sessions-backend-agnostic-architecture.md) |
