#!/usr/bin/env bash
# Audit Dart and asset changes since a Shorebird release tag/commit, so you can
# catch patch-unsafe changes (new icons, new JSON fields, new assets) before
# running `shorebird patch`.
#
# Usage:
#   ./scripts/shorebird-preflight.sh <release-tag-or-commit>
#
# Example:
#   ./scripts/shorebird-preflight.sh v1.0.2+27

set -euo pipefail

BASE="${1:-}"
if [[ -z "$BASE" ]]; then
  echo "Usage: $0 <release-tag-or-commit>" >&2
  exit 2
fi

if ! git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; then
  echo "error: '$BASE' is not a valid git ref" >&2
  exit 2
fi

APP_DIR="apps/tilawa"
RED=$'\033[0;31m'; YEL=$'\033[0;33m'; GRN=$'\033[0;32m'; NC=$'\033[0m'
warned=0

section() { printf "\n%s== %s ==%s\n" "$YEL" "$1" "$NC"; }
ok()      { printf "%s✓%s %s\n" "$GRN" "$NC" "$1"; }
warn()    { printf "%s⚠%s %s\n" "$RED" "$NC" "$1"; warned=$((warned+1)); }

echo "Comparing $BASE..HEAD"

# ---- Asset changes ---------------------------------------------------------
section "Asset file changes (won't ship via patch)"
asset_diff=$(git diff --name-only "$BASE..HEAD" -- "$APP_DIR/assets/" || true)
if [[ -z "$asset_diff" ]]; then
  ok "No asset files changed."
else
  warn "Asset files changed:"
  printf '    %s\n' $asset_diff
  echo "    → On-device assets won't update. If new JSON keys are required,"
  echo "      make them nullable or use @JsonKey(defaultValue: ...)."
fi

# ---- Newly-referenced icons ------------------------------------------------
section "Newly-referenced icons (font is tree-shaken at release build)"
icon_pattern='(Icons|FluentIcons|HugeIcons)\.[a-zA-Z0-9_]+'
new_icons=$(git diff "$BASE..HEAD" -- "$APP_DIR/lib/" \
  | grep '^+' | grep -v '^+++' \
  | grep -oE "$icon_pattern" \
  | sort -u || true)
old_icons=$(git grep -hE "$icon_pattern" "$BASE" -- "$APP_DIR/lib/" 2>/dev/null \
  | grep -oE "$icon_pattern" | sort -u || true)
truly_new=$(comm -23 <(echo "$new_icons") <(echo "$old_icons") | grep -v '^$' || true)
if [[ -z "$truly_new" ]]; then
  ok "No new icons referenced."
else
  warn "Icons referenced for the first time in this branch:"
  printf '    %s\n' $truly_new
  echo "    → These will render as missing-glyph boxes on patched devices."
fi

# ---- New required fields on JSON-backed freezed models --------------------
section "New 'required' fields on freezed models with @JsonKey"
risky=$(git diff "$BASE..HEAD" -- "$APP_DIR/lib/" \
  | grep -B1 -E '^\+.*required\s+\w+\s+\w+,?\s*$' \
  | grep -E "@JsonKey" || true)
if [[ -z "$risky" ]]; then
  ok "No newly-added 'required' JsonKey fields detected."
else
  warn "Possible newly-required JSON fields:"
  echo "$risky" | sed 's/^/    /'
  echo "    → If the field can be missing in old on-device JSON, parsing throws."
  echo "      Use 'String?' or @JsonKey(defaultValue: ...)."
fi

# ---- pubspec.yaml plugin version changes ----------------------------------
section "pubspec changes (plugin upgrades may cause native diffs)"
pub_diff=$(git diff --stat "$BASE..HEAD" -- '**/pubspec.yaml' '**/pubspec.lock' || true)
if [[ -z "$pub_diff" ]]; then
  ok "No pubspec.yaml or pubspec.lock changes."
else
  warn "Dependency files changed:"
  printf '    %s\n' "$pub_diff"
  echo "    → If native plugins moved versions, the patch may be blocked."
  echo "      Build first; Shorebird will flag native diffs explicitly."
fi

# ---- Summary --------------------------------------------------------------
echo
if (( warned == 0 )); then
  printf "%sPreflight clean.%s Safe to run: shorebird patch android --release-version <ver>\n" "$GRN" "$NC"
  exit 0
else
  printf "%s%d warning(s).%s Review above before patching. See docs/shorebird.md.\n" "$YEL" "$warned" "$NC"
  exit 1
fi
