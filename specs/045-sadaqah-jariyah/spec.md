# Feature Specification: Sadaqah Jariyah (Engineering)

**Status:** Approved for implementation  
**Spec id:** `045-sadaqah-jariyah`  
**Product source of truth:** [`.cursor/plans/legacy_participation_prd_aa042f95.plan.md`](../../.cursor/plans/legacy_participation_prd_aa042f95.plan.md) (FINAL PRD)  
**Related:** [`016-support-tilawa`](../016-support-tilawa/spec.md), [`firestore.rules`](../../firestore.rules), [`storage.rules`](../../storage.rules)

**Scope freeze:** Do not redesign UX, flows, naming, or MVP surface. This document is the engineering translation of the PRD only.

**Feature name (locked):** Sadaqah Jariyah / صدقة جارية  
**Route path (locked):** `/sadaqah-jariyah`  
**Analytics prefix (locked):** `sadaqah_jariyah_*`

---

## 0. Locked product decisions (do not reopen)

| Decision | Value |
|----------|--------|
| Participation | WhatsApp only — no IAP in this feature |
| Publishing | Admin-only after manual verify |
| List | Public published dedications; founding always first |
| Photos | `photoStoragePath` (Storage); resolve URL client-side |
| Titles | Firestore config with l10n fallback |
| Slug | Required unique; not shown in MVP UI |
| deathDate | Out of MVP |
| Social / amounts / badges / leaderboards | Forbidden |

**Founding seed (locked):**

- `displayName`: Ahmed Mohamed Tony (Abu Hudhaifa) — AR display via note/l10n as needed  
- `slug`: `ahmed-mohamed-tony` (immutable after publish)  
- `isFounding`: `true`  
- `status`: `published`  
- Bundled fallback asset: `assets/images/ahmed.png` when `photoStoragePath` null or resolve fails

**Slug uniqueness (locked):** pointer collection `dedications_slugs/{slug}` → `{ dedicationId }` (admin transaction on create/rename).

---

## 1. Feature Architecture

### 1.1 Boundaries

| Surface | Package / app | Responsibility |
|---------|---------------|----------------|
| Mobile feature | `apps/tilawa/lib/features/sadaqah_jariyah/` | Read published list + config; WhatsApp CTA; UI |
| Support cross-link | `features/support/` | Soft footer link only — no payment coupling |
| Onboarding | `features/onboarding/` | **Remove** page 3 (Abu Hudhaifa); keep 2 pages |
| Admin | `apps/tilawa_admin` feature `sadaqah-jariyah/` | CRUD, publish, Storage upload, config edit |
| Backend | Firestore + Storage rules only | **No** Cloud Functions in MVP |
| DI | `get_it` + `injectable` | Register datasources/repos/use cases/cubit |

### 1.2 Layer responsibilities (Tilawa convention)

Match `features/support/` shape: **presentation / domain / data** (no separate `application/` folder).

```text
presentation/  → Cubit, screens, widgets, sheets (BuildContext OK)
domain/        → entities, enums, repository interfaces, use cases, failures
data/          → Firestore/Storage datasources, mappers, repository impls
```

**Dependency flow:**

```text
UI → Cubit → UseCases → Repository (interface)
                              ↑
                     RepositoryImpl → RemoteDataSource / StorageResolver
```

- No `BuildContext` below presentation.
- Cross-layer results: `Either<Failure, T>` (`dartz_plus`) — never throw across layers.
- Prefer **Cubit** (project default). Support’s `Bloc` is legacy for billing streams; this feature has no purchase stream.

### 1.3 Folder structure

