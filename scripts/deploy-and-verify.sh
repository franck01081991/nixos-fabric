#!/usr/bin/env bash
set -euo pipefail

# Fabric Deployment and Verification Script
# This script helps deploy and verify the NixOS fabric configuration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== NixOS Fabric Deployment and Verification ===${NC}"
echo

# Check if we're in the right directory
if [ ! -d "hosts" ] || [ ! -f "flake.nix" ]; then
    echo -e "${RED}Error: This script must be run from the nixos-fabric repository root${NC}"
    exit 1
fi

# Function to deploy a host
deploy_host() {
    local host=$1
    echo -e "${YELLOW}Deploying $host...${NC}"
    
    if sudo nixos-rebuild switch --flake ".#$host"; then
        echo -e "${GREEN}✓ Successfully deployed $host${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to deploy $host${NC}"
        return 1
    fi
}

# Function to verify a host
verify_host() {
    local host=$1
    echo -e "${YELLOW}Verifying $host...${NC}"
    
    # Check WireGuard
    if ip link show wgtransport > /dev/null 2>&1; then
        echo -e "${GREEN}✓ WireGuard interface exists${NC}"
        sudo wg show wgtransport || echo "  (No peers yet)"
    else
        echo -e "${RED}✗ WireGuard interface not found${NC}"
    fi
    
    # Check routes
    echo -e "${YELLOW}Fabric routes:${NC}"
    ip route | grep -E "(10.255|10.254)" || echo "  (No fabric routes)"
    
    # Check FRR if applicable
    if [ "$host" = "sapinet" ]; then
        if systemctl is-active --quiet frr; then
            echo -e "${GREEN}✓ FRR service is running${NC}"
            if command -v vtysh > /dev/null 2>&1; then
                echo -e "${YELLOW}BGP Summary:${NC}"
                vtysh -c "show ip bgp summary" || echo "  (BGP not configured)"
                echo -e "${YELLOW}OSPF Neighbors:${NC}"
                vtysh -c "show ip ospf neighbor" || echo "  (OSPF not configured)"
            fi
        else
            echo -e "${RED}✗ FRR service not running${NC}"
        fi
    fi
    
    # Check connectivity
    echo -e "${YELLOW}Peer connectivity:${NC}"
    for peer in "10.255.0.1" "10.255.0.2" "10.254.0.1" "10.254.0.2"; do
        if ping -c 1 -W 1 "$peer" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ $peer is reachable${NC}"
        else
            echo -e "  ${RED}✗ $peer is not reachable${NC}"
        fi
    done
}

# Main menu
while true; do
    echo
    echo -e "${YELLOW}Menu:${NC}"
    echo "1. Deploy sapinet"
    echo "2. Deploy noisy-edge1"
    echo "3. Verify sapinet"
    echo "4. Verify noisy-edge1"
    echo "5. Full deployment (both hosts)"
    echo "6. Full verification (both hosts)"
    echo "7. Exit"
    echo
    read -p "Choose an option [1-7]: " choice
    
    case $choice in
        1) deploy_host "sapinet" ;;
        2) deploy_host "noisy-edge1" ;;
        3) verify_host "sapinet" ;;
        4) verify_host "noisy-edge1" ;;
        5)
            deploy_host "sapinet" && deploy_host "noisy-edge1"
            echo -e "${GREEN}✓ Full deployment completed${NC}"
            ;;
        6)
            verify_host "sapinet"
            echo
            verify_host "noisy-edge1"
            echo -e "${GREEN}✓ Full verification completed${NC}"
            ;;
        7)
            echo -e "${YELLOW}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done
