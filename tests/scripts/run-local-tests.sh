#!/bin/bash
# Local test runner for NixOS Fabric
# This script runs basic validation tests without requiring Nix builds

set -e

echo "🧪 Running NixOS Fabric Local Tests"
echo "===================================="

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# Test function
test_case() {
    local name="$1"
    local command="$2"
    
    echo -e "${YELLOW}🔍 Running test: $name${NC}"
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS: $name${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}❌ FAIL: $name${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

# Configuration validation tests
echo -e "\n📋 Configuration Validation Tests"
echo "----------------------------------"

test_case "Flake.nix syntax check" "nix flake check --no-write-lock-file"
test_case "Flake evaluation" "nix eval .#nixosConfigurations.rtr-sapinet.config.networking.hostName"
test_case "Spine configuration" "nix eval .#nixosConfigurations.rtr-sapinet.config.network-fabric.roles.spine.enable"
test_case "Leaf configuration" "nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.leaf.enable"
test_case "Hybrid configuration" "nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.spine.enable"

# Module structure tests
echo -e "\n📦 Module Structure Tests"
echo "--------------------------"

test_case "Network fabric module exists" "test -f modules/network-fabric.nix"
test_case "Generic role module exists" "test -f modules/roles/generic.nix"
test_case "Spine role module exists" "test -f modules/roles/spine-improved.nix"
test_case "Leaf role module exists" "test -f modules/roles/leaf-improved.nix"
test_case "Ansible module exists" "test -f modules/ansible-improved.nix"

# Documentation tests
echo -e "\n📚 Documentation Tests"
echo "-----------------------"

test_case "Architecture documentation exists" "test -f docs/architecture/ARCHITECTURE.md"
test_case "Contributing guide exists" "test -f CONTRIBUTING.md"
test_case "Code of conduct exists" "test -f CODE_OF_CONDUCT.md"
test_case "Readme exists" "test -f README.md"

# Test structure tests
echo -e "\n🧪 Test Structure Tests"
echo "-----------------------"

test_case "Test runner exists" "test -f tests/run-tests.nix"
test_case "Test utilities exist" "test -f tests/utils/default.nix"
test_case "Module tests exist" "test -f tests/modules/default.nix"
test_case "Role tests exist" "test -f tests/roles/default.nix"

# Script tests
echo -e "\n📜 Script Tests"
echo "-----------------"

test_case "Sync script exists" "test -f scripts/sync-bidirectional.sh"
test_case "Sync script is executable" "test -x scripts/sync-bidirectional.sh"
test_case "Deployment script exists" "test -f scripts/deploy-and-verify.sh"
test_case "WireGuard script exists" "test -f scripts/deploy-wireguard.sh"

# Ansible tests
echo -e "\n🤖 Ansible Tests"
echo "-----------------"

test_case "Ansible configuration exists" "test -f ansible/ansible.cfg"
test_case "Ansible playbooks exist" "test -d ansible/playbooks"
test_case "Ansible roles exist" "test -d ansible/roles"
test_case "Ansible inventory exists" "test -d ansible/inventory"

# Summary
echo -e "\n📊 Test Summary"
echo "================"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo -e "Total: $((PASS_COUNT + FAIL_COUNT))"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi