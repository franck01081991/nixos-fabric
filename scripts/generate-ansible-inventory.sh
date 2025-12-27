#!/usr/bin/env bash
set -euo pipefail

# Generate Ansible inventory from NixOS hosts
# Usage: ./scripts/generate-ansible-inventory.sh

INVENTORY_FILE="ansible/inventory/hosts.ini"

echo "Generating Ansible inventory from NixOS hosts..."

# Start with header
echo "[spine]" > "$INVENTORY_FILE"
echo "[leaf]" >> "$INVENTORY_FILE"
echo "[hybrid:children]" >> "$INVENTORY_FILE"
echo "spine" >> "$INVENTORY_FILE"
echo "leaf" >> "$INVENTORY_FILE"
echo "" >> "$INVENTORY_FILE"
echo "[all:vars]" >> "$INVENTORY_FILE"
echo "ansible_python_interpreter=/run/current-system/sw/bin/python3" >> "$INVENTORY_FILE"
echo "" >> "$INVENTORY_FILE"

# Process each host
for host_dir in hosts/*/; do
    host_name=$(basename "$host_dir")
    
    # Check if host has role variables
    if [ -f "$host_dir/role-variables.nix" ]; then
        # Check for spine role
        if grep -q "spine.enable = true" "$host_dir/role-variables.nix"; then
            echo "$host_name" >> "$INVENTORY_FILE"
        fi
        
        # Check for leaf role
        if grep -q "leaf.enable = true" "$host_dir/role-variables.nix"; then
            echo "$host_name" >> "$INVENTORY_FILE"
        fi
    fi
    
    # Add host-specific variables
    if [ -f "$host_dir/variables.nix" ]; then
        # Extract IP address if available
        ip_address=$(grep -oP 'publicIp = "\K[^"]+' "$host_dir/variables.nix" 2>/dev/null || echo "HOST_IP_$host_name")
        echo "$host_name ansible_host=$ip_address" >> "$INVENTORY_FILE"
    fi
done

echo "Ansible inventory generated at $INVENTORY_FILE"
