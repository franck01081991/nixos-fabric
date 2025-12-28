#!/usr/bin/env bash
# Enhanced Synchronization and Validation Script
# Automatically validates and syncs external configurations

set -euo pipefail

echo "🔄 Enhanced Synchronization and Validation"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "flakes/flake.nix" ]; then
    echo "❌ Please run this script from the repository root"
    exit 1
fi

# Step 1: Validate external configurations
echo "🔍 Step 1/3: Validating external configurations..."
if ! ./scripts/validate-external-configs.sh; then
    echo "❌ Validation failed - aborting synchronization"
    exit 1
fi
echo "✅ Validation completed successfully"
echo ""

# Step 2: Run comprehensive tests
echo "🧪 Step 2/3: Running comprehensive tests..."
if ! ./tests/scripts/test-external-configs.sh; then
    echo "❌ Tests failed - aborting synchronization"
    exit 1
fi
echo "✅ Tests completed successfully"
echo ""

# Step 3: Synchronize validated configurations
echo "🔄 Step 3/3: Synchronizing validated configurations..."

# Find all external configurations
EXTERNAL_CONFIGS=$(find external -maxdepth 1 -type d -name "*config" | sort)

for config_dir in $EXTERNAL_CONFIGS; do
    config_name=$(basename "$config_dir")
    host_dir="hosts/$config_name"
    
    echo "  📁 Processing $config_name..."
    
    # Create host directory if it doesn't exist
    mkdir -p "$host_dir"
    
    # Copy configuration files
    cp -v "$config_dir/"*.nix "$host_dir/" 2>/dev/null || true
    cp -v "$config_dir/"*.md "$host_dir/" 2>/dev/null || true
    
    # Update README to indicate synchronization
    cat > "$host_dir/README.md" << 'EOF'
# Synchronized Configuration

This configuration has been automatically synchronized from the external repository.

## Synchronization Info
- Source: external/$config_name/
- Status: Validated and synchronized

## Usage

This configuration is ready for deployment.
EOF
    
    echo "  ✅ $config_name synchronized"
done

echo ""
echo "✅ All configurations synchronized successfully"
echo ""
echo "📊 Summary:"
echo "  • Validated: $(echo "$EXTERNAL_CONFIGS" | wc -l | tr -d ' ') configurations"
echo "  • Synchronized: $(echo "$EXTERNAL_CONFIGS" | wc -l | tr -d ' ') configurations"
echo "  • Ready for deployment"
echo ""
echo "💡 Next steps:"
echo "  • Review synchronized configurations in hosts/"
echo "  • Run: nix flake check to validate the full system"
echo "  • Run: ./tests/scripts/run-local-tests.sh for comprehensive testing"
echo "  • Deploy using: sudo nixos-rebuild switch --flake .#<hostname>"