```text
apps/tilawa/lib/features/sadaqah_jariyah/
  sadaqah_jariyah.dart
  domain/
    domain.dart
    entities/
      dedication.dart
      sadaqah_jariyah_config.dart
      sadaqah_jariyah_page_data.dart   // config + ordered dedications
    enums/
      dedication_relation.dart
      dedication_status.dart          // used by admin mapper shared constants; app only needs published
    failures/
      sadaqah_jariyah_failure.dart
    repositories/
      dedications_repository.dart
      sadaqah_jariyah_config_repository.dart
    services/
      dedication_photo_url_resolver.dart  // interface
    usecases/
      get_sadaqah_jariyah_page_use_case.dart
      build_whatsapp_participate_uri_use_case.dart
      sort_dedications_for_display_use_case.dart  // pure; testable banding
  data/
    data.dart
    datasources/
      dedications_remote_data_source.dart
      sadaqah_jariyah_config_remote_data_source.dart
      dedication_photo_storage_data_source.dart
    mappers/
      dedication_mapper.dart
      sadaqah_jariyah_config_mapper.dart
    repositories/
      dedications_repository_impl.dart
      sadaqah_jariyah_config_repository_impl.dart
    services/
      firebase_dedication_photo_url_resolver.dart
  presentation/
    presentation.dart
    cubit/
      sadaqah_jariyah_cubit.dart
      sadaqah_jariyah_state.dart
    screens/
      sadaqah_jariyah_screen.dart
    widgets/
      sadaqah_jariyah_intro.dart
      sadaqah_jariyah_founding_card.dart
      sadaqah_jariyah_dedication_card.dart
      sadaqah_jariyah_letter_avatar.dart
      sadaqah_jariyah_list.dart
      sadaqah_jariyah_support_cta.dart
      sadaqah_jariyah_footer.dart
      sadaqah_jariyah_participate_sheet.dart
    l10n/
      dedication_relation_l10n.dart   // maps enum → context.l10n
```

**Admin (Angular):**

```text
apps/tilawa_admin/src/app/features/sadaqah-jariyah/
  sadaqah-jariyah.routes.ts
  list/
  edit/
  config/
  shared/
    dedications.paths.ts
    dedications.repository.ts
    slug.util.ts
    relation.options.ts
```

Paths centralize like `quran-sessions.paths.ts`.

---

## 2. Domain Model

### 2.1 `DedicationRelation` (enum)

```text
father, mother, brother, sister, husband, wife, son, daughter, friend, other
```

- Persist as lowercase string.
- Unknown wire value → treat as null on client (hide relation line); log debug.

### 2.2 `DedicationStatus` (enum)

```text
draft | published | archived
```

Client queries **published only**.

### 2.3 `Dedication` (entity)

| Field | Type | Validation |
|-------|------|------------|
| `id` | `String` | non-empty |
| `displayName` | `String` | trim; 1–80 chars |
| `slug` | `String` | `^[a-z0-9]+(?:-[a-z0-9]+)*$`; 1–80; unique |
| `relation` | `DedicationRelation?` | |
| `relationOther` | `String?` | required if relation==other; max 40; else null |
| `note` | `String?` | max 120; reject if contains `http://` or `https://` |
| `photoStoragePath` | `String?` | null or path under `photos/dedications/` |
| `isFounding` | `bool` | at most one true in DB |
| `isFeatured` | `bool` | default false |
| `sortOrder` | `int` | |
| `publishedAt` | `DateTime?` | set on first publish |
| `status` | `DedicationStatus` | |

**Invariants:**

- If `isFounding` → always band 0 regardless of `isFeatured` / `sortOrder`.
- Client never reads private ops.
- No amount fields on entity.

### 2.4 `SadaqahJariyahConfig` (entity)

| Field | Type | Default / fallback |
|-------|------|-------------------|
| `featureTitleAr` | `String` | `صدقة جارية` |
| `featureTitleEn` | `String` | `Sadaqah Jariyah` |
| `featureSubtitleAr` | `String` | l10n default or empty |
| `featureSubtitleEn` | `String` | l10n default or empty |
| `whatsappE164` | `String` | empty → CTA degraded |
| `messageTemplateAr` | `String` | bundled template |
| `messageTemplateEn` | `String` | bundled template |
| `featureEnabled` | `bool` | `true` if doc missing (fail-open to defaults) **unless** compile flag off |

