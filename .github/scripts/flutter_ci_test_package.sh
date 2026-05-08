#!/usr/bin/env bash
set -euo pipefail

test_list="$(mktemp)"
trap 'rm -f "$test_list"' EXIT

find test \
  -name '*_test.dart' \
  ! -path 'test/goldens/*' \
  ! -name '*timeline_test.dart' \
  -print | sort >"$test_list"

if [ ! -s "$test_list" ]; then
  echo "No CI test files found in $(pwd)"
  exit 0
fi

xargs flutter test --reporter expanded <"$test_list"
