#!/usr/bin/env bash
# Deploy stable-scope Quran Sessions Cloud Functions (Phase 4 App Check wiring).
#
# Usage:
#   ./scripts/deploy_quran_session_callables.sh [firebase-project-id]
#
# Optional env (set before deploy):
#   QURAN_SESSIONS_ENFORCE_APP_CHECK=true   # ops flip — default unset (off)
#
# Prerequisites: firebase CLI logged in, functions deps built (`cd functions && npm ci`).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${1:-quran-playera-app}"

# Stable-scope session callables (see sessionCallableWiring.test.ts).
STABLE_CALLABLES=(
  createSessionBooking
  cancelSessionBooking
  requestSessionReschedule
  confirmSessionReschedule
  completeSession
  markSessionNoShow
  openSessionDispute
  resolveSessionDispute
  reportSessionConcern
  resolveSessionReport
  issueSessionRtcToken
  registerActiveDevice
  getBookingPricingQuote
  getBookingPricingQuotes
  updateMarketPricingConfig
  setTeacherSessionPricing
  confirmManualBookingPayment
  rejectManualBookingPayment
  expirePendingReservations
)

# Scheduled jobs for session reminders (production notifications).
SCHEDULED_FUNCTIONS=(
  sessionReminders
)

ONLY_ARGS=()
for fn in "${STABLE_CALLABLES[@]}"; do
  ONLY_ARGS+=("functions:${fn}")
done

DEPLOY_REMINDERS="${DEPLOY_SESSION_REMINDERS:-true}"
if [[ "${DEPLOY_REMINDERS}" == "true" ]]; then
  for fn in "${SCHEDULED_FUNCTIONS[@]}"; do
    ONLY_ARGS+=("functions:${fn}")
  done
fi

ONLY_CSV=$(IFS=,; echo "${ONLY_ARGS[*]}")

echo "== Deploy Quran Sessions CFs to project: ${PROJECT} =="
echo "   Callables: ${#STABLE_CALLABLES[@]}"
if [[ "${DEPLOY_REMINDERS}" == "true" ]]; then
  echo "   Scheduled: ${SCHEDULED_FUNCTIONS[*]}"
fi
if [[ -n "${QURAN_SESSIONS_ENFORCE_APP_CHECK:-}" ]]; then
  echo "   QURAN_SESSIONS_ENFORCE_APP_CHECK=${QURAN_SESSIONS_ENFORCE_APP_CHECK}"
else
  echo "   QURAN_SESSIONS_ENFORCE_APP_CHECK unset (default off — safe for staging)"
fi

cd "${ROOT}/functions"
firebase deploy --only "${ONLY_CSV}" --project "${PROJECT}"

echo ""
echo "Deploy complete. Smoke with release build + manual B1–B5 / T2–T8 checklist."
