# Support Tilawa — Google Play products

**Product spec:** [`specs/016-support-tilawa/spec.md`](../specs/016-support-tilawa/spec.md)  
**Visual rules:** [`packages/ui_kit/docs/support_visual_system.md`](../packages/ui_kit/docs/support_visual_system.md)

Create these **consumable** in-app products in Play Console for package
`com.tilawa.app`. Set prices in Console; the app shows Play-formatted prices.

| Product ID | Suggested label (EN) | Suggested price (USD) |
|------------|----------------------|------------------------|
| `support_once_small` | Small support | ~$2.99 |
| `support_once_kind` | Kind support | ~$4.99 |
| `support_once_generous` | Generous support | ~$9.99 |

## Feature flag

Enabled by default. Disable for a build with:

```bash
flutter run --dart-define=TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED=false
```

## Upload a build to Play Console

Play unlocks **One-time products** after it sees `com.android.vending.BILLING` in an
Upload a release AAB via the **Android Release (Google Play)** GitHub workflow, or locally:

```bash
cd apps/tilawa
flutter build appbundle --release --target-platform android-arm64 --obfuscate --split-debug-info=build/symbols
```

Upload: `apps/tilawa/build/app/outputs/bundle/release/app-release.aab`

**Closed testing:** Test and release → Testing → Closed testing → pick a track
(e.g. **Closed testing - Alpha** if empty) → Create new release → upload AAB.

Then: merchant account → create the three consumables → license testers.

See also: [`docs/google_play_release_checklist.md`](google_play_release_checklist.md), [`docs/ci_release.md`](ci_release.md).

## Cloud Function

Deploy `verifySupportPurchase` (region `us-central1`). The default App Engine /
Cloud Functions service account needs **Google Play Android Developer API**
access in Google Cloud Console, linked to Play Console API access.

Ledger collection: `support_purchases/{sha256(purchaseToken)}` for replay
protection (MVP — no user entitlement document).
