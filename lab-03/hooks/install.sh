#!/usr/bin/env bash
# Install the hooks for this clone: point git at the versioned hooks directory.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
chmod +x lab-03/hooks/pre-commit lab-03/hooks/pre-push
git config core.hooksPath lab-03/hooks
echo "hooks installed: core.hooksPath = $(git config core.hooksPath)"
