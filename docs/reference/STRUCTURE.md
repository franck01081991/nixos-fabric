# NixOS Fabric Repository Structure (Updated)

## Overview

This document describes the **new organized structure** of the NixOS Fabric repository after the reorganization. The structure follows best practices for clarity, maintainability, and scalability.

## Repository Organization

```
nixos-fabric/
├── modules/                  # Core NixOS modules (REORGANIZED)
│   ├── core/                 # Core modules
│   │   ├── network-fabric.nix # Main fabric module
│   │   ├── base.nix           # Base configuration
│   │   └── lib.nix            # Utility functions
│   │
│   ├── networking/          # Networking modules
│   │   ├── frr.nix           # FRR routing
│   │   ├── wireguard.nix      # WireGuard VPN
│   │   ├── networking.nix     # Network configuration
│   │   └── roles/            # Network roles (spine, leaf, etc.)
│   │
│   ├── security/            # Security modules (CONSOLIDATED)
│   │   ├── init.nix          # Main entry point
│   │   ├── index.nix         # Module documentation
│   │   ├── default.nix       # Core security
│   │   ├── firewall.nix      # Firewall rules
│   │   ├── hardening.nix     # System hardening
│   │   ├── ssh.nix           # SSH security
│   │   ├── nftables-advanced.nix # Advanced firewall
│   │   ├── network-security.nix # Network security integration
│   │   └── README.md        # Comprehensive documentation
│   │
│   ├── integration/         # Integration modules
│   │   ├── ansible.nix       # Ansible integration
│   │   └── monitoring.nix    # Monitoring integration
│   │
│   └── utils/               # Utility modules
│       ├── lib/              # Library functions
│       ├── ci-bootless.nix   # CI utilities
│       └── dynamic.nix       # Dynamic configuration
│
├── hosts/                   # Host configurations (REORGANIZED)
│   ├── production/          # Production environment
│   │   ├── spine/           # Spine routers
│   │   ├── leaf/            # Leaf routers
│   │   └── edge/            # Edge routers
│   │
│   ├── staging/            # Staging environment
│   ├── development/         # Development environment
│   ├── roles/               # Host roles
│   └── templates/           # Configuration templates
│
├── ansible/                 # Ansible configuration (SIMPLIFIED)
│   ├── inventories/         # Inventory files
│   │   ├── production/      # Production inventory
│   │   ├── staging/         # Staging inventory
│   │   └── development/     # Development inventory
│   │
│   ├── playbooks/          # Playbooks
│   │   ├── deploy-fabric.yml # Main deployment
│   │   ├── verify-fabric.yml # Verification
│   │   └── roles/           # Role-specific playbooks
│   │
│   ├── roles/              # Ansible roles
│   │   ├── common/          # Common configuration
│   │   ├── frr/             # FRR routing
│   │   ├── wireguard/       # WireGuard VPN
│   │   └── security/        # Security configuration
│   │
│   ├── templates/          # Jinja2 templates
│   ├── group_vars/          # Group variables
│   ├── host_vars/           # Host variables
│   ├── ansible.cfg          # Configuration
│   ├── requirements.txt     # Requirements
│   └── README.md            # Ansible documentation
│
├── examples/                # Configuration examples
│   ├── basic-fabric.nix     # Basic fabric example
│   ├── secure-fabric.nix    # Secure fabric example
│   ├── wireguard-bgp.nix    # WireGuard + BGP
│   └── spine-leaf.nix       # Spine-leaf architecture
│
├── tests/                   # Tests (REORGANIZED)
│   ├── unit/                # Unit tests
│   │   ├── modules/         # Module tests
│   │   └── utils/           # Utility tests
│   │
│   ├── integration/        # Integration tests
│   │   ├── fabric/          # Fabric tests
│   │   └── scenarios/       # Scenario tests
│   │
│   ├── vm/                 # VM tests
│   │   ├── configurations/  # Test configs
│   │   └── test-vm.nix      # Main VM test
│   │
│   ├── scripts/            # Test scripts
│   └── README.md            # Test documentation
│
├── docs/                    # Documentation (CONSOLIDATED)
│   ├── architecture/        # Architecture docs
│   ├── modules/             # Module documentation
│   ├── deployment/          # Deployment guides
│   ├── security/            # Security documentation
│   ├── development/         # Development guides
│   ├── examples/            # Documented examples
│   └── README.md            # Documentation index
│
├── scripts/                 # Utility scripts
│   ├── deployment/          # Deployment scripts
│   ├── development/         # Development scripts
│   ├── testing/             # Test scripts
│   └── README.md            # Script documentation
│
├── external/                # External configurations
│   └── README.md            # External configs documentation
│
├── .github/                 # GitHub configuration
│   └── workflows/           # CI/CD workflows
│
├── .vscode/                 # VSCode configuration
│   └── settings.json        # Recommended settings
│
└── root files               # Root files
    ├── README.md            # Main README
    ├── STRUCTURE.md         # Structure documentation
    ├── CONTRIBUTING.md      # Contribution guide
    ├── LICENSE              # License
    ├── flake.nix            # Nix flake
    ├── flake.lock           # Flake lockfile
    └── .gitignore           # Git ignore
```

## Key Improvements

### 1. Module Organization

**Before**: Modules mixed in root with inconsistent subdirectories
**After**: Clear hierarchical structure by functional domain

```
modules/
├── core/       # Foundation modules
├── networking/ # All networking-related
├── security/   # All security-related (consolidated)
├── integration/# Integration with other tools
└── utils/      # Utility functions
```

### 2. Security Consolidation

