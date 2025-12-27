#!/usr/bin/env bash

# NixOS Fabric Organized Test Runner
# 
# This script runs comprehensive tests for the organized repository structure
# and validates the new security module organization

set -e

echo "🚀 NixOS Fabric Organized Test Runner"
echo "======================================"
echo ""

# Test 1: Security Module Structure
echo "Test 1: Security Module Structure"
echo "----------------------------------"
if [ -f "modules/security/init.nix" ] && \
   [ -f "modules/security/default.nix" ] && \
   [ -f "modules/security/README.md" ] && \
   [ -f "modules/security/index.nix" ] && \
   [ -f "modules/security/QUICKSTART.md" ]; then
    echo "✅ PASS: Security module structure is organized"
else
    echo "❌ FAIL: Security module structure issues"
    exit 1
fi
echo ""

# Test 2: Security Module Syntax
echo "Test 2: Security Module Syntax"
echo "------------------------------"
if nix-instantiate --eval -E 'import ./modules/security/init.nix' > /dev/null 2>&1; then
    echo "✅ PASS: Security module syntax is valid"
else
    echo "❌ FAIL: Security module syntax errors"
    exit 1
fi
echo ""

# Test 3: Example Configuration
echo "Test 3: Example Configuration"
echo "-----------------------------"
if nix-instantiate --eval -E 'import ./examples/security-example.nix' > /dev/null 2>&1; then
    echo "✅ PASS: Example configuration is valid"
else
    echo "❌ FAIL: Example configuration errors"
    exit 1
fi
echo ""

# Test 4: Security Test Suite
echo "Test 4: Security Test Suite"
echo "----------------------------"
if nix-build -E 'with import <nixpkgs> {}; callPackage ./tests/modules/security/init.nix {}' > /dev/null 2>&1; then
    echo "✅ PASS: Security test suite passed"
else
    echo "❌ FAIL: Security test suite failed"
    exit 1
fi
echo ""

# Test 5: VM Test Configuration
echo "Test 5: VM Test Configuration"
echo "------------------------------"
if nix-instantiate --eval -E 'with import <nixpkgs> {}; { inherit (callPackage ./tests/vm-test-config.nix {}) config; }' > /dev/null 2>&1; then
    echo "✅ PASS: VM test configuration is valid"
else
    echo "❌ FAIL: VM test configuration errors"
    exit 1
fi
echo ""

# Test 6: Repository Structure
echo "Test 6: Repository Structure"
echo "-----------------------------"
if [ -f "STRUCTURE.md" ] && \
   [ -d "modules/security" ] && \
   [ -d "tests/modules/security" ] && \
   [ -d "examples" ]; then
    echo "✅ PASS: Repository structure is well-organized"
else
    echo "❌ FAIL: Repository structure issues"
    exit 1
fi
echo ""

# Test 7: Documentation Completeness
echo "Test 7: Documentation Completeness"
echo "-----------------------------------"
doc_files=(
    "modules/security/README.md"
    "modules/security/QUICKSTART.md"
    "modules/security/index.nix"
    "STRUCTURE.md"
)

missing_docs=0
for doc in "${doc_files[@]}"; do
    if [ ! -f "$doc" ]; then
        echo "❌ Missing: $doc"
        missing_docs=$((missing_docs + 1))
    fi
done

if [ $missing_docs -eq 0 ]; then
    echo "✅ PASS: All documentation files are present"
else
    echo "❌ FAIL: Missing $missing_docs documentation files"
    exit 1
fi
echo ""

# Test 8: Host Configurations
echo "Test 8: Host Configurations"
echo "----------------------------"
host_configs=(
    "hosts/rtr-sapinet/default.nix"
    "hosts/rtr-noisy/default.nix"
)

host_errors=0
for host in "${host_configs[@]}"; do
    if [ -f "$host" ]; then
        if nix-instantiate --eval -E "import ./$host" > /dev/null 2>&1; then
            echo "✅ PASS: $(basename "$host") configuration is valid"
        else
            echo "❌ FAIL: $(basename "$host") configuration has errors"
            host_errors=$((host_errors + 1))
        fi
    else
        echo "⚠️  SKIP: $(basename "$host") not found"
    fi
done

if [ $host_errors -eq 0 ]; then
    echo "✅ PASS: All host configurations are valid"
else
    echo "❌ FAIL: $host_errors host configuration errors"
    exit 1
fi
echo ""

echo "======================================"
echo "🎉 All Organized Tests Passed!"
echo "======================================"
echo ""
echo "Summary:"
echo "  ✅ Security module structure"
echo "  ✅ Security module syntax"
echo "  ✅ Example configuration"
echo "  ✅ Security test suite"
echo "  ✅ VM test configuration"
echo "  ✅ Repository structure"
echo "  ✅ Documentation completeness"
echo "  ✅ Host configurations"
echo ""
echo "The repository is well-organized and ready! 🚀"
echo ""
echo "Key Improvements:"
echo "  • Organized security module with clear structure"
echo "  • Comprehensive documentation and quick start guide"
echo "  • Standardized test organization"
echo "  • Improved code comments and organization"
echo "  • Consistent naming conventions"
echo ""

# Additional information
echo "Next Steps:"
echo "  • Review modules/security/README.md for full documentation"
echo "  • Check modules/security/QUICKSTART.md for quick setup"
echo "  • See STRUCTURE.md for repository organization"
echo "  • Run specific tests with: nix-instantiate --eval -E 'import ./path/to/test.nix'"
echo ""

# Success exit
exit 0