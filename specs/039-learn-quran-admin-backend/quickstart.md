# Quickstart: Validate Learn Quran Admin and Backend Completion

## Local quality gate

```sh
cd apps/tilawa_admin
npm test
npm run build
```

```sh
cd functions
npm run build
npm test
npm run test:emulator
```

## Admin configuration smoke test

1. Sign in as an administrator and load Global Settings.
2. Use a non-production policy whose age threshold is not 14.
3. Change an unrelated global flag, save, reload, and verify the threshold is
   unchanged.
4. Open Market Pricing and verify video-only is fixed, not an editable market
   choice.
5. Submit an invalid policy value and verify no saved value changes.

## Report and dispute smoke test

1. Use isolated non-production data for an open report and an open dispute.
2. Move the report to under review, then resolve/dismiss with a reason.
3. Resolve the dispute with an allowed outcome and a reason.
4. Verify authoritative terminal state, resolver, timestamp, audit data, and at
   most one financial record where applicable.
5. Retry each terminal action and repeat as a non-administrator; verify no
   duplicate effect and an authorization failure respectively.

## App Check staging evidence

1. Record a named owner and current enforcement state.
2. Enable attestation in staging only.
3. Exercise authenticated pricing, booking, report, dispute, and admin
   resolution flows from attested clients; record successes/rejections.
4. Exercise one non-attested request and verify observable rejection without
   sensitive payload logging.
5. If a critical flow fails, restore the recorded enforcement state and record
   the rollback result. Do not promote until all evidence is complete.

