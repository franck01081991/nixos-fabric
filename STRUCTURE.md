# NixOS Fabric Repository Structure

This document provides an overview of the repository structure and organization.

## Repository Organization

```
nixos-fabric/
├── modules/                  # Core NixOS modules
│   ├── security/             # Security module (organized)
│   │   ├── init.nix          # Main entry point
│   │   ├── index.nix         # Module reference
│   │   ├── default.nix       # Core security module
│   │   └── README.md        # Documentation
│   ├── networking.nix        # Network configuration
│   ├── firewall.nix          # Firewall rules
│   ├── ssh.nix               # SSH configuration
│   ├── wireguard.nix         # WireGuard VPN
│   ├── frr.nix               # FRR routing
│   ├── ansible.nix           # Ansible integration
│   ├── lib/                  # Utility functions
│   └── network-fabric.nix    # Main fabric module
│
├── examples/                # Configuration examples
│   ├── security-example.nix  # Security module example
│   └── ...                   # Other examples
│
├── tests/                   # Test suite
│   ├── modules/              # Module tests
│   ├── test-security-module.nix  # Security tests
│   ├── vm-test-config.nix    # VM test configuration
│   └── run-tests.sh          # Test runner
│
├── hosts/                   # Host configurations
│   ├── host1/                # Host-specific configs
│   ├── host2/                # Host-specific configs
│   └── ...                   # Other hosts
│
├── docs/                    # Documentation
│   ├── architecture/         # Architecture docs
│   ├── deployment/           # Deployment guides
│   └── development/          # Development docs
│
├── scripts/                 # Utility scripts
│   ├── deploy.sh             # Deployment scripts
│   ├── setup.sh              # Setup scripts
│   └── ...                   # Other scripts
│
├── external/                # External configurations
│   └── ...                   # External host configs
│
├── .github/                 # GitHub configuration
│   └── workflows/            # CI/CD workflows
│
├── STRUCTURE.md             # This file
├── README.md                # Main README
├── CONTRIBUTING.md          # Contribution guide
├── LICENSE                  # License information
└── flake.nix                # Nix flake configuration
```

## Module Structure

### Security Module

The security module is organized as a submodule with clear entry points:

```
modules/security/
├── init.nix          # Main entry point (import this)
├── index.nix         # Module documentation and reference
├── default.nix       # Core security implementation
└── README.md        # Comprehensive documentation
```

**Usage:**
```nix
imports = [ ../modules/security/init.nix ];
```

### Network Fabric Module

The main fabric module that ties everything together:

```nix
network-fabric = {
  enable = true;
  name = "production-fabric";
  environment = "production";
  
  security = { ... };      # Security configuration
  networking = { ... };    # Network configuration
  wireguard = { ... };     # WireGuard VPN
  frr = { ... };           # FRR routing
  ansible = { ... };       # Ansible integration
};
```

## Configuration Hierarchy

1. **Global Configuration** (`modules/network-fabric.nix`)
   - Main fabric settings
   - Module integration
   - Default values

2. **Feature Modules** (`modules/*.nix`)
   - Security
   - Networking
   - WireGuard
   - FRR
   - Ansible

3. **Host Configurations** (`hosts/*/`)
   - Host-specific settings
   - Environment variables
   - Hardware configurations

4. **Examples** (`examples/*.nix`)
   - Reference configurations
   - Best practices
   - Testing templates

## Import Conventions

### Recommended Import Order

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    # 1. Core modules
    ../modules/network-fabric.nix
    
    # 2. Feature modules
    ../modules/security/init.nix
    ../modules/wireguard.nix
    ../modules/frr.nix
    
    # 3. Integration modules
    ../modules/ansible.nix
    
    # 4. Host-specific overrides
    ./host-config.nix
    
    # 5. Environment-specific settings
    ./environment/${config.network-fabric.environment}.nix
  ];

  # Configuration follows...
}
```

## Naming Conventions

### Module Files
- `default.nix` - Main module implementation
- `init.nix` - Entry point for submodules
- `index.nix` - Documentation and reference
- `README.md` - Comprehensive documentation

### Configuration Options
- `network-fabric.*` - Main fabric namespace
- `network-fabric.security.*` - Security configurations
- `network-fabric.networking.*` - Network configurations
- `services.*` - Service configurations
- `security.*` - System security settings

### Variable Naming
- `cfg` - Configuration object
- `lib` - Nix library functions
- `pkgs` - Nix packages
- `options` - Module options
- `config` - Final configuration

## Documentation Standards

### Module Documentation
Each module should include:

1. **Purpose** - What the module does
2. **Features** - List of available features
3. **Usage** - Basic and advanced examples
4. **Options** - Configuration reference
5. **Integration** - How it works with other modules

### Code Comments
- **Function-level** comments for major functions
- **Section-level** comments for configuration blocks
- **Inline comments** for complex logic
- **TODO comments** for future improvements

## Testing Structure

### Test Organization

```
tests/
├── modules/              # Individual module tests
│   ├── security/          # Security module tests
│   ├── networking/        # Networking tests
│   └── ...                # Other module tests
│
├── integration/          # Integration tests
│   ├── fabric-test.nix    # Full fabric tests
│   └── ...                # Other integration tests
│
├── vm-test-config.nix    # VM test configuration
├── test-security-module.nix  # Security test suite
├── run-tests.sh          # Test runner script
└── TESTING_SUMMARY.md    # Testing documentation
```

### Test Conventions
- **Unit Tests** - Test individual modules
- **Integration Tests** - Test module interactions
- **VM Tests** - Test in real NixOS environment
- **Documentation Tests** - Verify examples work

## Best Practices

### Module Development
1. **Single Responsibility** - Each module should do one thing well
2. **Clear Interfaces** - Well-defined options and outputs
3. **Sensible Defaults** - Secure and functional defaults
4. **Comprehensive Documentation** - Complete usage examples
5. **Backward Compatibility** - Maintain compatibility when possible

### Configuration Management
1. **Use Imports** - Import modules rather than copying code
2. **Layer Configurations** - Separate global, host, and environment configs
3. **Enable Features Explicitly** - Opt-in rather than opt-out
4. **Use Descriptive Names** - Clear and meaningful option names
5. **Document Assumptions** - Explain configuration requirements

## Contribution Guidelines

See `CONTRIBUTING.md` for detailed contribution guidelines including:
- Code style standards
- Commit message conventions
- Pull request process
- Testing requirements
- Documentation standards

## License

This project is licensed under the MIT License. See `LICENSE` for details.