#!/usr/bin/env bash
# Enforces ≥90% line coverage on audio session sync (handler ↔ bloc alignment).
set -euo pipefail
cd "$(dirname "$0")/.."
MIN_PCT=90

TESTS=(
  test/features/audio_player/presentation/bloc/audio_player_bloc_test.dart
  test/features/audio_player/presentation/bloc/audio_player_bloc_sync_active_playback_test.dart
  test/features/audio_player/domain/usecases/sync_active_playback_from_handler_use_case_test.dart
  test/features/audio_player/data/repositories/audio_player_repository_impl_test.dart
  test/shared/audio/audio_player_handler_impl_test.dart
)

# File-level gate for handler ↔ repository ↔ use case sync plumbing.
# Bloc session-dismiss logic is covered by audio_player_bloc*_test.dart separately.
SCOPE=(
  lib/features/audio_player/domain/entities/active_playback_snapshot.dart
  lib/features/audio_player/domain/usecases/sync_active_playback_from_handler_use_case.dart
  lib/features/audio_player/data/repositories/audio_player_repository_impl.dart
  lib/shared/audio/audio_player_handler_impl.dart
)

if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
else
  FLUTTER=(flutter)
fi

"${FLUTTER[@]}" test --coverage "${TESTS[@]}" >/dev/null

python3 - "$MIN_PCT" "${SCOPE[@]}" <<'PY'
import re, sys
from pathlib import Path

min_pct = float(sys.argv[1])
scope = sys.argv[2:]
lcov = Path("coverage/lcov.info").read_text()
by_file = {}
for rec in lcov.split("end_of_record\n"):
    m = re.search(r"^SF:(.+)$", rec, re.M)
    if not m:
        continue
    path = m.group(1)
    lines = re.findall(r"^DA:(\d+),(\d+)$", rec, re.M)
    hit = sum(1 for _, h in lines if int(h) > 0)
    by_file[path] = (hit, len(lines))

failed = []
total_hit = total = 0
for f in scope:
    hit, tot = by_file.get(f, (0, 0))
    total_hit += hit
    total += tot
    pct = 100 * hit / tot if tot else 100
    ok = pct >= min_pct
    print(f"{'OK' if ok else 'FAIL'} {pct:5.1f}% ({hit}/{tot}) {f}")
    if not ok:
        failed.append(f)

combined = 100 * total_hit / total if total else 100
print(f"\nCombined: {combined:.1f}% ({total_hit}/{total})")
if failed:
    print(f"\nBelow {min_pct}%: {', '.join(failed)}", file=sys.stderr)
    sys.exit(1)
PY

echo "Audio player session sync coverage ≥ ${MIN_PCT}%"
