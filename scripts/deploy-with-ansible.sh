#!/usr/bin/env bash
set -euo pipefail

# Deploy NixOS Fabric with Ansible
# Usage: ./scripts/deploy-with-ansible.sh [host|all]

TARGET="${1:-all}"

echo "=== NixOS Fabric Deployment with Ansible ==="
echo "Target: $TARGET"
echo "Date: $(date)"
echo

# Generate Ansible inventory
echo "Generating Ansible inventory..."
./scripts/generate-ansible-inventory.sh
echo

# Test connectivity
echo "Testing Ansible connectivity..."
ansible $TARGET -m ping
echo

# Run Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook ansible/playbooks/main.yml --limit "$TARGET"
echo

# Verify deployment
echo "Verifying deployment..."
ansible-playbook ansible/playbooks/verify-fabric.yml --limit "$TARGET"
echo

echo "=== Deployment Complete ==="
