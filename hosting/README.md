# Tilawa legal pages (Firebase Hosting)

Static pages for Google Play compliance:

| URL path | File |
|----------|------|
| `/privacy` | `privacy/index.html` |
| `/delete-account` | `delete-account/index.html` |

Deploy (after configuring Firebase project + custom domain `tilawa.app`):

```bash
firebase deploy --only hosting
```

Enter these URLs in Play Console:

- **Privacy policy:** `https://tilawa.app/privacy`
- **Data deletion:** `https://tilawa.app/delete-account`

Override in-app links at build time if needed:

```bash
--dart-define=TILAWA_PRIVACY_POLICY_URL=https://...
--dart-define=TILAWA_ACCOUNT_DELETION_URL=https://...
```

See `apps/tilawa/lib/core/app_legal_urls.dart`.
