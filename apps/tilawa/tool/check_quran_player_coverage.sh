#!/usr/bin/env bash
# Enforces ≥90% line coverage on Phase C player logic (excludes quran_player_widget.dart).
set -euo pipefail
cd "$(dirname "$0")/.."
MIN_PCT=90

TESTS=(
  test/shared/widgets/quran_player_hero_test.dart
  test/shared/widgets/quran_player_hero_widgets_test.dart
  test/shared/widgets/quran_player_expand_gesture_policy_test.dart
  test/shared/widgets/quran_player_expand_drag_integration_test.dart
  test/shared/widgets/quran_player_expand_physics_test.dart
  test/shared/widgets/quran_player_expanded_route_transition_test.dart
  test/shared/widgets/quran_player_queue_utils_test.dart
  test/shared/widgets/quran_player_queue_hot_path_test.dart
  test/features/audio_player/presentation/player_presentation_controller_test.dart
)

SCOPE=(
  lib/shared/widgets/quran_player_expand_gesture_policy.dart
  lib/shared/widgets/quran_player_expand_physics.dart
  lib/shared/widgets/quran_player_queue_utils.dart
  lib/shared/widgets/quran_player_route_progress_guard.dart
  lib/shared/widgets/quran_player_transition_test_utils.dart
  lib/shared/widgets/quran_player_hero_tags.dart
  lib/shared/widgets/quran_player_expanded_route_transition.dart
  lib/features/audio_player/presentation/player_presentation_controller.dart
)

fvm flutter test --coverage "${TESTS[@]}" >/dev/null

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

echo "Phase C player coverage ≥ ${MIN_PCT}%"
