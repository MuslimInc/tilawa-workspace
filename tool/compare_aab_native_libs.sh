#!/usr/bin/env bash
# Compare native libs inside two Android App Bundles (sizes, SHA-256, equality).
# Does NOT measure Play update / binary-delta size (no bsdiff / archive-patcher).
#
# Usage:
#   ./tool/compare_aab_native_libs.sh old.aab new.aab
#
# Exit 0 always after printing the report (comparison is informational).

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <old.aab> <new.aab>" >&2
  exit 2
fi

OLD_AAB=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
NEW_AAB=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")

for f in "$OLD_AAB" "$NEW_AAB"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing file: $f" >&2
    exit 1
  fi
done

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

extract_lib() {
  local aab=$1
  local dest=$2
  mkdir -p "$dest"
  # Device payload only (ignore BUNDLE-METADATA symbols / proguard.map).
  unzip -l "$aab" | awk '/base\/lib\/arm64-v8a\/.*\.so$/ { print $4 }' | while read -r path; do
    local name
    name=$(basename "$path")
    unzip -p "$aab" "$path" >"$dest/$name"
  done
}

human() {
  local bytes=$1
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec --suffix=B "$bytes"
  else
    python3 -c "b=int('$bytes'); print(f'{b/1e6:.2f} MB')"
  fi
}

extract_lib "$OLD_AAB" "$WORKDIR/old"
extract_lib "$NEW_AAB" "$WORKDIR/new"

echo "=== AAB on-disk ==="
echo "old: $(human "$(stat -f%z "$OLD_AAB" 2>/dev/null || stat -c%s "$OLD_AAB")")  $OLD_AAB"
echo "new: $(human "$(stat -f%z "$NEW_AAB" 2>/dev/null || stat -c%s "$NEW_AAB")")  $NEW_AAB"
echo

echo "=== arm64-v8a .so (what Play delivers to 64-bit phones) ==="
printf '%-22s %12s %12s %s\n' "lib" "old" "new" "sha256"
printf '%-22s %12s %12s %s\n' "----------------------" "------------" "------------" "------"

ALL_LIBS=$( (
  ls -1 "$WORKDIR/old" 2>/dev/null
  ls -1 "$WORKDIR/new" 2>/dev/null
) | sort -u)

changed=0
unchanged=0
missing=0

while IFS= read -r lib; do
  [[ -z "$lib" ]] && continue
  old_path="$WORKDIR/old/$lib"
  new_path="$WORKDIR/new/$lib"
  if [[ ! -f "$old_path" || ! -f "$new_path" ]]; then
    printf '%-22s %12s %12s %s\n' "$lib" \
      "$( [[ -f "$old_path" ]] && human "$(stat -f%z "$old_path" 2>/dev/null || stat -c%s "$old_path")" || echo missing )" \
      "$( [[ -f "$new_path" ]] && human "$(stat -f%z "$new_path" 2>/dev/null || stat -c%s "$new_path")" || echo missing )" \
      "ONLY_IN_ONE_AAB"
    missing=$((missing + 1))
    continue
  fi
  old_sz=$(stat -f%z "$old_path" 2>/dev/null || stat -c%s "$old_path")
  new_sz=$(stat -f%z "$new_path" 2>/dev/null || stat -c%s "$new_path")
  old_hash=$(shasum -a 256 "$old_path" | awk '{print $1}')
  new_hash=$(shasum -a 256 "$new_path" | awk '{print $1}')
  if [[ "$old_hash" == "$new_hash" ]]; then
    status="SAME"
    unchanged=$((unchanged + 1))
  else
    status="CHANGED"
    changed=$((changed + 1))
  fi
  printf '%-22s %12s %12s %s\n' "$lib" "$(human "$old_sz")" "$(human "$new_sz")" "$status"
  if [[ "$status" == "CHANGED" && "$lib" == "libapp.so" ]]; then
    echo "         old sha256: $old_hash"
    echo "         new sha256: $new_hash"
  fi
done <<<"$ALL_LIBS"

echo
echo "=== Verdict ==="
echo "unchanged libs: $unchanged"
echo "changed libs:   $changed"
echo "missing side:   $missing"
if [[ -f "$WORKDIR/old/libapp.so" && -f "$WORKDIR/new/libapp.so" ]]; then
  if ! cmp -s "$WORKDIR/old/libapp.so" "$WORKDIR/new/libapp.so"; then
    echo
    echo "libapp.so CHANGED (bytes differ) → likely major contributor to update cost."
    echo "SHA/equality alone do not measure Play binary-delta size; confirm in"
    echo "Play Console App size view or with a measured bsdiff/archive-patcher patch."
  else
    echo
    echo "libapp.so identical (same bytes). Expected only if both AABs share"
    echo "the exact same Flutter AOT artifact (e.g. same file compared twice)."
  fi
fi
