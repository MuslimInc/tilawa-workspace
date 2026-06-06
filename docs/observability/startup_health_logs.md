# Startup health logs (Firestore)

Cold-start milestones and failures are written to the **`app_startup_logs`**
collection so you can query them like backend logs in the Firebase console or
BigQuery export.

## Document shape

| Field | Type | Description |
|--------|------|-------------|
| `level` | string | `info` or `error` |
| `event` | string | `startup_phase`, `startup_failed`, `startup_completed` |
| `phase` | string | Milestone name (e.g. `boot_gate_start`, `firebase_ready`) |
| `reason` | string | Failure reason (errors only) |
| `error_type` / `error_message` | string | Truncated error summary (errors only) |
| `elapsed_ms` | number | Ms since process start |
| `session_id` | string | Per-launch id |
| `app_version` / `build_number` | string | From `package_info_plus` |
| `platform` | string | `android`, `ios`, … |
| `build_mode` | string | `release`, `profile`, `debug` |
| `client_timestamp_ms` | number | Device wall clock |
| `server_ingested_at` | timestamp | Firestore server time |

Full stack traces stay in **Crashlytics**; Firestore rows are for search and
funnels.

## Example queries (console)

- Stuck splash: `event == "startup_phase"` and `phase == "boot_gate_start"` with
  no matching `startup_completed` for the same `session_id`.
- Startup failures: `event == "startup_failed"` grouped by `reason`.

## Security rules (deploy to Firebase)

Rules live in repo root [`firestore.rules`](../../firestore.rules) (wired in
`firebase.json`). Deploy before the first patched build:

```bash
firebase deploy --only firestore:rules
```

Tighten further with **Firebase App Check** on the client (already used in Tilawa).

**Patch rollout:** [patch_startup_telemetry.md](patch_startup_telemetry.md) (Option A).

## Related signals

- **Crashlytics**: non-fatal `startup_failed` + breadcrumbs `startup_phase:*`
- **Analytics**: same event names for dashboards and alerts

Implementation: `apps/tilawa/lib/core/telemetry/startup_telemetry.dart`.