**Resolved title helper:** `titleFor(Locale)` / `subtitleFor(Locale)` — empty string → bundled l10n default.

### 2.5 `SadaqahJariyahPageData` (aggregate)

```text
config: SadaqahJariyahConfig
dedications: List<Dedication>  // already display-sorted
```

### 2.6 Value objects / pure helpers

| Helper | Role |
|--------|------|
| `DedicationDisplayBand` | `founding` \| `featured` \| `standard` |
| `sortDedicationsForDisplay(List<Dedication>)` | founding → featured(sortOrder) → rest(sortOrder) |
| `DedicationSlug` | normalize + validate |
| `WhatsappParticipateRequest` | phone E164 + body text |

### 2.7 Failures

```text
SadaqahJariyahFailure
  - network / unavailable
  - parse
  - whatsappUnavailable  // no phone / launch failed
```

Map Firestore/Storage exceptions in data layer → Failure; never leak Firebase types to UI.

---

## 3. Repository Layer

### 3.1 `DedicationsRepository`

**Responsibilities:** fetch published dedications for the app.

```dart
abstract class DedicationsRepository {
  Future<Either<Failure, List<Dedication>>> getPublishedDedications();
}
```

- **Caching (MVP):** rely on Firestore SDK persistence; no custom disk cache required. Optional in-memory cache on repository for session (clear on Cubit refresh).
- **Error handling:** `Left(Failure)`; empty published list (only founder missing) is still `Right` if query succeeds — seed must ensure founding exists.
- **No** create/update/delete on mobile.

### 3.2 `SadaqahJariyahConfigRepository`

```dart
abstract class SadaqahJariyahConfigRepository {
  Future<Either<Failure, SadaqahJariyahConfig>> getConfig();
}
```

- Mirror forced-update pattern: missing doc → defaults entity (fail-open for titles).
- Empty title fields → defaults inside mapper.

### 3.3 `DedicationPhotoUrlResolver` (domain service)

```dart
abstract class DedicationPhotoUrlResolver {
  /// Returns HTTPS download URL or null if path null/resolve fails.
  Future<String?> resolveDownloadUrl(String? photoStoragePath);
}
```

- In-memory map path → url with TTL (e.g. 55 minutes) to avoid hammering `getDownloadURL`.
- Never write resolved URL back to Firestore.

### 3.4 Use cases

| Use case | Behavior |
|----------|----------|
| `GetSadaqahJariyahPageUseCase` | Parallel get config + dedications; sort; return `PageData` |
| `SortDedicationsForDisplayUseCase` | Pure sort (also unit-tested standalone) |
| `BuildWhatsappParticipateUriUseCase` | Pick template by locale; fill placeholders; build `https://wa.me/<digits>?text=` |

---

## 4. Firestore

### 4.1 Collections / documents

```text
dedications/{dedicationId}
  displayName, slug, relation, relationOther, note,
  photoStoragePath, status, isFounding, isFeatured, sortOrder,
  publishedAt, createdAt, updatedAt, createdByAdminId, updatedByAdminId

dedications/{dedicationId}/private/ops
  internalOpsNote, channelRef

dedications_slugs/{slug}
  dedicationId: string
  // create/update/delete in same admin transaction as dedication slug changes

app_config/sadaqah_jariyah
  featureTitleAr, featureTitleEn, featureSubtitleAr, featureSubtitleEn,
  whatsappE164, messageTemplateAr, messageTemplateEn, featureEnabled
```

### 4.2 Indexes

Composite for client query:

```text
Collection: dedications
  status ASC, sortOrder ASC
```

(Single-field indexes usually auto; confirm composite in Firebase console / `firestore.indexes.json`.)

Admin list filters may need:

```text
status ASC, updatedAt DESC
isFounding ASC
isFeatured ASC, sortOrder ASC
```

