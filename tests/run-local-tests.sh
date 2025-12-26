#!/usr/bin/env bash

# NixOS Fabric Test Runner
# Run comprehensive tests for the NixOS Fabric configuration

set -euo pipefail

# Check Nix version
check_nix_version() {
    local required_version="2.18.0"
    local current_version=$(nix --version | cut -d' ' -f3)
    
    if [ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" != "$required_version" ]; then
        echo "❌ Nix version $current_version is too old. Required: $required_version+"
        echo "📋 Please upgrade Nix:"
        echo "   nix upgrade-nix"
        echo "   or"
        echo "   curl -L https://nixos.org/nix/install | sh"
        exit 1
    else
        echo "✅ Nix version $current_version is compatible"
    fi
}

# Run version check
check_nix_version

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${TEST_DIR}/.."

# Function to run Nix tests
un_nix_tests() {
    echo -e "${BLUE}Running Nix tests...${NC}"
    
    # Run the test runner
    if nix-instantiate --eval -E "
      let
        pkgs = import <nixpkgs> {};
        tests = import ${TEST_DIR};
        config = import ${PROJECT_ROOT}/flake.nix;
      in
        tests.runTests config
    " > /tmp/test-results.json 2>&1; then
        echo -e "${GREEN}✓ Nix tests completed successfully${NC}"
        cat /tmp/test-results.json | jq .
        return 0
    else
        echo -e "${RED}✗ Nix tests failed${NC}"
        cat /tmp/test-results.json
        return 1
    fi
}

# Function to run basic validation
un_basic_validation() {
    echo -e "${BLUE}Running basic validation...${NC}"
    
    # Check flake validity
    if nix flake check; then
        echo -e "${GREEN}✓ Flake validation passed${NC}"
    else
        echo -e "${RED}✗ Flake validation failed${NC}"
        return 1
    fi
    
    # Check vm-sapinet configuration
    if nix eval .#nixosConfigurations.vm-sapinet.config.networking.hostName > /dev/null 2>&1; then
        echo -e "${GREEN}✓ vm-sapinet configuration valid${NC}"
    else
        echo -e "${RED}✗ vm-sapinet configuration invalid${NC}"
        return 1
    fi
    
    # Check rtr-noisy configuration
    if nix eval .#nixosConfigurations.rtr-noisy.config.networking.hostName > /dev/null 2>&1; then
        echo -e "${GREEN}✓ rtr-noisy configuration valid${NC}"
    else
        echo -e "${RED}✗ rtr-noisy configuration invalid${NC}"
        return 1
    fi
    
    return 0
}

# Function to run syntax checks
un_syntax_checks() {
    echo -e "${BLUE}Running syntax checks...${NC}"
    
    local failed=0
    
    # Check all Nix files
    for file in $(find ${PROJECT_ROOT} -name "*.nix" -not -path "*/.git/*"); do
        if nix-instantiate --parse ${file} > /dev/null 2>&1; then
            echo -e "${GREEN}✓ ${file}${NC}"
        else
            echo -e "${RED}✗ ${file}${NC}"
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✓ All syntax checks passed${NC}"
        return 0
    else
        echo -e "${RED}✗ $failed syntax checks failed${NC}"
        return 1
    fi
}

# Function to show test summary
test_summary() {
    echo -e "${BLUE}
========================================${NC}"
    echo -e "${BLUE}NixOS Fabric Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}Basic Validation:    ${basic_result}${NC}"
    echo -e "${YELLOW}Syntax Checks:      ${syntax_result}${NC}"
    echo -e "${YELLOW}Nix Tests:          ${nix_result}${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ "$basic_result" = "✓ PASS" ] && [ "$syntax_result" = "✓ PASS" ] && [ "$nix_result" = "✓ PASS" ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}NixOS Fabric Test Runner${NC}"
    echo -e "${BLUE}=========================${NC}"
    
    # Run basic validation
    if run_basic_validation; then
        basic_result="✓ PASS"
    else
        basic_result="✗ FAIL"
    fi
    
    # Run syntax checks
    if run_syntax_checks; then
        syntax_result="✓ PASS"
    else
        syntax_result="✗ FAIL"
    fi
    
    # Run Nix tests
    if run_nix_tests; then
        nix_result="✓ PASS"
    else
        nix_result="✗ FAIL"
    fi
    
    # Show summary
    test_summary
}

# Run main function
main "$@"