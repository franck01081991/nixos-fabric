# Ansible Configuration for NixOS Fabric

## Overview

This directory contains Ansible playbooks, roles, and configurations for deploying and managing NixOS Fabric infrastructure.

## Structure

```
ansible/
├── inventories/         # Inventory files
│   ├── production/      # Production inventory
│   ├── staging/         # Staging inventory
│   └── development/     # Development inventory
│
├── playbooks/          # Playbooks
│   ├── deploy-fabric.yml # Main deployment playbook
│   ├── verify-fabric.yml # Verification playbook
│   └── roles/           # Role-specific playbooks
│
├── roles/              # Ansible roles
│   ├── common/          # Common configuration
│   ├── frr/             # FRR routing configuration
│   ├── wireguard/       # WireGuard VPN configuration
│   └── security/        # Security configuration
│
├── templates/          # Jinja2 templates
├── group_vars/          # Group variables
├── host_vars/           # Host-specific variables
├── ansible.cfg          # Ansible configuration
├── requirements.txt     # Python requirements
└── README.md            # This documentation
```

## Usage

### Basic Deployment

```bash
# Deploy to production
ansible-playbook -i inventories/production/hosts.ini playbooks/deploy-fabric.yml

# Verify deployment
ansible-playbook -i inventories/production/hosts.ini playbooks/verify-fabric.yml
```

### Development Workflow

```bash
# Test with development inventory
ansible-playbook -i inventories/development/hosts.ini playbooks/deploy-fabric.yml --check

# Deploy specific role
ansible-playbook -i inventories/development/hosts.ini playbooks/roles/deploy-wireguard-bgp.yml
```

## Inventory Structure

### Production Inventory Example

```ini
# inventories/production/hosts.ini

[spine]
rtr-sapinet ansible_host=192.168.1.100

[leaf]  
rtr-noisy ansible_host=192.168.1.101

[fabric:children]
spine
leaf

[fabric:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/nixos-fabric
fabric_environment=production
```

## Roles

### Common Role

The `common` role handles:
- Base system configuration
- Package installation
- User management
- Time synchronization
- System updates

### FRR Role

The `frr` role configures:
- FRR routing daemon
- BGP/OSPF protocols
- Routing security
- Interface configurations

### WireGuard Role

The `wireguard` role manages:
- WireGuard VPN tunnels
- Cryptographic keys
- Interface configurations
- Routing integration

### Security Role

The `security` role implements:
- Firewall rules
- SSH hardening
- System hardening
- Security monitoring

## Configuration

### Ansible Configuration

The `ansible.cfg` file contains default settings:

```ini
[defaults]
inventory = inventories/production/hosts.ini
remote_user = root
private_key_file = ~/.ssh/nixos-fabric
host_key_checking = False
retry_files_enabled = False

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false
```

### Variables

Variables are organized by:
- **Group variables**: `group_vars/` - Apply to groups of hosts
- **Host variables**: `host_vars/` - Apply to specific hosts
- **Role defaults**: In each role's `defaults/main.yml`

## Best Practices

### Inventory Management

1. **Use separate inventories** for different environments
2. **Group hosts logically** (spine, leaf, edge, etc.)
3. **Use variables** for environment-specific settings
4. **Keep inventory files** in version control

### Playbook Development

1. **Start with `--check`** mode for dry runs
2. **Use tags** for selective execution
3. **Test on development** before production
4. **Document playbooks** with clear comments

### Security

1. **Use SSH keys** instead of passwords
2. **Limit sudo access** in production
3. **Rotate credentials** regularly
4. **Audit changes** before deployment

## Testing

### Playbook Validation

```bash
# Syntax check
ansible-playbook --syntax-check playbooks/deploy-fabric.yml

# Dry run
ansible-playbook -i inventories/development/hosts.ini playbooks/deploy-fabric.yml --check

# Specific host
ansible-playbook -i inventories/development/hosts.ini playbooks/deploy-fabric.yml --limit rtr-noisy
```

### Role Testing

```bash
# Test specific role
ansible-playbook -i inventories/development/hosts.ini playbooks/roles/deploy-wireguard.yml

# Test with tags
ansible-playbook -i inventories/development/hosts.ini playbooks/deploy-fabric.yml --tags "wireguard,security"
```

## Integration with NixOS

Ansible works alongside NixOS:

1. **NixOS handles** declarative system configuration
2. **Ansible handles** deployment orchestration
3. **Together they provide** reproducible infrastructure

### Typical Workflow

```bash
# 1. Update NixOS configuration
nixos-rebuild switch --flake .#host-name

# 2. Deploy with Ansible
ansible-playbook -i inventories/production/hosts.ini playbooks/deploy-fabric.yml

# 3. Verify deployment
ansible-playbook -i inventories/production/hosts.ini playbooks/verify-fabric.yml
```

## Troubleshooting

### Common Issues

**Connection problems:**
- Verify SSH keys and permissions
- Check firewall rules on target hosts
- Test manual SSH connection first

**Playbook failures:**
- Use `-v` for verbose output
- Check Ansible logs
- Test individual tasks

**Role conflicts:**
- Review role dependencies
- Check variable precedence
- Test roles individually

### Debugging Commands

```bash
# Verbose output
ansible-playbook -vvv -i inventory playbook.yml

# Specific task debugging
ansible -i inventory host -m debug -a "var=hostvars[inventory_hostname]"

# Check facts
ansible -i inventory host -m setup
```

## Contributing

Contributions to Ansible configurations are welcome!

### Guidelines

1. **Follow existing patterns** for consistency
2. **Document new roles** and playbooks
3. **Add tests** for new functionality
4. **Update documentation** for changes
5. **Test thoroughly** before submitting

### Areas for Contribution

- Additional roles for new services
- Improved error handling
- Better testing frameworks
- Enhanced documentation
- Performance optimizations

## License

This Ansible configuration is licensed under the MIT License.

## Support

For Ansible-specific issues, please open a GitHub issue with the `ansible` tag.