Add only what admin queries use.

### 4.3 Security rules (intent)

```text
match /app_config/sadaqah_jariyah {
  allow read: if true;
  allow write: if isAdmin();
}

match /dedications/{id} {
  allow read: if isAdmin()
    || (resource.data.status == 'published');
  allow create, update, delete: if isAdmin();

  match /private/{docId} {
    allow read, write: if isAdmin();
  }
}

match /dedications_slugs/{slug} {
  allow read: if isAdmin();   // client does not need slug lookup in MVP
  allow write: if isAdmin();
}
```

**Note:** Public `list` queries must only return published docs — rules `allow read` on published is sufficient for queries that filter `status == published`. Admins use admin SDK or admin auth with `isAdmin()`.

Ensure admin Angular uses account with custom claim `admin == true` (same as rest of panel).

### 4.4 Queries

**App:**

```text
dedications
  .where('status', '==', 'published')
  .orderBy('sortOrder')
```

Then client `sortDedicationsForDisplay`.

**Admin:** status filter + search client-side on page or `displayName` prefix as needed; keep simple for MVP.

### 4.5 Sorting strategy

1. Query by `sortOrder` for stable transport.  
2. **Mandatory** client band sort: founding → featured → standard.  
3. Within band: `sortOrder` ascending; tie-break `displayName` or `id`.

### 4.6 Offline behavior

- Firestore persistence enabled (app default): show last cached published snapshot when offline.
- If no cache: `TilawaErrorState` + retry.
- Config: same; titles fall back to l10n if config unread.
- Photos: if URL not cached / resolve fails → letter avatar (founding → asset).

---

## 5. Firebase Storage

### 5.1 Path convention

```text
photos/dedications/{dedicationId}.webp
```

Optional future: `photos/dedications/{dedicationId}_256.webp` — not MVP.

### 5.2 Upload flow (Admin only)

1. Admin selects image on edit form.  
2. Client-side resize/compress to WebP (or JPEG if WebP tooling costly — prefer WebP; max edge ~512px; max ~400KB).  
3. `put` to `photos/dedications/{id}.webp` with `contentType` + `cacheControl: public,max-age=31536000`.  
4. Set `photoStoragePath` on dedication doc (path only).  
5. Overwrite same path on replace (cache-bust at resolve time with `?v=updatedAt` query if needed — **in memory URL only**).

### 5.3 Download flow (App)

1. Read `photoStoragePath`.  
2. If null → avatar fallback.  
3. Else `FirebaseStorage.ref(path).getDownloadURL()` via resolver cache.  
4. `Image.network` / cached network image with errorBuilder → letter avatar.  
5. Founding + null/fail → `AssetImage('assets/images/ahmed.png')`.

### 5.4 Caching

- Resolver TTL cache for download URLs.  
- HTTP cache via Storage `cacheControl`.  
- Do not store download URLs in Firestore.

### 5.5 Storage rules

```text
match /photos/dedications/{fileName} {
  allow read: if true;  // public dedications photos
  allow write: if isAdmin()
    && request.resource.size < 400 * 1024
    && request.resource.contentType.matches('image/webp|image/jpeg');
  allow delete: if isAdmin();
}
```

(`isAdmin()` must be available in storage.rules — mirror Auth token claim pattern used elsewhere, or restrict write to Admin SDK only and have admin upload via a thin callable later. **MVP preference:** admin claim on Storage rules if already supported; else Admin SDK upload from Cloud Function. Prefer matching how other admin uploads work in this repo — if none, use admin Auth + Storage rules with `request.auth.token.admin == true`.)

---

## 6. Admin Panel

### 6.1 Screens

| Screen | Route (example) | Purpose |
|--------|-----------------|---------|
| List | `/sadaqah-jariyah` | Table: name, status, featured, founding, sortOrder, updated |
| Create / Edit | `/sadaqah-jariyah/:id` | Form + photo + private ops |
| Config | `/sadaqah-jariyah/config` | Titles, WhatsApp, templates, featureEnabled |

