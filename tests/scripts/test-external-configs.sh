#!/usr/bin/env bash
# Test External Configurations Script
# Runs comprehensive tests on all external configurations

set -euo pipefail

echo "🧪 Testing external configurations..."

# Check if we're in the right directory
if [ ! -f "tests/integration/external-configs-test.nix" ]; then
    echo "❌ Please run this script from the repository root"
    exit 1
fi

# Run the external configs test with proper context
if nix-instantiate --eval -E "with import <nixpkgs> {}; callPackage ./tests/integration/external-configs-test.nix {}" 2>/dev/null; then
    echo "✅ External configuration tests passed"
    
    # Show detailed results
    echo ""
    echo "📊 Test Results:"
    echo "  All external configurations passed validation"
    echo "  Found configs: $(ls -1 external/*-config 2>/dev/null | wc -l | tr -d ' ')"
    
    exit 0
else
    echo "❌ External configuration tests failed"
    
    # Show failure details
    echo ""
    echo "🔍 Failure Details:"
    nix eval --apply 'result: result.summary.failures' -E "with import <nixpkgs> {}; callPackage ./tests/integration/external-configs-test.nix {}" 2>/dev/null || echo "Unable to show detailed failures"
    
    exit 1
fi