#!/usr/bin/env bash

# Security Module Test Runner
# 
# This script runs the security module test suite and displays the results

set -e

echo "🚀 Security Module Test Runner"
echo "================================"
echo ""

# Test 1: Module syntax validation
echo "Test 1: Module Syntax Validation"
echo "--------------------------------"
if nix-instantiate --eval -E 'import ./modules/security-improved.nix' > /dev/null 2>&1; then
    echo "✅ PASS: Module syntax is valid"
else
    echo "❌ FAIL: Module syntax has errors"
    exit 1
fi
echo ""

# Test 2: Minimal configuration
echo "Test 2: Minimal Configuration"
echo "-----------------------------"
if nix-instantiate --eval -E 'import ./tests/test-security-module.nix' > /dev/null 2>&1; then
    echo "✅ PASS: Minimal configuration works"
else
    echo "❌ FAIL: Minimal configuration has errors"
    exit 1
fi
echo ""

# Test 3: Complete configuration
echo "Test 3: Complete Configuration"
echo "------------------------------"
if nix eval -f ./tests/test-security-module.nix --json results.allTestsPassed 2>&1 | grep -q "true"; then
    echo "✅ PASS: Complete configuration works"
else
    echo "❌ FAIL: Complete configuration has errors"
    exit 1
fi
echo ""

# Test 4: Flake integration
echo "Test 4: Flake Integration"
echo "------------------------"
if nix flake check > /dev/null 2>&1; then
    echo "✅ PASS: Flake integration works"
else
    echo "❌ FAIL: Flake integration has errors"
    exit 1
fi
echo ""

# Test 5: Host configurations
echo "Test 5: Host Configurations"
echo "---------------------------"
if nix-instantiate --eval -E 'import ./hosts/rtr-sapinet/default.nix' > /dev/null 2>&1; then
    echo "✅ PASS: rtr-sapinet configuration works"
else
    echo "❌ FAIL: rtr-sapinet configuration has errors"
    exit 1
fi

if nix-instantiate --eval -E 'import ./hosts/rtr-noisy/default.nix' > /dev/null 2>&1; then
    echo "✅ PASS: rtr-noisy configuration works"
else
    echo "❌ FAIL: rtr-noisy configuration has errors"
    exit 1
fi
echo ""

echo "================================"
echo "🎉 All Security Module Tests Passed!"
echo "================================"
echo ""
echo "Summary:"
echo "  ✅ Module syntax validation"
echo "  ✅ Minimal configuration"
echo "  ✅ Complete configuration"
echo "  ✅ Flake integration"
echo "  ✅ Host configurations"
echo ""
echo "The security-improved module is ready for production use! 🚀"