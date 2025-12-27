#!/usr/bin/env bash
set -euo pipefail

# Script to run all tests
# Usage: ./run-tests.sh [--quick] [--verbose]

QUICK=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --quick)
      QUICK=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Usage: $0 [--quick] [--verbose]"
      exit 1
      ;;
  esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

run_test() {
  local test_name="$1"
  local test_file="$2"
  local description="$3"
  
  if [ ! -f "$test_file" ]; then
    log_warn "Test file not found: $test_file"
    return 1
  fi
  
  log_info "Running test: $description"
  
  if [ "$VERBOSE" = true ]; then
    if nix-instantiate --eval -E "import $test_file" 2>&1; then
      log_info "✓ Test passed: $test_name"
      return 0
    else
      log_error "✗ Test failed: $test_name"
      return 1
    fi
  else
    if nix-instantiate --eval -E "import $test_file" > /dev/null 2>&1; then
      log_info "✓ Test passed: $test_name"
      return 0
    else
      log_error "✗ Test failed: $test_name"
      return 1
    fi
  fi
}

# Main test function
main() {
  local total_tests=0
  local passed_tests=0
  local failed_tests=0
  
  log_info "Starting test suite..."
  
  # Quick tests (run in --quick mode)
  if [ "$QUICK" = true ]; then
    run_test "wireguard-config" "tests/wireguard-config-test.nix" "WireGuard configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "frr-config" "tests/frr-config-test.nix" "FRR configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "wireguard-wg0" "tests/wireguard-wg0-test.nix" "WireGuard wg0 configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "wireguard-secrets" "tests/wireguard-secrets-test.nix" "WireGuard secrets configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
  fi
  
  # WireGuard tests
  if [ "$QUICK" = false ]; then
    run_test "wireguard-interface" "tests/wireguard-interface-test.nix" "WireGuard interface configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "wireguard-peers" "tests/wireguard-peers-test.nix" "WireGuard peers configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "wireguard-mtu" "tests/wireguard-mtu-test.nix" "WireGuard MTU configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
  fi
  
  # BGP tests
  if [ "$QUICK" = false ]; then
    run_test "bgp-session" "tests/bgp-session-test.nix" "BGP session configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "bgp-routes" "tests/bgp-routes-test.nix" "BGP routes configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "bgp-evpn" "tests/bgp-evpn-test.nix" "BGP EVPN configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
  fi
  
  # VLAN tests
  if [ "$QUICK" = false ]; then
    run_test "vlan-bridge" "tests/vlan-bridge-test.nix" "VLAN bridge configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "vlan-ports" "tests/vlan-ports-test.nix" "VLAN ports configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "vlan-routing" "tests/vlan-routing-test.nix" "VLAN routing configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
  fi
  
  # Security tests
  if [ "$QUICK" = false ]; then
    run_test "security-ssh" "tests/security-ssh-test.nix" "SSH security configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "security-firewall" "tests/security-firewall-test.nix" "Firewall configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "security-hardening" "tests/security-hardening-test.nix" "System hardening configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
  fi
  
  # Monitoring tests
  if [ "$QUICK" = false ]; then
    run_test "monitoring-prometheus" "tests/monitoring-prometheus-test.nix" "Prometheus configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "monitoring-grafana" "tests/monitoring-grafana-test.nix" "Grafana configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "monitoring-exporters" "tests/monitoring-exporters-test.nix" "Exporters configuration"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
  fi

  # New configuration tests
  if [ "$QUICK" = false ]; then
    run_test "wireguard-config" "tests/wireguard-config-test.nix" "WireGuard configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "frr-config" "tests/frr-config-test.nix" "FRR configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "wireguard-wg0" "tests/wireguard-wg0-test.nix" "WireGuard wg0 configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
    
    run_test "wireguard-secrets" "tests/wireguard-secrets-test.nix" "WireGuard secrets configuration test"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
  fi
  
  # Summary
  log_info "\n${YELLOW}Test Summary:${NC}"
  echo "================"
  echo "Total tests: $total_tests"
  echo "Passed: $passed_tests"
  echo "Failed: $failed_tests"
  
  if [ $failed_tests -eq 0 ]; then
    log_info "\n${GREEN}All tests passed!${NC}"
    return 0
  else
    log_error "\n${RED}Some tests failed${NC}"
    return 1
  fi
}

main "$@"
