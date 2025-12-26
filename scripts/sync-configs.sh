#!/bin/bash
# Synchronization script for external configurations

set -e

echo "🔄 Synchronizing configurations..."

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Please run this script from the repository root"
    exit 1
fi

# Create temp directory if it doesn't exist
mkdir -p temp-export

# Export current configurations
echo "📤 Exporting current configurations..."
cp -r hosts/rtr-sapinet/* temp-export/rtr-sapinet-config/
cp -r hosts/rtr-noisy/* temp-export/rtr-noisy-config/

# Update README files
cat > temp-export/rtr-sapinet-config/README.md << 'EOF'
# rtr-sapinet-config - Pure Spine Node
This configuration is synchronized with the main nixos-fabric repository.
EOF

cat > temp-export/rtr-noisy-config/README.md << 'EOF'
# rtr-noisy-config - Hybrid Node
This configuration is synchronized with the main nixos-fabric repository.
EOF

echo "✅ Configurations exported to temp-export/"
echo ""
echo "To push to external repositories:"
echo "1. cd temp-export/rtr-sapinet-config"
echo "2. git init && git add . && git commit -m 'Update from main repo'"
echo "3. git remote add origin https://github.com/franck01081991/rtr-sapinet-config.git"
echo "4. git push -u origin master"
echo ""
echo "Repeat for rtr-noisy-config"

echo ""
echo "To import from external repositories:"
echo "1. cp -r external/rtr-sapinet-config/* hosts/rtr-sapinet/"
echo "2. cp -r external/rtr-noisy-config/* hosts/rtr-noisy/"
echo "3. git add hosts/ && git commit -m 'Update from external repos'"

echo ""
echo "💡 Tip: Use 'git submodule' for automatic synchronization"