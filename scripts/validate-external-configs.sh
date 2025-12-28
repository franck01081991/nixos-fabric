#!/usr/bin/env bash
# Dynamic External Configuration Validator
# Validates all external configurations automatically

set -euo pipefail

echo "🔍 Validating external configurations..."

# Check if we're in the right directory
if [ ! -d "external" ]; then
    echo "❌ Please run this script from the repository root"
    exit 1
fi

# Find all external configurations
EXTERNAL_CONFIGS=$(find external -maxdepth 1 -type d -name "*config" | sort)

if [ -z "$EXTERNAL_CONFIGS" ]; then
    echo "ℹ️ No external configurations found"
    exit 0
fi

echo "📁 Found external configurations:"
echo "$EXTERNAL_CONFIGS" | sed 's/^/  • /'
echo ""

# Validate each configuration
VALIDATION_FAILED=false

for config_dir in $EXTERNAL_CONFIGS; do
    config_name=$(basename "$config_dir")
    echo "🔧 Validating $config_name..."
    
    # Check required files
    REQUIRED_FILES=("default.nix" "variables.nix" "base-variables.nix" "role-variables.nix")
    MISSING_FILES=()
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$config_dir/$file" ]; then
            MISSING_FILES+=("$file")
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -gt 0 ]; then
        echo "❌ $config_name: Missing required files:"
        for file in "${MISSING_FILES[@]}"; do
            echo "    - $file"
        done
        VALIDATION_FAILED=true
        continue
    fi
    
    # Try to evaluate the configuration with proper context
    if ! nix-instantiate --eval -E "with import <nixpkgs> {}; callPackage $config_dir/default.nix {}" 2>/dev/null; then
        echo "❌ $config_name: Configuration evaluation failed"
        VALIDATION_FAILED=true
        continue
    fi
    
    # Check for common issues
    if ! grep -q "network-fabric" "$config_dir/default.nix" 2>/dev/null; then
        echo "⚠️  $config_name: Warning - No network-fabric reference found"
    fi
    
    echo "✅ $config_name: Validation passed"
    echo ""
done

# Summary
if [ "$VALIDATION_FAILED" = true ]; then
    echo "❌ External configuration validation FAILED"
    exit 1
else
    echo "✅ All external configurations validated successfully"
    echo ""
    echo "💡 Next steps:"
    echo "  • Run: ./scripts/sync-configs.sh to sync validated configs"
    echo "  • Run: nix flake check to validate the full system"
    echo "  • Run: ./tests/scripts/run-local-tests.sh to run all tests"
    exit 0
fi