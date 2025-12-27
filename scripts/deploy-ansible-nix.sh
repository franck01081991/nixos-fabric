#!/usr/bin/env bash
set -euo pipefail

# Deploy Ansible configuration using Nix integration
# Usage: ./scripts/deploy-ansible-nix.sh [host]

TARGET="${1:-rtr-sapinet}"

echo "=== Deploying Ansible configuration via Nix ==="
echo "Target: $TARGET"
echo "Date: $(date)"
echo

# Build and switch NixOS configuration with Ansible enabled
echo "Building NixOS configuration with Ansible..."
sudo nixos-rebuild switch --flake ".#$TARGET" --option sandbox false
echo

# The Ansible configuration will be generated automatically by the Nix module
# Check that Ansible is installed
echo "Verifying Ansible installation..."
if command -v ansible >/dev/null 2>&1; then
    echo "✓ Ansible is installed: $(ansible --version | head -n 1)"
else
    echo "✗ Ansible not found. The Nix module should have installed it."
    exit 1
fi
echo

# Check Ansible configuration
echo "Checking Ansible configuration..."
if [ -f "/etc/nixos-fabric/ansible/ansible.cfg" ]; then
    echo "✓ Ansible configuration found"
    grep "^inventory" /etc/nixos-fabric/ansible/ansible.cfg
else
    echo "✗ Ansible configuration not found"
    exit 1
fi
echo

# Check inventory
echo "Checking Ansible inventory..."
if [ -f "/etc/nixos-fabric/ansible/inventory/hosts.ini" ]; then
    echo "✓ Ansible inventory found"
    grep "^\[" /etc/nixos-fabric/ansible/inventory/hosts.ini
else
    echo "✗ Ansible inventory not found"
    exit 1
fi
echo

# Test Ansible connectivity
echo "Testing Ansible connectivity..."
if ansible all -m ping --inventory /etc/nixos-fabric/ansible/inventory/hosts.ini; then
    echo "✓ Ansible connectivity successful"
else
    echo "✗ Ansible connectivity failed"
    exit 1
fi
echo

# Run Ansible playbooks
echo "Running Ansible playbooks..."
for playbook in main.yml verify-fabric.yml; do
    if [ -f "/etc/nixos-fabric/ansible/playbooks/$playbook" ]; then
        echo "Running playbook: $playbook"
        ansible-playbook \
            --inventory /etc/nixos-fabric/ansible/inventory/hosts.ini \
            "/etc/nixos-fabric/ansible/playbooks/$playbook"
        echo
    else
        echo "Playbook not found: $playbook"
    fi
done

echo "=== Ansible Deployment Complete ==="
