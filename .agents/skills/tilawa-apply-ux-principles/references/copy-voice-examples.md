# Copy voice examples (chrome strings)

Tone from `docs/tilawa_brand.md` §8. Full strings live in `*.arb`; these teach
intent for new keys.

## Do / don't (English)

| Avoid | Prefer |
|-------|--------|
| Unlock your spiritual journey! | Choose athkar for quick access |
| Oops! Something went wrong :( | We couldn't load your athkar. Try again. |
| Upgrade to Premium | Support Tilawa |
| Delete forever!!! | Remove this dhikr? |
| Find your favorite reciter! | Search reciters |

## Section titles (calm, noun phrases)

- Your athkar / أذكارك
- More / المزيد
- Daily ayah / الآية اليومية

## Empty states (invitation + one verb)

- **Empty:** "No athkar pinned yet" + CTA **Choose athkar**
- **Error:** Human reason + **Try again** (uses `context.l10n.retry` where shared)

## Destructive confirm

- Title: short fact ("Remove saved dhikr?")
- Body: what is lost (one line)
- Actions: **Cancel** (secondary) + **Remove** (destructive, not ALL CAPS)

## Arabic

- Match existing `app_ar.arb` formality; do not machine-translate religious terms
- Category names: use entity `nameAr` in UI, not English fallback, when locale is Arabic
