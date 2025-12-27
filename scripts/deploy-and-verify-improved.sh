#!/usr/bin/env bash
set -euo pipefail

# Improved Fabric Deployment and Verification Script
# This script provides comprehensive deployment, verification, and monitoring

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
DEPLOY_LOG="/tmp/fabric-deploy-$(date +%Y%m%d-%H%M%S).log"
VERBOSE=false
DRY_RUN=false
SKIP_VERIFICATION=false
TARGET_HOSTS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            echo -e "${YELLOW}📝 DRY RUN MODE - No changes will be made${NC}"
            shift
            ;;
        -s|--skip-verification)
            SKIP_VERIFICATION=true
            echo -e "${YELLOW}⏭️  SKIPPING VERIFICATION${NC}"
            shift
            ;;
        -t|--target)
            TARGET_HOSTS+=("$2")
            shift 2
            ;;
        -a|--all)
            TARGET_HOSTS=("rtr-sapinet" "rtr-noisy")
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Show help function
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -n, --dry-run           Dry run - show what would be done"
    echo "  -s, --skip-verification Skip verification steps"
    echo "  -t, --target HOST       Target specific host (rtr-sapinet, rtr-noisy)"
    echo "  -a, --all               Target all hosts"
    echo ""
    echo "Examples:"
    echo "  $0 -a                    Deploy and verify all hosts"
    echo "  $0 -t rtr-sapinet        Deploy only rtr-sapinet"
    echo "  $0 -v -n -a             Verbose dry run for all hosts"
    echo "  $0 -s -t rtr-noisy       Deploy rtr-noisy without verification"
}

# Log function
log() {
    local level="INFO"
    local color="${BLUE}"
    
    case $1 in
        "ERROR")
            level="ERROR"
            color="${RED}"
            ;;
        "WARN")
            level="WARN"
            color="${YELLOW}"
            ;;
        "SUCCESS")
            level="SUCCESS"
            color="${GREEN}"
            ;;
        "INFO")
            level="INFO"
            color="${BLUE}"
            ;;
        "DEBUG")
            level="DEBUG"
            color="${PURPLE}"
            ;;
    esac
    
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $2${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $2" >> "$DEPLOY_LOG"
}

# Check if we're in the right directory
if [ ! -d "hosts" ] || [ ! -f "flake.nix" ]; then
    log ERROR "This script must be run from the nixos-fabric repository root"
    exit 1
fi

