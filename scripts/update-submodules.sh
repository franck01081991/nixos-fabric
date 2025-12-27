#!/usr/bin/env bash

# Script to update and clean Git submodules
# Usage: ./scripts/update-submodules.sh

set -euo pipefail

echo "🔄 Updating submodules..."
git submodule update --remote --recursive

echo "🧹 Cleaning submodules..."
git submodule foreach git reset --hard
git submodule foreach git clean -fd

echo "📝 Adding submodule changes..."
git add external/rtr-noisy-config external/rtr-sapinet-config

echo "✅ Submodules updated and cleaned successfully!"
echo "💡 Don't forget to commit the changes:"
echo "   git commit -m 'chore: Update submodules to latest commits'"