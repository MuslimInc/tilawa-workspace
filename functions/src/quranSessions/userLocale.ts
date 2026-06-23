/**
 * Reads the user's app language from a Firestore `users/{uid}` document.
 *
 * Field: top-level `languageCode` (`ar` | `en`). Falls back to `en`.
 */
export function readUserLanguageCode(
  userData: Record<string, unknown> | undefined | null,
): "ar" | "en" {
  const direct = userData?.languageCode;
  if (typeof direct === "string" && direct.length > 0) {
    return direct === "ar" ? "ar" : "en";
  }

  const preferences = userData?.preferences;
  if (preferences && typeof preferences === "object") {
    const nested = (preferences as Record<string, unknown>).languageCode
      ?? (preferences as Record<string, unknown>).locale;
    if (typeof nested === "string" && nested.length > 0) {
      return nested === "ar" ? "ar" : "en";
    }
  }

  return "en";
}
