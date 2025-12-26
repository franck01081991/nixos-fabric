#!/bin/bash
# Setup script for external configuration submodules

set -e

echo "🚀 Setting up external configuration submodules..."

# Create external directory if it doesn't exist
mkdir -p external

# Initialize and update submodules
if [ -f ".gitmodules" ]; then
    echo "📦 Initializing submodules..."
    git submodule init
    git submodule update
else
    echo "⚠️  No .gitmodules file found. Please create external repositories first."
    echo ""
    echo "To set up submodules manually:"
    echo "1. Create repositories on GitHub:"
    echo "   - https://github.com/franck01081991/rtr-sapinet-config"
    echo "   - https://github.com/franck01081991/rtr-noisy-config"
    echo ""
    echo "2. Push the exported configurations:"
    echo "   cd temp-export/rtr-sapinet-config"
    echo "   git init && git add . && git commit -m 'Initial commit'"
    echo "   git remote add origin https://github.com/franck01081991/rtr-sapinet-config.git"
    echo "   git push -u origin master"
    echo ""
    echo "3. Add submodules to this repository:"
    echo "   git submodule add https://github.com/franck01081991/rtr-sapinet-config.git external/rtr-sapinet-config"
    echo "   git submodule add https://github.com/franck01081991/rtr-noisy-config.git external/rtr-noisy-config"
fi

echo "✅ Submodule setup complete!"

echo ""
echo "Available commands:"
echo "- git submodule update --remote  # Update all submodules"
echo "- git submodule status           # Check submodule status"
echo "- git submodule foreach git pull # Pull latest changes in all submodules"