Nav label: **Sadaqah Jariyah**.

### 6.2 CRUD

| Op | Rules |
|----|--------|
| Create | status default `draft`; generate slug; block second `isFounding` |
| Update | validate fields; slug change updates pointer txn |
| Publish | status→`published`; set `publishedAt` if null; slug frozen after first publish (recommended) |
| Archive | status→`archived`; disappears from app |
| Delete | discouraged; prefer archive; hard delete only non-founding + confirm |

### 6.3 Validation (admin)

- `displayName` required  
- `slug` unique + pattern  
- `relationOther` if `other`  
- `note` length + no URLs  
- Cannot clear `isFounding` on seed; cannot create another founding  
- Photo optional  

### 6.4 Publishing flow

1. Ops verifies WhatsApp support offline.  
2. Create/edit dedication (draft).  
3. Upload photo optional.  
4. Set status Published.  
5. App shows on next fetch/refresh.

### 6.5 Featured ordering

- Toggle `isFeatured`.  
- Adjust `sortOrder` (number input or up/down).  
- App bands featured after founding; no badge UI.

### 6.6Slug generation

- On `displayName` blur: propose slug (transliterate Arabic → ASCII; lowercase; hyphenate; strip honorifics).  
- If empty ASCII → require manual slug.  
- Collision → show error; suggest `slug-2`.  
- Implement `slug.util.ts` + unit tests.

---

## 7. Flutter UI

### 7.1 Screen: `SadaqahJariyahScreen`

Use `TilawaShellChildScaffold` (settings stack child; ADR-009).

**Widget tree:**

```text
TilawaShellChildScaffold
  TilawaAppBar (resolved title)
  body: switch state
    loading → TilawaLoadingIndicator
    error → TilawaErrorState (retry → cubit.load)
    ready → CustomScrollView / Column
      SadaqahJariyahIntro (story + optional subtitle)
      SadaqahJariyahList
        SadaqahJariyahFoundingCard
        optional section label if featured non-empty
        SadaqahJariyahDedicationCard × N
      SadaqahJariyahFooter (disclaimer + soft Support link)
      bottom: SadaqahJariyahSupportCta
```

**Participate:** CTA opens `SadaqahJariyahParticipateSheet` (`TilawaBottomSheetScaffold`).

### 7.2 Cards

- **Founding:** larger; portrait; name; رحمه الله; origin one-liner; calm surface distinction — no gold pay CTA.  
- **Dedication:** avatar | name + رحمه الله | localized relation | note.  
- **Letter avatar:** first grapheme; calm container color from scheme.  
- **No** amounts, badges, rankings, share buttons.

### 7.3 States

| State | UI |
|-------|-----|
| Loading | Center loader (first load) |
| Error | Icon + message + retry |
| Empty others | Founder only + soft empty line |
| Offline cached | Show data; optional subtle offline is OK without banner spam |
| CTA disabled | `featureEnabled == false` or compile flag → hide route/tile; if open → empty/disabled |
| WhatsApp missing phone | Sheet explains; copy template; hide/disable Continue |

### 7.4 Accessibility / RTL / l10n

- Semantics labels on CTA, cards (name).  
- RTL via Material + Arabic fonts (existing).  
- All user strings in `app_en.arb` / `app_ar.arb` via `context.l10n`.  
- Relation via `dedication_relation_l10n.dart`.  
- Intro story in l10n (PRD copy).  
- Visual: Support calm rules ([support_visual_system.md](../../packages/ui_kit/docs/support_visual_system.md)).

### 7.5 Onboarding change

[`onboarding_screen.dart`](../../apps/tilawa/lib/features/onboarding/presentation/screens/onboarding_screen.dart): remove third `OnboardingContent` (portrait). Page count = 2. Keep asset for founding card.

---

## 8. Routing

### 8.1 App routes