# Determine targets if none specified
if [ ${#TARGET_HOSTS[@]} -eq 0 ]; then
    log INFO "No specific targets specified, defaulting to all hosts"
    TARGET_HOSTS=("rtr-sapinet" "rtr-noisy")
fi

# Main deployment function
deploy_host() {
    local host="$1"
    
    log INFO "Starting deployment for $host"
    
    # Check if host configuration exists
    if [ ! -d "hosts/$host" ]; then
        log ERROR "Host configuration for $host not found"
        return 1
    fi
    
    # Show host information
    log INFO "Host: $host"
    log INFO "Configuration: hosts/$host/"
    
    # Check Nix flake evaluation
    log INFO "Evaluating Nix configuration..."
    if ! nix eval ".#nixosConfigurations.$host.config.networking.hostName" > /dev/null 2>&1; then
        log ERROR "Failed to evaluate Nix configuration for $host"
        return 1
    fi
    log SUCCESS "Nix configuration evaluation successful"
    
    # Show what would be deployed
    log INFO "Configuration summary:"
    log INFO "  Hostname: $(nix eval ".#nixosConfigurations.$host.config.networking.hostName")"
    log INFO "  System: $(nix eval ".#nixosConfigurations.$host.config.system.stateVersion")"
    
    # Check if spine role is enabled
    if nix eval ".#nixosConfigurations.$host.config.network-fabric.roles.spine.enable" | grep -q "true"; then
        log INFO "  Role: Spine (enabled)"
    fi
    
    # Check if leaf role is enabled
    if nix eval ".#nixosConfigurations.$host.config.network-fabric.roles.leaf.enable" | grep -q "true"; then
        log INFO "  Role: Leaf (enabled)"
    fi
    
    # Dry run mode
    if [ "$DRY_RUN" = true ]; then
        log WARN "DRY RUN: Would deploy $host with the above configuration"
        return 0
    fi
    
    # Actual deployment
    log INFO "Deploying $host..."
    
    if sudo nixos-rebuild switch --flake ".#$host" --show-trace; then
        log SUCCESS "Successfully deployed $host"
        
        # Check if we should run verification
        if [ "$SKIP_VERIFICATION" = false ]; then
            verify_host "$host"
        fi
        
        return 0
    else
        log ERROR "Failed to deploy $host"
        return 1
    fi
}

# Verification function
verify_host() {
    local host="$1"
    
    log INFO "Verifying $host..."
    
    # Check basic system status
    log INFO "System Status:"
    if systemctl is-system-running --quiet; then
        log SUCCESS "  ✓ System is running normally"
    else
        log ERROR "  ✗ System is not running normally"
    fi
    
    # Check WireGuard
    log INFO "WireGuard Status:"
    if ip link show wgtransport > /dev/null 2>&1; then
        log SUCCESS "  ✓ WireGuard interface exists"
        
        # Show WireGuard peers
        if sudo wg show wgtransport > /dev/null 2>&1; then
            local peers=$(sudo wg show wgtransport | grep "peer:" | wc -l)
            log INFO "  ✓ WireGuard peers: $peers"
        else
            log WARN "  ⚠ WireGuard interface exists but has no peers"
        fi
    else
        log ERROR "  ✗ WireGuard interface not found"
    fi
    
    # Check FRR routing
    log INFO "FRR Routing Status:"
    if systemctl is-active --quiet frr; then
        log SUCCESS "  ✓ FRR service is running"
        
        # Check OSPF neighbors (if spine role)
        if nix eval ".#nixosConfigurations.$host.config.network-fabric.roles.spine.enable" | grep -q "true"; then
            if sudo vtysh -c "show ip ospf neighbor" > /dev/null 2>&1; then
                local ospf_neighbors=$(sudo vtysh -c "show ip ospf neighbor" | grep "Full" | wc -l)
                log INFO "  ✓ OSPF neighbors: $ospf_neighbors"
            else
                log WARN "  ⚠ OSPF not configured or no neighbors"
            fi
        fi
        
        # Check BGP neighbors
        if sudo vtysh -c "show ip bgp summary" > /dev/null 2>&1; then
            local bgp_neighbors=$(sudo vtysh -c "show ip bgp summary" | grep "Established" | wc -l)
            log INFO "  ✓ BGP neighbors: $bgp_neighbors"
        else
            log WARN "  ⚠ BGP not configured or no neighbors"
        fi
    else
        log ERROR "  ✗ FRR service is not running"
    fi
    
    # Check security services
    log INFO "Security Status:"
    
    # Check SSH
    if systemctl is-active --quiet sshd; then
        log SUCCESS "  ✓ SSH service is running"
    else
        log ERROR "  ✗ SSH service is not running"
    fi
    
    # Check firewall
    if systemctl is-active --quiet nftables; then
        log SUCCESS "  ✓ Firewall is active"
    else
        log ERROR "  ✗ Firewall is not active"
    fi
    
    # Check fail2ban
    if systemctl is-active --quiet fail2ban; then
        log SUCCESS "  ✓ Fail2ban is active"
        local banned_ips=$(sudo fail2ban-client status | grep "Banned" | wc -l)
        log INFO "  ✓ Banned IPs: $banned_ips"
    else
        log WARN "  ⚠ Fail2ban is not active"
    fi
    
    # Check fabric services
    log INFO "Fabric Services:"
    
    # Check fabric configuration directory
    if [ -d "/etc/nixos-fabric" ]; then
        log SUCCESS "  ✓ Fabric configuration directory exists"
    else
        log ERROR "  ✗ Fabric configuration directory not found"
    fi
    
    # Check role configuration
    if [ -f "/etc/nixos-fabric/roles" ]; then
        log SUCCESS "  ✓ Role configuration exists"
    else
        log WARN "  ⚠ Role configuration not found"
    fi
    
    # Network connectivity test
    log INFO "Network Connectivity:"
    
    # Test connectivity to other fabric nodes
    for target_host in "${TARGET_HOSTS[@]}"; do
        if [ "$target_host" != "$host" ]; then
            if ping -c 1 "$target_host" > /dev/null 2>&1; then
                log SUCCESS "  ✓ Can reach $target_host"
            else
                log WARN "  ⚠ Cannot reach $target_host"
            fi
        fi
    done
    
    log SUCCESS "Verification completed for $host"
}

# Main execution
main() {
    log INFO "=== NixOS Fabric Deployment and Verification ==="
    log INFO "Starting deployment process"
    log INFO "Target hosts: ${TARGET_HOSTS[*]}"
    log INFO "Dry run: $DRY_RUN"
    log INFO "Skip verification: $SKIP_VERIFICATION"
    log INFO "Verbose: $VERBOSE"
    log INFO "Log file: $DEPLOY_LOG"
    
    # Run deployment for each target host
    local overall_success=true
    
    for host in "${TARGET_HOSTS[@]}"; do
        log INFO "========================================"
        log INFO "Processing host: $host"
        log INFO "========================================"
        
        if ! deploy_host "$host"; then
            overall_success=false
            log ERROR "Deployment failed for $host"
        fi
        
        log INFO ""
    done
    
    # Summary
    log INFO "========================================"
    log INFO "Deployment Summary"
    log INFO "========================================"
    
    if [ "$overall_success" = true ]; then
        log SUCCESS "🎉 All deployments completed successfully!"
        log INFO "📊 Deployment log saved to: $DEPLOY_LOG"
        exit 0
    else
        log ERROR "❌ Some deployments failed"
        log INFO "📊 Detailed log available at: $DEPLOY_LOG"
        exit 1
    fi
}

# Run main function
main