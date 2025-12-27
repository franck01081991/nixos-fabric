#!/usr/bin/env bash
set -euo pipefail

# Setup Ansible for NixOS Fabric
# Usage: ./scripts/setup-ansible.sh

echo "=== Setting up Ansible for NixOS Fabric ==="
echo "Date: $(date)"
echo

# Check if running on NixOS
if [ -f /etc/nixos/configuration.nix ]; then
    echo "Detected NixOS system"
    
    # Install Ansible using Nix
    echo "Installing Ansible via Nix..."
    if ! command -v ansible >/dev/null 2>&1; then
        nix-env -iA nixos.ansible
    else
        echo "Ansible is already installed"
    fi
    
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        nix-env -iA nixos.ansible
    else
        echo "ansible-playbook is already installed"
    fi
else
    echo "Non-NixOS system detected"
    
    # Install Ansible using pip
    if command -v python3 >/dev/null 2>&1; then
        echo "Installing Ansible via pip..."
        pip3 install --user ansible ansible-core
    elif command -v python >/dev/null 2>&1; then
        echo "Installing Ansible via pip..."
        pip install --user ansible ansible-core
    else
        echo "ERROR: Python not found. Please install Python first."
        exit 1
    fi
fi

# Verify installation
echo
echo "Verifying Ansible installation..."
ansible --version
ansible-playbook --version

# Setup Ansible configuration
echo
echo "Setting up Ansible configuration..."
mkdir -p ansible/inventory
cp ansible/ansible.cfg ansible/ansible.cfg.bak 2>/dev/null || true

# Generate initial inventory
echo
echo "Generating initial Ansible inventory..."
./scripts/generate-ansible-inventory.sh

echo
echo "=== Ansible Setup Complete ==="
echo
echo "Next steps:"
echo "1. Edit ansible/inventory/hosts.ini with your host IPs"
echo "2. Test connectivity: ansible all -m ping"
echo "3. Run playbooks: ./scripts/deploy-with-ansible.sh"