```text
@TypedGoRoute<SadaqahJariyahRoute>(path: '/sadaqah-jariyah')
```

- Under shell with Settings (same parent pattern as `SupportRoute` `/support`).  
- Navigate: `const SadaqahJariyahRoute().push(context)`.

### 8.2 Entry points

| From | Action |
|------|--------|
| Settings tile | Push route (title from config or default) |
| About | Push route |
| Support footer | Soft text button → push route |
| Deep link | `/sadaqah-jariyah` if app links configured |

### 8.3 Feature flag

- Compile/remote launch flag (mirror Support): e.g. `TILAWA_LAUNCH_SADAQAH_JARIYAH_ENABLED` (default true when ready).  
- AND `config.featureEnabled`.  
- If disabled: hide Settings/About/Support entries; deep link → safe redirect (Settings or Home).

### 8.4 Navigation flow

```text
Settings → SadaqahJariyahScreen → sheet → external WhatsApp
SadaqahJariyahScreen → SupportRoute (footer, optional)
```

No slug routes in MVP.

---

## 9. State Management

### 9.1 `SadaqahJariyahCubit`

```text
states:
  SadaqahJariyahInitial
  SadaqahJariyahLoading
  SadaqahJariyahLoaded(pageData, photoUrls: Map<id,String?>)
  SadaqahJariyahError(Failure)
```

**Lifecycle:**

- `load()` on screen open (`BlocProvider` create or `context.read` + `initState`).  
- `refresh()` pull-to-refresh optional (nice); retry button calls `load()`.  
- Resolve photo URLs after dedications load (async; cards update as URLs arrive — or resolve in use case before emit Loaded for simpler MVP).

**Prefer simpler MVP:** use case returns dedications; cubit resolves photos then emits single `Loaded` (show loader until photos attempted; timeouts → null urls).

### 9.2 DI

- `@LazySingleton` repositories/datasources/resolver.  
- `@injectable` use cases.  
- Cubit: `factory` / `getIt` in route builder (same as other features).

### 9.3 Refresh strategy

- Every screen entry: fetch (Firestore cache makes this cheap).  
- No realtime listeners required in MVP (`get` once).  
- Optional Phase 2: snapshots.

---

## 10. Remote Configuration

**Source:** single Firestore doc `app_config/sadaqah_jariyah` (not Firebase Remote Config in MVP).

**Load:** `SadaqahJariyahConfigRemoteDataSource.get()` — same style as `FirestoreForcedUpdateConfigRemoteDataSource`.

**Fallback:**

1. Doc missing / error → default entity.  
2. Empty title/subtitle fields → l10n defaults.  
3. Empty WhatsApp → degrade CTA.  
4. Empty templates → bundled constants in domain.

**Caching:** Firestore persistence + optional repo memory for session.

**Failure handling:** never block list on config failure — use defaults + still show dedications if dedications fetch OK. If dedications fail → error state.

---

## 11. Security

### 11.1 Threat model (MVP)

| Threat | Mitigation |
|--------|------------|
| Client forges dedication | Client cannot write dedications |
| Client reads ops/amounts | `private/ops` admin-only |
| Client uploads photos | Storage write admin-only |
| Spam publish | Human WhatsApp + admin |
| Title XSS in admin | Angular binding; plain text fields |
| Hotlink abuse | Own Storage paths only |
| Enum injection | Mapper unknown → null |

### 11.2 Permissions

| Actor | dedications | config | storage photos | private ops |
|-------|-------------|--------|----------------|-------------|
| Anonymous/signed-in user | read published | read | read | deny |
| Admin claim | full | full | write | full |

### 11.3 Privacy

- No donor names/amounts on public docs.  
- Photos only with family consent (ops process).  
- Archive on family takedown request.  
- Slug not shown in MVP UI (still treat as public identifier for future web).

---

## 12. Performance

