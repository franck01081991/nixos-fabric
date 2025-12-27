# Ansible Integration for NixOS Fabric

This directory contains Ansible playbooks and roles for managing the NixOS fabric infrastructure.

## Structure

```
ansible/
├── inventory/          # Inventory files
├── playbooks/          # Main playbooks
├── roles/              # Ansible roles
│   ├── wireguard/      # WireGuard configuration
│   ├── frr/            # FRR routing setup
│   ├── networking/     # Network configuration
│   ├── security/       # Security hardening
│   └── monitoring/     # Monitoring setup
├── group_vars/         # Group variables
├── host_vars/          # Host-specific variables
└── ansible.cfg         # Ansible configuration
```

## Usage

### Basic Commands

```bash
# Run all playbooks
ansible-playbook playbooks/main.yml

# Run specific playbook
ansible-playbook playbooks/wireguard.yml

# Check connectivity
ansible all -m ping
```

### Inventory

The inventory is automatically generated from the NixOS hosts directory.

### Integration with NixOS

Ansible is used for:
- Initial provisioning
- Configuration management
- Idempotent operations
- Tasks not well-suited for Nix

NixOS remains the primary configuration management system.
