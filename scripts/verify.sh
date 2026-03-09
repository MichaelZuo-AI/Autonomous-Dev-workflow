#!/bin/bash
set -e

echo "▶ Type check..."   && tsc --noEmit
echo "▶ Lint..."         && eslint . --max-warnings 0
echo "▶ Tests..."        && jest --coverage --passWithNoTests
echo "▶ Build check..."  && expo export --platform ios --dev false
echo "✅ All checks passed"
