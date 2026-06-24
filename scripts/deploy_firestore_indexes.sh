#!/usr/bin/env bash
# Deploy Firestore composite indexes for Quran Sessions teacher filters (P2.8).
#
# Usage:
#   ./scripts/deploy_firestore_indexes.sh [firebase-project-id]
#
# Prerequisites: firebase CLI logged in; indexes defined in firestore.indexes.json.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${1:-quran-playera-app}"

echo "== Deploy Firestore indexes to project: ${PROJECT} =="
cd "${ROOT}"
firebase deploy --only firestore:indexes --project "${PROJECT}"

echo ""
echo "Index deploy submitted. Monitor build status in Firebase console before enabling filtered teacher queries in prod."
