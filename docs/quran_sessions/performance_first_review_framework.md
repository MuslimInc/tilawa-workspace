# Quran Sessions — Performance-First Review Framework

**Canonical gate** for every Quran Sessions feature, change, refactor, or review.

**Priority order (intentional):**

1. **Performance** — fast, scalable, reliable, efficient
2. **UX** — clear flows, no dead ends, understandable errors
3. **UI** — UI Kit, tokens, localization, RTL (after 1 and 2 pass)

UI polish is not first priority. A beautiful screen is not enough if booking is slow, Firestore queries are expensive, availability generation is heavy, join flow is unreliable, or audio/video quality is unstable.

**Conflict resolution:** Performance beats UI polish. Reliable performance beats fancy UX.

---

## Core principle

For every Quran Sessions change, apply this order:

### 1. Performance first

**Backend / Firebase**

- No unnecessary Firestore reads
- No global collection scans
- No unbounded queries
- Deterministic document IDs where possible
- Indexed queries only
- Minimal query count
- No duplicated reads after writes
- No full-window regeneration when incremental update suffices
- Minimize Cloud Function cold-start impact where possible
- Small callable payloads
- Controlled notification fan-out
- No expensive client-side joins
- Prefer O(1) or near O(1) lookups for critical operations
- Maps/sets/indexed structures instead of repeated list scans
- Booking/session consistency with minimal writes
- Efficient idempotency; no expensive retry loops
- No over-fetch for admin dashboards

**Flutter**

- No unnecessary rebuilds or large-tree rebuilds for small state changes
- No expensive grouping/sorting every frame
- No repeated DateTime/timezone work in `build()`
- No business logic in `build()`
- Efficient state updates; stable keys where needed
- Lazy scrollable lists
- No memory duplication for large slot/session collections
- Pagination or scoped queries — do not load everything
- No duplicate listeners or duplicate network calls on route changes

**Availability / booking**

- Availability lookup near O(1) where possible
- Slot deletion must not trigger full regeneration unless needed
- Override lookup by date key, not scan all overrides
- Deterministic slot/session IDs where possible
- Efficient duplicate-booking prevention
- Efficient teacher slot generation
- Efficient day grouping; cache when needed

**Audio / video providers**

Evaluate for: external meeting, Agora, WebRTC, future providers.

Consider: call startup time, A/V latency, reconnect, low-end Android stability (incl. OPPO A98 Android 15), memory, battery, network switching, poor network handling, permissions flow, SDK init cost, token/channel generation cost, background/foreground, 1:1 performance, future group scalability.

Provider-specific code stays behind abstraction.

### 2. UX second

After performance is safe:

- Student can book easily; teacher can manage sessions; admin can operate safely
- No dead-end states
- Clear errors, loading, and empty states
- Comfortable bottom CTAs
- No confusing approval/dashboard flow; no hidden required steps
- No stale state after admin approval
- Clear join, cancellation, report, and dispute flows
- Natural Arabic RTL
- User knows what happened after every action

Fast broken UX is still not acceptable. Do not sacrifice core performance for UI decoration.

### 3. UI third

After performance and UX pass:

- UI Kit, ARB/localization, design tokens
- Dark mode and Arabic RTL
- Visual consistency; no raw Material where UI Kit exists
- No one-off styles; no hardcoded colors/sizes/strings

Do not polish UI while performance or UX blockers exist.

---

## Required: Performance Impact Analysis (before implementation)

```markdown
## Performance Impact Analysis
### Backend / Firebase
- Queries affected:
- Reads/writes affected:
- Indexes required:
- Any global scans? Yes/No
- Any unbounded queries? Yes/No
- Complexity before:
- Complexity after:
- Expected Firestore cost impact:
### Flutter
- Rebuild impact:
- State update impact:
- List/grouping/sorting impact:
- Memory impact:
- Any repeated computations? Yes/No
### Audio/Video Provider
- Provider affected:
- Startup latency risk:
- Network/battery risk:
- Token/channel generation cost:
- Low-end Android risk:
### Verdict
- Performance safe? Yes/No
- If no, what must change first?
```

---

## Required: Complexity reporting (critical flows)

