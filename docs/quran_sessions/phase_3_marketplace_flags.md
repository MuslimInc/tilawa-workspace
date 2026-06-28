# Phase 3 — Paid marketplace readiness (feature flags)

**Status:** UX polish behind flags — no production paid booking by default.

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` | `false` | Wallet nav, sandbox checkout, wallet screen |
| `QuranSessionsFeatureConfig.walletEnabled` | mirrors sandbox flag | Hides wallet entry when false |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | `true` (staging) | Booking routes; independent of paid |
| `quranTutorBookingMode` (Firestore / distribution) | `autoConfirm` staging; `requiresTutorApproval` play prod | Invite / approval flow |

## Enable sandbox paid UX (local / staging)

```sh
flutter run \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED=true
```

Verify:

- Sessions home → Wallet entry visible
- Paid teacher booking → price summary on booking screen → sandbox checkout sheet
- Wallet screen shows sandbox notice strip

## Phase 3 scope notes

- **Price filters:** client-side only (`free`, `paid`, `budget` chips on teacher list).
- **Profile budget preference:** deferred — no `UserProfile` field yet.
- **PSP:** `SandboxPaymentProvider` only; no real gateway wired.

See also: [production_readiness_status.md](./production_readiness_status.md).
