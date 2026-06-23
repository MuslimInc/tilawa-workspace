#!/usr/bin/env bash
# Quran Sessions Free Beta — pre-upload / pre-QA automated checks.
# Usage: ./scripts/quran_sessions_preflight.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== dart analyze (quran_sessions + affected tilawa paths) =="
# --no-fatal-warnings: pre-existing unused warnings in quran_sessions tests.
dart analyze --no-fatal-warnings packages/quran_sessions
dart analyze --no-fatal-warnings \
  apps/tilawa/lib/core/bootstrap/app_launch_config.dart \
  apps/tilawa/lib/features/auth \
  apps/tilawa/lib/features/notifications/data \
  apps/tilawa/lib/router/quran_sessions_session_guard.dart \
  apps/tilawa/lib/features/quran_sessions

echo "== Flutter — quran_sessions booking/join suite =="
(
  cd packages/quran_sessions
  flutter test \
    test/domain/usecases/join_session_usecase_test.dart \
    test/domain/usecases/submit_session_booking_usecase_test.dart \
    test/boundaries/call_provider_test.dart \
    test/boundaries/routing_session_call_provider_test.dart \
    test/presentation/screens/booking_screen_test.dart \
    test/presentation/blocs/my_sessions_bloc_test.dart \
    test/presentation/screens/session_detail_screen_test.dart
)

echo "== Flutter — single-active-device suite =="
(
  cd apps/tilawa
  flutter test \
    test/features/auth \
    test/features/notifications/data \
    test/router/quran_sessions_session_guard_test.dart
)

echo "== Functions — unit tests =="
(
  cd functions
  npm test
)

if command -v java >/dev/null 2>&1; then
  JAVA_VER="$(java -version 2>&1 | head -1 || true)"
  if echo "$JAVA_VER" | grep -qE 'version "21'; then
    echo "== Functions — integration + rules (JDK 21) =="
    (
      cd functions
      npm run test:integration
      npm run test:rules
    )
  else
    echo "SKIP integration/rules tests (JDK 21 required; found: $JAVA_VER)"
    echo "  macOS: export JAVA_HOME=\"\$(/usr/libexec/java_home -v 21)\""
  fi
else
  echo "SKIP integration/rules tests (java not found)"
fi

echo ""
echo "Preflight complete."