For each flow below, report:

```markdown
Flow:
Current complexity:
Target complexity:
Data structure used:
Potential bottleneck:
Recommended optimization:
Free Beta blocker? Yes/No
```

**Critical flows:**

- booking creation
- availability loading
- slot deletion
- availability override lookup
- teacher list loading
- session list loading
- join info loading
- report/dispute creation
- admin dispute/report list
- notification targeting
- single active device validation
- Agora/external/mock join path

**Prefer:** O(1), O(log n), O(k) scoped to small k, O(n) only when n is bounded and acceptable.

**Avoid:** O(n²), unbounded O(n), repeated scans, full collection reads, full-window regeneration for single-item changes.

---

## Required: Data structure review

For affected code, document structures used:

- List, Map, Set, HashMap, LinkedHashMap
- Indexed Firestore documents, deterministic IDs
- Date-key maps, slotId maps, participant maps

**Prefer for performance-sensitive features:**

- `Map<String, Slot>` — slot lookup by slotId
- `Map<DateTime, List<SlotId>>` — slots by day
- `Set<String>` — active/deleting/blocked IDs
- Deterministic document IDs for direct reads
- Scoped Firestore queries instead of full scans

Do not introduce complex structures without real performance value.

---

## Required: Firebase / backend rules

- Never query all teachers if only active/public teachers are needed
- Never query all sessions if only user sessions are needed
- Never query all disputes/reports without admin pagination
- Never scan all overrides if one date is needed
- Never trust client-calculated booking price/provider/status
- Never trust client role
- Prefer one transaction/batch over multiple writes where safer
- Avoid unnecessary Cloud Function calls when local state can update safely
- Use emulator tests for Firestore behavior where possible
- Document indexes

---

## Required: Audio/video provider performance rules

Do not choose provider on features alone. Evaluate:

1. Join speed
2. Stability on Android
3. CPU usage
4. Memory usage
5. Battery impact
6. Poor network handling
7. Reconnect behavior
8. SDK size impact
9. Permission flow
10. Security/token model
11. Cost at scale
12. Group session scalability later
13. Vendor lock-in
14. Maintainability

If Agora/WebRTC integration is proposed, include: SDK size impact, Android permissions, backend token/channel generation, cold-start/init impact, fallback if join fails, provider isolation.

---

## Required: UX review (after performance accepted)

```markdown
## UX Review
- Does the user know what to do next?
- Is the flow short and clear?
- Are errors understandable?
- Are loading states clear?
- Are actions comfortable to reach?
- Is Arabic RTL natural?
- Is there any dead-end?
- Does this reduce support burden?
- Does this make student/teacher/admin happier?
```

---

## Required: UI review (last)

```markdown
## UI Review
- UI Kit used?
- ARB strings used?
- Tokens used?
- Dark mode safe?
- RTL safe?
- Consistent spacing?
- No one-off visual hacks?
```

---

## Acceptance criteria

A Quran Sessions task is **not complete** unless:

1. Performance impact is documented
2. Firebase queries are scoped and efficient
3. No unbounded/global scans are introduced
4. Critical lookups are near O(1) where practical
5. Audio/video provider work is abstracted and performance-reviewed
6. UX is clear and does not create dead ends
7. UI follows UI Kit and ARB
8. Tests cover critical paths
9. Coverage remains ~90–100% for affected business-critical paths
10. Any remaining performance risk is documented

---

## Required: Final report (per implementation phase)

1. Performance summary
2. Complexity before/after
3. Firestore query/read/write impact
4. Flutter rebuild/memory impact
5. Audio/video provider performance impact (if relevant)
6. UX summary
7. UI summary
8. Tests added
9. Coverage percentage
10. Remaining performance risks
11. Recommended next optimization

---

## Scope

This framework applies to:

- `packages/quran_sessions/`
- `packages/quran_sessions_rtc/`
- `apps/tilawa/lib/features/quran_sessions/`
- `functions/src/quranSessions/`
- `apps/tilawa_admin/` (Quran Sessions surfaces)
- Related Firestore rules and indexes

**Baseline audit:** [baseline_performance_audit.md](./baseline_performance_audit.md)
