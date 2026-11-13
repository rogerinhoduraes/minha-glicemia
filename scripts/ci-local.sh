#!/usr/bin/env bash
# CI local (sem GitHub Actions): analyze + testes quando há mudança em código Flutter desde origin/main.
set -euo pipefail
cd "$(dirname "$0")/.."

BASE=$(git merge-base HEAD origin/main 2>/dev/null || git rev-list --max-parents=0 HEAD | tail -1)
CHANGED=$(git diff --name-only "$BASE"...HEAD; git diff --name-only; git diff --name-only --cached)

if ! echo "$CHANGED" | grep -qE '^(lib/|test/|pubspec\.(yaml|lock)|android/|ios/)'; then
  echo "ci-local: nenhuma mudança em código Flutter, nada a checar."
  exit 0
fi

echo "ci-local: flutter analyze"
flutter analyze --no-pub

echo "ci-local: flutter test"
flutter test --no-pub

echo "ci-local: OK"
