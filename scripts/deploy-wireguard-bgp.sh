#!/usr/bin/env bash
set -euo pipefail

# Script de déploiement automatisé WireGuard + BGP EVPN
# Usage: ./deploy-wireguard-bgp.sh [--dry-run]

DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Usage: $0 [--dry-run]"
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

run_cmd() {
  local cmd="$1"
  local description="$2"
  
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would execute: $description"
    log_info "Command: $cmd"
    return 0
  fi
  
  log_info "Executing: $description"
  if eval "$cmd"; then
    log_info "✓ Success: $description"
    return 0
  else
    log_error "✗ Failed: $description"
    return 1
  fi
}

# Generate WireGuard keys
generate_wg_keys() {
  local host="$1"
  local key_path="/etc/wireguard/${host}.key"
  local pub_path="/etc/wireguard/${host}.pub"

  if [[ ! -f "$key_path" ]]; then
    run_cmd "sudo mkdir -p /etc/wireguard" "Create WireGuard directory"
    run_cmd "wg genkey | sudo tee ${key_path} | wg pubkey | sudo tee ${pub_path}" "Generate WireGuard keys for ${host}"
    run_cmd "sudo chmod 600 ${key_path} ${pub_path}" "Set secure permissions for keys"
    run_cmd "sudo chown root:root ${key_path} ${pub_path}" "Set ownership for keys"
  else
    log_info "WireGuard keys already exist for ${host}"
  fi
}

# Fetch public key from remote host
fetch_remote_pubkey() {
  local remote_host="$1"
  local remote_user="$2"
  local local_path="/tmp/${remote_host}.pub"
  
  if [[ ! -f "$local_path" ]]; then
    run_cmd "scp ${remote_user}@${remote_host}:/etc/wireguard/${remote_host}.pub ${local_path}" "Fetch public key from ${remote_host}"
  else
    log_info "Public key from ${remote_host} already cached"
  fi
  
  cat "$local_path"
}

# Replace placeholders in configuration
replace_placeholders() {
  local sapinet_pub="$1"
  local noisy_pub="$2"
  
  local hostname=$(hostname)
  
  case "$hostname" in
    rtr-sapinet)
      run_cmd "sudo sed -i 's/__RTR_NOISY_PUB__/${noisy_pub}/' /etc/nixos/variables.nix" "Replace rtr-noisy public key"
      ;;
    rtr-noisy)
      run_cmd "sudo sed -i 's/__RTR_SAPINET_PUB__/${sapinet_pub}/' /etc/nixos/variables.nix" "Replace rtr-sapinet public key"
      ;;
    *)
      log_error "This script must be run on rtr-sapinet or rtr-noisy"
      exit 1
      ;;
  esac
}

# Verify WireGuard configuration
verify_wireguard() {
  log_info "Verifying WireGuard configuration..."
  
  if ! command -v wg &> /dev/null; then
    log_error "WireGuard not installed"
    return 1
  fi
  
  local wg_output
  wg_output=$(wg show 2>&1)
  
  if echo "$wg_output" | grep -q "interface: wgtransport"; then
    log_info "✓ WireGuard interface exists"
    
    if echo "$wg_output" | grep -q "handshake:"; then
      log_info "✓ WireGuard handshake successful"
      return 0
    else
      log_warn "⚠ WireGuard handshake not established"
      return 1
    fi
  else
    log_error "✗ WireGuard interface not found"
    return 1
  fi
}

# Verify BGP configuration
verify_bgp() {
  log_info "Verifying BGP configuration..."
  
  if ! command -v vtysh &> /dev/null; then
    log_error "FRR not installed"
    return 1
  fi
  
  local bgp_output
  bgp_output=$(vtysh -c "show bgp summary" 2>&1)
  
  if echo "$bgp_output" | grep -q "Established"; then
    log_info "✓ BGP session established"
    return 0
  else
    log_warn "⚠ BGP session not established"
    echo "$bgp_output"
    return 1
  fi
}

# Verify VLAN configuration
verify_vlan() {
  log_info "Verifying VLAN configuration..."
  
  if ! command -v bridge &> /dev/null; then
    log_error "bridge command not available"
    return 1
  fi
  
  local vlan_output
  vlan_output=$(bridge vlan show 2>&1)
  
  if echo "$vlan_output" | grep -q "br0"; then
    log_info "✓ Bridge br0 exists"
    
    if echo "$vlan_output" | grep -q "VLAN=10"; then
      log_info "✓ VLAN 10 configured"
      return 0
    else
      log_warn "⚠ VLAN 10 not found"
      return 1
    fi
  else
    log_error "✗ Bridge br0 not found"
    return 1
  fi
}

# Main deployment function
main() {
  local hostname=$(hostname)
  local sapinet_pub=""
  local noisy_pub=""
  
  log_info "Starting WireGuard + BGP EVPN deployment on ${hostname}"
  
  # Generate local keys
  generate_wg_keys "$hostname"
  
  # Fetch remote public keys
  case "$hostname" in
    rtr-sapinet)
      noisy_pub=$(fetch_remote_pubkey "rtr-noisy" "franck")
      ;;
    rtr-noisy)
      sapinet_pub=$(fetch_remote_pubkey "rtr-sapinet" "franck")
      ;;
    *)
      log_error "Unknown hostname: $hostname"
      exit 1
      ;;
  esac
  
  # Replace placeholders
  replace_placeholders "$sapinet_pub" "$noisy_pub"
  
  # Apply NixOS configuration
  run_cmd "sudo nixos-rebuild switch" "Apply NixOS configuration"
  
  # Verify deployment
  log_info "Running verification checks..."
  
  local wg_ok=false
  local bgp_ok=false
  local vlan_ok=false
  
  # Give services time to start
  sleep 5
  
  # Check WireGuard (3 attempts)
  for i in {1..3}; do
    if verify_wireguard; then
      wg_ok=true
      break
    fi
    sleep 10
  done
  
  # Check BGP (3 attempts)
  for i in {1..3}; do
    if verify_bgp; then
      bgp_ok=true
      break
    fi
    sleep 10
  done
  
  # Check VLAN (only on rtr-noisy)
  if [[ "$hostname" == "rtr-noisy" ]]; then
    for i in {1..3}; do
      if verify_vlan; then
        vlan_ok=true
        break
      fi
      sleep 5
    done
  else
    vlan_ok=true
  fi
  
  # Summary
  log_info "\n${YELLOW}Deployment Summary:${NC}"
  echo "===================="
  echo "Host: $hostname"
  echo "WireGuard: ${wg_ok && echo "✓ OK" || echo "✗ FAILED"}"
  echo "BGP: ${bgp_ok && echo "✓ OK" || echo "✗ FAILED"}"
  echo "VLAN: ${vlan_ok && echo "✓ OK" || echo "✗ FAILED"}"
  
  if [[ "$wg_ok" = true && "$bgp_ok" = true && "$vlan_ok" = true ]]; then
    log_info "\n${GREEN}Deployment completed successfully!${NC}"
    return 0
  else
    log_error "\n${RED}Deployment completed with errors${NC}"
    return 1
  fi
}

main "$@"
