#!/bin/bash
set -e

# Adapt these commands to your project's toolchain.
# This is a reference template — copy and customize per project.

echo "▶ Type check..."   && tsc --noEmit
echo "▶ Lint..."         && eslint . --max-warnings 0
echo "▶ Tests..."        && jest --coverage --passWithNoTests
echo "▶ Build check..."  && npm run build
echo "✅ All checks passed"
