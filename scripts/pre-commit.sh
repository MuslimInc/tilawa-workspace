#!/bin/sh
echo "Running pre-commit hook..."

# Format code
if ! dart format .; then
  echo "dart format failed"
  exit 1
fi

# Fix code
if ! dart fix --apply; then
  echo "dart fix failed"
  exit 1
fi

# Stage any changes made by the above commands
git add .
