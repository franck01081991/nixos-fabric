#!/bin/bash
# Bidirectional synchronization script for host configurations

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Please run this script from the repository root"
    exit 1
fi

# Function to sync from external to local
sync_from_external() {
    echo -e "${YELLOW}🔄 Synchronizing from external to local...${NC}"
    
    # Check if external configs exist
    if [ ! -d "external/rtr-sapinet-config" ]; then
        echo -e "${RED}❌ External rtr-sapinet-config not found${NC}"
        return 1
    fi
    
    if [ ! -d "external/rtr-noisy-config" ]; then
        echo -e "${RED}❌ External rtr-noisy-config not found${NC}"
        return 1
    fi
    
    # Create hosts directory if it doesn't exist
    mkdir -p hosts
    
    # Sync rtr-sapinet
    echo -e "${GREEN}✓ Syncing rtr-sapinet...${NC}"
    cp -r external/rtr-sapinet-config/* hosts/rtr-sapinet/ 2>/dev/null || cp -r external/rtr-sapinet-config hosts/rtr-sapinet
    
    # Sync rtr-noisy
    echo -e "${GREEN}✓ Syncing rtr-noisy...${NC}"
    cp -r external/rtr-noisy-config/* hosts/rtr-noisy/ 2>/dev/null || cp -r external/rtr-noisy-config hosts/rtr-noisy
    
    echo -e "${GREEN}✅ Synchronization from external completed!${NC}"
    echo "Run 'git add hosts/ && git commit' to commit changes"
}

# Function to sync from local to external
sync_to_external() {
    echo -e "${YELLOW}🔄 Synchronizing from local to external...${NC}"
    
    # Check if local configs exist
    if [ ! -d "hosts/rtr-sapinet" ]; then
        echo -e "${RED}❌ Local rtr-sapinet not found${NC}"
        return 1
    fi
    
    if [ ! -d "hosts/rtr-noisy" ]; then
        echo -e "${RED}❌ Local rtr-noisy not found${NC}"
        return 1
    fi
    
    # Create external directory if it doesn't exist
    mkdir -p external
    
    # Sync rtr-sapinet
    echo -e "${GREEN}✓ Syncing rtr-sapinet...${NC}"
    cp -r hosts/rtr-sapinet/* external/rtr-sapinet-config/
    
    # Sync rtr-noisy
    echo -e "${GREEN}✓ Syncing rtr-noisy...${NC}"
    cp -r hosts/rtr-noisy/* external/rtr-noisy-config/
    
    echo -e "${GREEN}✅ Synchronization to external completed!${NC}"
    echo "Run 'git add external/ && git commit' to commit submodule changes"
}

# Function to sync both directions (smart sync)
sync_both() {
    echo -e "${YELLOW}🔄 Smart bidirectional synchronization...${NC}"
    
    # Get timestamps to determine which is newer
    local_sapinet_time=$(stat -c %Y hosts/rtr-sapinet/role-variables.nix 2>/dev/null || echo "0")
    external_sapinet_time=$(stat -c %Y external/rtr-sapinet-config/role-variables.nix 2>/dev/null || echo "0")
    
    local_noisy_time=$(stat -c %Y hosts/rtr-noisy/role-variables.nix 2>/dev/null || echo "0")
    external_noisy_time=$(stat -c %Y external/rtr-noisy-config/role-variables.nix 2>/dev/null || echo "0")
    
    # Sync based on which is newer
    if [ "$local_sapinet_time" -gt "$external_sapinet_time" ]; then
        echo -e "${GREEN}→ Local rtr-sapinet is newer, syncing to external${NC}"
        cp -r hosts/rtr-sapinet/* external/rtr-sapinet-config/
    elif [ "$external_sapinet_time" -gt "$local_sapinet_time" ]; then
        echo -e "${GREEN}← External rtr-sapinet is newer, syncing to local${NC}"
        cp -r external/rtr-sapinet-config/* hosts/rtr-sapinet/
    else
        echo -e "${YELLOW}⏸ rtr-sapinet: Both versions are identical${NC}"
    fi
    
    if [ "$local_noisy_time" -gt "$external_noisy_time" ]; then
        echo -e "${GREEN}→ Local rtr-noisy is newer, syncing to external${NC}"
        cp -r hosts/rtr-noisy/* external/rtr-noisy-config/
    elif [ "$external_noisy_time" -gt "$local_noisy_time" ]; then
        echo -e "${GREEN}← External rtr-noisy is newer, syncing to local${NC}"
        cp -r external/rtr-noisy-config/* hosts/rtr-noisy/
    else
        echo -e "${YELLOW}⏸ rtr-noisy: Both versions are identical${NC}"
    fi
    
    echo -e "${GREEN}✅ Smart synchronization completed!${NC}"
}

# Function to check sync status
check_status() {
    echo -e "${YELLOW}🔍 Checking synchronization status...${NC}"
    
    # Check if files exist
    if [ ! -f "hosts/rtr-sapinet/role-variables.nix" ] || [ ! -f "external/rtr-sapinet-config/role-variables.nix" ]; then
        echo -e "${RED}❌ Missing configuration files${NC}"
        return 1
    fi
    
    # Compare files
    if diff -q hosts/rtr-sapinet/role-variables.nix external/rtr-sapinet-config/role-variables.nix >/dev/null; then
        echo -e "${GREEN}✓ rtr-sapinet: IN SYNC${NC}"
    else
        echo -e "${RED}✗ rtr-sapinet: OUT OF SYNC${NC}"
    fi
    
    if diff -q hosts/rtr-noisy/role-variables.nix external/rtr-noisy-config/role-variables.nix >/dev/null; then
        echo -e "${GREEN}✓ rtr-noisy: IN SYNC${NC}"
    else
        echo -e "${RED}✗ rtr-noisy: OUT OF SYNC${NC}"
    fi
}

# Main script logic
case "$1" in
    "from-external")
        sync_from_external
        ;;
    "to-external")
        sync_to_external
        ;;
    "both"|"smart")
        sync_both
        ;;
    "status"|"check")
        check_status
        ;;
    *)
        echo "Usage: $0 [from-external|to-external|both|status]"
        echo ""
        echo "Examples:"
        echo "  $0 from-external  # Pull changes from external to local"
        echo "  $0 to-external    # Push changes from local to external"
        echo "  $0 both           # Smart sync in both directions"
        echo "  $0 status         # Check synchronization status"
        exit 1
        ;;
esac