| Topic | MVP approach |
|-------|----------------|
| Pagination | **None** — load all published (expect small N). Add cursor when N hurts (Phase 2) |
| Caching | Firestore persistence + URL TTL map |
| Images | Resolve URL once; network image; letter fallback; founding asset |
| Reads | 1 config get + 1 query per open |
| Cost | Public read OK; avoid listeners; avoid storing download URLs |
| Offline | Persistence; avatar fallbacks |

**Cost optimization:** overwrite Storage object at same path; no historical photo versions.

---

## 13. Testing

### 13.1 Unit

- `sortDedicationsForDisplay` banding (founding before featured before rest; sortOrder).  
- Config mapper empty → defaults.  
- Dedication mapper unknown relation → null.  
- Slug normalize/validate.  
- WhatsApp URI builder encoding.  
- Note URL rejection (admin util / shared validation).

### 13.2 Repository

- Fake Firestore / fake datasource: published filter; error mapping.  
- Config missing doc → defaults.

### 13.3 Widget

- Screen loading / error / loaded with founder.  
- Letter avatar when no photo.  
- Founding uses asset when path null.  
- CTA opens sheet; sheet shows intention line.  
- Wrap `MaterialApp` + `AppTheme.getLightTheme` + l10n delegates (project convention).  
- Prefer fakes over mocks.

### 13.4 Golden (optional MVP)

- Founding card + dedication card light theme — if goldens already used nearby; else skip.

### 13.5 Integration

- Flag off hides settings tile (if testable).  
- Rules tests (`functions/test-rules`): published readable; draft not; private deny; config public read; admin write.

### 13.6 Admin

- `slug.util` unit tests.  
- Mapping tests for dedication form ↔ Firestore.  
- Manual QA checklist for publish/archive/photo.

### 13.7 Acceptance (manual)

Map to PRD acceptance checklist (titles, WhatsApp, founding first, no amounts, onboarding 2 pages, etc.).

---

## 14. Implementation Order

### Phase A — Backend foundation

1. `firestore.indexes.json` entry if needed  
2. `firestore.rules` dedications + config + slugs + private  
3. `storage.rules` photos/dedications  
4. Seed script: founding dedication + slug pointer + default config doc  

### Phase B — Domain + data (app)

5. Entities, enums, failures  
6. Mappers + datasources + repos + photo resolver  
7. Use cases + unit tests  

### Phase C — Presentation (app)

8. Cubit + states  
9. Widgets + screen  
10. Participate sheet + WhatsApp launch (reuse wa.me pattern)  
11. l10n AR/EN  
12. Routing + Settings/About/Support entries + flag  

### Phase D — Onboarding

13. Remove page 3; fix tests  

### Phase E — Admin

14. Paths, repository, slug util  
15. List + edit + config screens  
16. Storage upload  
17. Nav + i18n  

### Phase F — Hardening

18. Rules tests  
19. Widget tests  
20. Manual QA + scholar copy gate before prod flag on  
21. `melos run fix:format` · analyze · targeted tests  

---

## 15. Engineering Checklist (GitHub-issue sized)

### Backend

- [ ] **SJ-01** Add Firestore rules for `app_config/sadaqah_jariyah` (public read, admin write)  
- [ ] **SJ-02** Add Firestore rules for `dedications` published read + admin write  
- [ ] **SJ-03** Add Firestore rules for `dedications/{id}/private/{doc}` admin-only  
- [ ] **SJ-04** Add Firestore rules for `dedications_slugs` admin-only  
- [ ] **SJ-05** Add composite index `dedications: status + sortOrder`  
- [ ] **SJ-06** Add Storage rules for `photos/dedications/{file}`  
- [ ] **SJ-07** Seed script: founding doc `ahmed-mohamed-tony` + slug pointer + default config  

### App domain/data