**Before**: `security/` and `security-improved/` with duplication
**After**: Single unified security module with comprehensive features

### 3. Ansible Simplification

**Before**: `.ansible/` and `ansible/` with duplication
**After**: Single `ansible/` directory with standard structure

### 4. Test Organization

**Before**: Tests mixed with other files
**After**: Clear separation by test type (unit, integration, vm)

### 5. Documentation Centralization

**Before**: Documentation scattered across repository
**After**: Centralized in `docs/` with clear structure

## Module Structure Details

### Core Modules

```
modules/core/
├── network-fabric.nix # Main fabric module
├── base.nix           # Base system configuration
└── lib.nix            # Core utility functions
```

### Networking Modules

```
modules/networking/
├── frr.nix           # FRR routing daemon
├── wireguard.nix      # WireGuard VPN
├── networking.nix     # General networking
└── roles/            # Network roles
    ├── spine.nix     # Spine router role
    ├── leaf.nix      # Leaf router role
    ├── generic.nix   # Generic role
    └── ...           # Other roles
```

### Security Modules

```
modules/security/
├── init.nix          # Main entry point (imports all)
├── index.nix         # Documentation index
├── default.nix       # Core security module
├── firewall.nix      # Firewall configuration
├── hardening.nix     # System hardening
├── ssh.nix           # SSH security
├── nftables-advanced.nix # Advanced firewall rules
├── network-security.nix # Network security integration
└── README.md        # Comprehensive documentation
```

## Configuration Hierarchy

### Recommended Import Order

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    # 1. Core modules (foundation)
    ../modules/core/network-fabric.nix
    ../modules/core/base.nix
    
    # 2. Feature modules (domain-specific)
    ../modules/networking/frr.nix
    ../modules/networking/wireguard.nix
    ../modules/security/init.nix  # Imports all security modules
    
    # 3. Integration modules (cross-domain)
    ../modules/integration/ansible.nix
    
    # 4. Utility modules (helpers)
    ../modules/utils/lib.nix
    
    # 5. Host-specific overrides
    ./host-config.nix
    
    # 6. Environment-specific settings
    ./environment/${config.network-fabric.environment}.nix
  ];
}
```

## Usage Examples

### Basic Fabric Configuration

```nix
{ config, pkgs, ... }:

{
  imports = [
    ../modules/core/network-fabric.nix
    ../modules/networking/wireguard.nix
    ../modules/security/init.nix
  ];
  
  network-fabric = {
    name = "my-fabric";
    environment = "production";
    
    wireguard = {
      enable = true;
      peers = [
        {
          name = "peer1";
          publicKey = "...";
          allowedIPs = [ "10.0.0.2/32" ];
        }
      ];
    };
    
    security = {
      enable = true;
      firewall = {
        allowedTCP = [ 22 51820 ];
      };
    };
  };
}
```

### Advanced Configuration with Roles

```nix
{ config, pkgs, ... }:

{
  imports = [
    ../modules/core/network-fabric.nix
    ../modules/networking/roles/spine.nix
    ../modules/security/init.nix
  ];
  
  network-fabric = {
    name = "spine-router";
    role = "spine";
    
    frr = {
      enable = true;
      bgp = {
        as = 65000;
        neighbors = {
          leaf1 = { ip = "10.255.0.1"; as = 65001; };
        };
      };
    };
    
    security = {
      enable = true;
      ssh = {
        port = 2222;
        passwordAuthentication = false;
      };
    };
  };
}
```

## Best Practices

### Module Development

1. **Single Responsibility**: Each module should do one thing well
2. **Clear Interfaces**: Well-defined options and outputs
3. **Sensible Defaults**: Secure and functional defaults
4. **Comprehensive Documentation**: Complete usage examples
5. **Backward Compatibility**: Maintain compatibility when possible

### Configuration Management

1. **Use Imports**: Import modules rather than copying code
2. **Layer Configurations**: Separate global, host, and environment configs
3. **Enable Features Explicitly**: Opt-in rather than opt-out
4. **Use Descriptive Names**: Clear and meaningful option names
5. **Document Assumptions**: Explain configuration requirements

### File Organization

1. **Keep related files together**: Group by functional domain
2. **Use consistent naming**: Follow established patterns
3. **Document structure**: Keep documentation updated
4. **Avoid duplication**: Reuse existing modules
5. **Keep it simple**: Prefer simplicity over complexity

## Migration Guide

### From Old Structure

If migrating from the old structure:

1. **Update import paths** to reflect new organization
2. **Consolidate security configurations** into new security module
3. **Move Ansible configurations** to new structure
4. **Update test references** to new locations
5. **Review documentation** for accuracy

### Example Migration

**Old import**:
```nix
imports = [
  ../modules/network-fabric.nix
  ../modules/security/default.nix
  ../modules/security/firewall.nix
  ../modules/wireguard.nix
];
```

**New import**:
```nix
imports = [
  ../modules/core/network-fabric.nix
  ../modules/security/init.nix  # Imports all security modules
  ../modules/networking/wireguard.nix
];
```

## Contribution Guidelines

See `CONTRIBUTING.md` for detailed contribution guidelines including:

- Code style standards
- Commit message conventions
- Pull request process
- Testing requirements
- Documentation standards

## License

This project is licensed under the MIT License. See `LICENSE` for details.

## Support

For questions about the new structure:

- **GitHub Issues**: For structure-related questions
- **Discussions**: For general architecture discussions
- **Documentation**: Check updated documentation in `docs/`

---

**Last Updated**: 2024-07-25
**Structure Version**: 2.0 (Organized)
**Maintainer**: Franck
**License**: MIT