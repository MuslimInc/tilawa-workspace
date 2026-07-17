#!/bin/sh
# Generate UUID-matched dSYM shells for prebuilt vendor frameworks that ship
# without DWARF (Agora RTC extensions, LiveKit WebRTC, etc.).
#
# Xcode App Store validation warns "Upload Symbols Failed" when a framework's
# Mach-O UUID has no matching dSYM in the archive. Agora/WebRTC binaries are
# stripped, so we cannot recover real crash symbols — but `dsymutil` still
# emits a dSYM with the correct UUID, which clears the upload warning.
#
# Must run after "[CP] Embed Pods Frameworks".

set -euo pipefail

FRAMEWORKS_DIR="${TARGET_BUILD_DIR:-}/${FRAMEWORKS_FOLDER_PATH:-}"
DSYM_DIR="${DWARF_DSYM_FOLDER_PATH:-}"

if [ ! -d "$FRAMEWORKS_DIR" ] || [ -z "$DSYM_DIR" ]; then
  exit 0
fi

mkdir -p "$DSYM_DIR"

is_vendor_framework() {
  case "$1" in
    Agora*|Agoraf*|WebRTC|aosl|video_dec|video_enc)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

generated=0
for framework in "$FRAMEWORKS_DIR"/*.framework; do
  [ -d "$framework" ] || continue
  name="$(basename "$framework" .framework)"
  if ! is_vendor_framework "$name"; then
    continue
  fi

  binary="$framework/$name"
  if [ ! -f "$binary" ]; then
    continue
  fi

  # Skip when a real/existing dSYM is already present for this framework.
  out="$DSYM_DIR/${name}.framework.dSYM"
  if [ -d "$out/Contents/Resources/DWARF" ]; then
    existing_uuid="$(xcrun dwarfdump --uuid "$out" 2>/dev/null | awk '{print $2; exit}')"
    binary_uuid="$(xcrun dwarfdump --uuid "$binary" 2>/dev/null | awk '{print $2; exit}')"
    if [ -n "$existing_uuid" ] && [ "$existing_uuid" = "$binary_uuid" ]; then
      continue
    fi
    rm -rf "$out"
  fi

  echo "note: Generating vendor dSYM for ${name}.framework"
  if xcrun dsymutil "$binary" -o "$out" >/dev/null 2>&1; then
    generated=$((generated + 1))
  else
    echo "warning: dsymutil failed for ${name}.framework" >&2
  fi
done

echo "note: Generated ${generated} vendor dSYM(s) into ${DSYM_DIR}"