- [ ] **SJ-08** Add `DedicationRelation` + `DedicationStatus` enums  
- [ ] **SJ-09** Add `Dedication` + `SadaqahJariyahConfig` + `SadaqahJariyahPageData`  
- [ ] **SJ-10** Add `SadaqahJariyahFailure`  
- [ ] **SJ-11** Add repository interfaces + photo resolver interface  
- [ ] **SJ-12** Implement Firestore dedications datasource + mapper  
- [ ] **SJ-13** Implement config datasource + mapper (defaults)  
- [ ] **SJ-14** Implement Storage download URL resolver with TTL cache  
- [ ] **SJ-15** Implement repository impls + DI registration  
- [ ] **SJ-16** Implement `GetSadaqahJariyahPageUseCase`  
- [ ] **SJ-17** Implement `SortDedicationsForDisplayUseCase` + unit tests  
- [ ] **SJ-18** Implement `BuildWhatsappParticipateUriUseCase` + unit tests  

### App UI / routing

- [ ] **SJ-19** Add AR/EN l10n (title defaults, intro, CTA, sheet, relations, footer)  
- [ ] **SJ-20** Build letter avatar + dedication card + founding card widgets  
- [ ] **SJ-21** Build intro, list, footer, CTA widgets  
- [ ] **SJ-22** Build participate bottom sheet  
- [ ] **SJ-23** Implement `SadaqahJariyahCubit` + screen with loading/error/empty  
- [ ] **SJ-24** Add `SadaqahJariyahRoute` `/sadaqah-jariyah` + codegen  
- [ ] **SJ-25** Wire Settings + About + Support soft link entry points  
- [ ] **SJ-26** Add launch flag `TILAWA_LAUNCH_SADAQAH_JARIYAH_ENABLED` gate  
- [ ] **SJ-27** WhatsApp launch + fallback copy number/message  

### Onboarding

- [ ] **SJ-28** Remove Abu Hudhaifa onboarding page; update widget tests  

### Admin

- [ ] **SJ-29** Add `dedications.paths.ts` + repository  
- [ ] **SJ-30** Implement slug util + unit tests  
- [ ] **SJ-31** List page (filters status / search)  
- [ ] **SJ-32** Create/edit form (relation enum, featured, sortOrder, founding lock)  
- [ ] **SJ-33** Photo upload to Storage + set `photoStoragePath`  
- [ ] **SJ-34** Private ops editor  
- [ ] **SJ-35** Publish/archive actions + slug immutability after publish  
- [ ] **SJ-36** Config page (titles, WhatsApp, templates, featureEnabled)  
- [ ] **SJ-37** Sidebar nav + admin l10n  

### QA

- [ ] **SJ-38** Rules tests: draft hidden; published visible; private denied  
- [ ] **SJ-39** Widget tests: banding order; avatar fallback; sheet intention text  
- [ ] **SJ-40** Manual acceptance pass vs PRD checklist  
- [ ] **SJ-41** Scholar/copy review sign-off before enabling prod flag  
- [ ] **SJ-42** `dart run melos run fix:format` + analyze + targeted `flutter test`  

---

## 16. Analytics (minimal)

| Event | When |
|-------|------|
| `sadaqah_jariyah_screen_viewed` | Screen loaded |
| `sadaqah_jariyah_cta_tapped` | Support MeMuslim CTA |
| `sadaqah_jariyah_whatsapp_opened` | Launch success |
| `sadaqah_jariyah_whatsapp_failed` | Launch fail |

No amount or deceased PII in event params.

---

## 17. Out of scope (do not implement)

- In-app payment / auto-publish  
- Self-serve dedication create  
- Slug public profile UI  
- deathDate / anniversary pushes  
- Pagination, social, badges, amounts  
- Dual Remote Config title sync  
- Persisting download URLs on Firestore  

---

## 18. Verify commands

```sh
# from workspace root
dart run melos run fix:format
dart run melos run analyze
# app
cd apps/tilawa && flutter test test/features/sadaqah_jariyah
# rules (if added under functions/test-rules)
```

---

**End of engineering SPEC.** Implement against this document; product questions → PRD only.
