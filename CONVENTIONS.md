# NixOS Fabric Naming and Coding Conventions

This document establishes consistent naming and coding conventions for the NixOS Fabric project to ensure code readability, maintainability, and consistency across the repository.

## Table of Contents

1. [File and Directory Naming](#file-and-directory-naming)
2. [Module Structure](#module-structure)
3. [Nix Code Conventions](#nix-code-conventions)
4. [Configuration Options](#configuration-options)
5. [Variable Naming](#variable-naming)
6. [Commenting Standards](#commenting-standards)
7. [Documentation Standards](#documentation-standards)
8. [Import Conventions](#import-conventions)
9. [Test Organization](#test-organization)

## File and Directory Naming

### Directory Structure

```
✅ GOOD
modules/
├── security/          # Module subdirectory
│   ├── init.nix       # Entry point
│   ├── default.nix    # Implementation
│   ├── index.nix      # Reference
│   └── README.md     # Documentation
├── networking.nix     # Single module file
└── utils.nix          # Utility functions

❌ AVOID
modules/
├── security_module/   # Too verbose
├── sec/              # Too abbreviated
├── Security/         # Inconsistent case
└── securityStuff.nix  # Unclear naming
```

### File Naming Conventions

- **Entry points**: `init.nix` - Main entry point for modules
- **Implementations**: `default.nix` - Core module implementation
- **References**: `index.nix` - Module documentation and reference
- **Documentation**: `README.md` - Comprehensive module documentation
- **Quick guides**: `QUICKSTART.md` - Quick start guide
- **Single modules**: `<module-name>.nix` - Standalone modules

### Examples

```bash
✅ modules/security/init.nix        # Security module entry
✅ modules/security/default.nix     # Security implementation
✅ modules/networking.nix          # Networking module
✅ modules/utils.nix               # Utility functions
✅ examples/security-example.nix   # Example configuration
✅ tests/modules/security/init.nix # Security tests entry

❌ modules/sec_main.nix            # Inconsistent naming
❌ modules/SecurityModule.nix      # Wrong case
❌ modules/securityModule.nix      # Mixed case
❌ modules/sec_utils.nix           # Too abbreviated
```

## Module Structure

### Standard Module Organization

```nix
# modules/security/init.nix
{ config, lib, pkgs, ... }:

let
  # Import submodules
  submodules = [
    ./default.nix
    # ./subfeature.nix
  ];
  
  # Combine configurations
  combined = lib.foldl' (acc: module: acc // import module) {} submodules;
  
in combined
```

### Module Entry Point Pattern

```nix
# ✅ RECOMMENDED
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption mkDefault mkEnableOption mkIf mkForce;
  inherit (lib.types) submodule str bool listOf attrs;
  
  # Module-specific functions and variables
  defaultConfig = { ... };
  helperFunction = x: ...;
  
in {
  options = { ... };
  config = { ... };
}
```

## Nix Code Conventions

### Indentation and Formatting

```nix
✅ GOOD - Consistent 2-space indentation
{
  option1 = "value";
  option2 = {
    subOption = "value";
    anotherOption = [
      "item1"
      "item2"
    ];
  };
}

❌ AVOID - Inconsistent indentation
{
  option1 = "value";
    option2 = {
      subOption = "value";
    anotherOption = [ "item1", "item2" ];
    };
}
```

### String Quoting

```nix
✅ GOOD - Double quotes for strings
{
  message = "Hello, NixOS Fabric!";
  path = "/etc/nixos/config.nix";
}

❌ AVOID - Single quotes (less common in Nix)
{
  message = 'Hello, NixOS Fabric!';
}
```

### Function Definitions

```nix
✅ GOOD - Clear function definitions
let
  # Single line function
  square = x: x * x;
  
  # Multi-line function
  processConfig = cfg: 
    let
      result = cfg.value + 1;
    in result;
  
in { ... }

❌ AVOID - Unclear function definitions
let f=x:x*x; g=y:let z=y+1;in z; in { ... }
```

## Configuration Options

### Option Naming

```nix
✅ GOOD - Clear, descriptive names
options.network-fabric.security = {
  enable = mkOption { ... };
  ssh = mkOption { ... };
  firewall = mkOption { ... };
  fail2ban = mkOption { ... };
}

❌ AVOID - Vague or abbreviated names
options.nf.sec = {
  en = mkOption { ... };
  sshd = mkOption { ... };
  fw = mkOption { ... };
}
```

### Option Organization

```nix
✅ GOOD - Logical grouping
options.network-fabric.security = {
  # Main enable option
  enable = mkEnableOption "Enable security module";
  
  # Feature groups
  ssh = mkOption { ... };
  firewall = mkOption { ... };
  fail2ban = mkOption { ... };
  
  # Advanced features
  apparmor = mkOption { ... };
  auditd = mkOption { ... };
}

❌ AVOID - Random ordering
options.network-fabric.security = {
  fail2ban = mkOption { ... };
  enable = mkEnableOption "...";
  auditd = mkOption { ... };
  ssh = mkOption { ... };
}
```

## Variable Naming

### Common Variable Names

```nix
✅ GOOD - Standard variable names
{
  config,      # Full configuration
  lib,         # Nix library
  pkgs,        # Nix packages
  options,     # Module options
  cfg,         # Processed configuration
  defaultConfig, # Default configuration values
  helperFunc,  # Helper function
}

❌ AVOID - Non-standard names
{
  c,           # Unclear what this is
  l,           # Unclear abbreviation
  p,           # Unclear abbreviation
  opts,        # Non-standard
  conf,        # Non-standard
}
```

### Function Parameter Names

```nix
✅ GOOD - Descriptive parameter names
let
  processSecurityConfig = securityConfig: ...;
  generateFirewallRules = config: ...;
  validateSSHSettings = sshSettings: ...;
  
in { ... }

❌ AVOID - Unclear parameter names
let
  process = x: ...;
  generate = y: ...;
  validate = z: ...;
  
in { ... }
```

## Commenting Standards

### File Header Comments

```nix
✅ GOOD - Comprehensive file headers
# ============================================
# NixOS Fabric Security Module
# ============================================
#
# This module provides comprehensive security configuration
# for NixOS Fabric deployments.
#
# Features:
# - SSH Hardening
# - Firewall Configuration
# - Intrusion Detection
# - System Hardening
#
# Usage:
#   imports = [ ../modules/security/init.nix ];
# ============================================

❌ AVOID - Minimal or no headers
# Security module
# Provides security features
```

### Section Comments

```nix
✅ GOOD - Clear section separation
# ============================================
# DEFAULT SECURITY CONFIGURATION
# ============================================
# This section defines sensible defaults for all
# security features that can be overridden.
# ============================================

❌ AVOID - No section separation
# Default config
defaultConfig = { ... }
```

### Inline Comments

```nix
✅ GOOD - Helpful inline comments
services.openssh = mkIf cfg.ssh.enable {
  enable = true;
  
  settings = {
    Port = toString cfg.ssh.port;  # Custom SSH port for security
    PermitRootLogin = mkForce cfg.ssh.permitRootLogin;  # Disable root login
    PasswordAuthentication = mkForce cfg.ssh.passwordAuthentication;  # Keys only
  };
};

❌ AVOID - Redundant or obvious comments
services.openssh = mkIf cfg.ssh.enable {
  enable = true;  # Enable the service
  
  settings = {
    Port = toString cfg.ssh.port;  # Set the port
    PermitRootLogin = mkForce cfg.ssh.permitRootLogin;  # Set root login
    PasswordAuthentication = mkForce cfg.ssh.passwordAuthentication;  # Set auth
  };
};
```

### TODO Comments

```nix
✅ GOOD - Clear TODO format
# TODO: Add support for custom AppArmor profiles
# TODO: Implement automatic certificate rotation
# TODO: Add more detailed error handling

❌ AVOID - Unclear TODOs
# Fix this later
# Add something here
# Check this
```

## Documentation Standards

### Module Documentation Structure

```markdown
✅ GOOD - Complete documentation
# Module Name

## Overview
Brief description of what the module does.

## Features
- Feature 1
- Feature 2
- Feature 3

## Usage
### Basic
```nix
# Basic usage example
```

### Advanced
```nix
# Advanced usage example
```

## Configuration Options
### option1
Description of option1

### option2
Description of option2

## Integration
How it works with other modules

## Testing
How to test the module

## Troubleshooting
Common issues and solutions
```

❌ AVOID - Minimal documentation
# Security Module
# Configures security settings
```

### Code Examples in Documentation

```markdown
✅ GOOD - Complete examples
```nix
# Production security configuration
network-fabric.security = {
  enable = true;
  
  ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };
  
  firewall = {
    enable = true;
    allowedTCP = [ 2222 80 443 ];
    allowedUDP = [ ];
  };
};
```

❌ AVOID - Incomplete examples
```nix
# Security config
network-fabric.security.enable = true;
```
```

## Import Conventions

### Import Order

```nix
✅ GOOD - Logical import order
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
    
    # 4. Host-specific
    ./host-config.nix
    
    # 5. Environment-specific
    ./environment/${config.network-fabric.environment}.nix
  ];
}

❌ AVOID - Random import order
{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/frr.nix
    ./host-config.nix
    ../modules/network-fabric.nix
    ../modules/security/init.nix
    ../modules/ansible.nix
  ];
}
```

### Import Paths

```nix
✅ GOOD - Relative paths from repository root
imports = [
  ../modules/security/init.nix
  ../modules/networking.nix
  ../modules/wireguard.nix
];

❌ AVOID - Absolute paths or inconsistent paths
imports = [
  /home/user/nixos-fabric/modules/security/init.nix
  ./modules/security/init.nix
  modules/security/init.nix
];
```

## Test Organization

### Test File Structure

```bash
✅ GOOD - Organized test structure
tests/
├── modules/              # Module-specific tests
│   ├── security/         # Security module tests
│   │   ├── init.nix      # Test entry point
│   │   ├── default.nix   # Main test suite
│   │   └── ...           # Additional test files
│   ├── networking/       # Networking tests
│   └── ...               # Other module tests
│
├── integration/          # Integration tests
│   ├── fabric-test.nix   # Full fabric tests
│   └── ...               # Other integration tests
│
├── vm-test-config.nix    # VM test configuration
├── run-organized-tests.sh # Test runner script
└── TESTING_SUMMARY.md    # Testing documentation

❌ AVOID - Disorganized test structure
tests/
├── test1.nix
├── test_security.nix
├── security_test_suite.nix
├── test_vm_config.nix
└── some_test_file.nix
```

### Test Naming

```bash
✅ GOOD - Clear test names
test-security-module.nix        # Security module tests
test-networking-config.nix     # Networking configuration tests
test-fabric-integration.nix    # Fabric integration tests
vm-test-config.nix             # VM test configuration
run-organized-tests.sh        # Test runner script

❌ AVOID - Unclear test names
test1.nix                      # What does this test?
sec_test.nix                    # Too abbreviated
my_test_file.nix               # Too generic
```

## Best Practices Checklist

### Before Committing

- [ ] Follow file and directory naming conventions
- [ ] Use consistent indentation (2 spaces)
- [ ] Add comprehensive file header comments
- [ ] Include section comments for major blocks
- [ ] Use descriptive variable and function names
- [ ] Add helpful inline comments where needed
- [ ] Include TODO comments for future work
- [ ] Follow import conventions
- [ ] Organize configuration options logically
- [ ] Test the module with `nix-instantiate --eval`
- [ ] Update documentation if changes affect usage

### Code Review Checklist

- [ ] Consistent naming throughout
- [ ] Proper indentation and formatting
- [ ] Clear and helpful comments
- [ ] Logical organization of code
- [ ] Appropriate use of Nix functions
- [ ] Proper error handling where needed
- [ ] Comprehensive documentation updates
- [ ] Tests cover new functionality
- [ ] No breaking changes to existing APIs

## Migration Guide

### From Old Structure to New

**Before:**
```bash
modules/
├── security.nix                # Single file
├── security-improved.nix       # Alternative module
└── ...
```

**After:**
```bash
modules/
├── security/                   # Organized module
│   ├── init.nix                # Entry point
│   ├── default.nix             # Implementation
│   ├── index.nix               # Reference
│   ├── README.md              # Documentation
│   └── QUICKSTART.md          # Quick guide
└── ...
```

### Updating Imports

**Before:**
```nix
imports = [
  ../modules/security.nix
  # or
  ../modules/security-improved.nix
];
```

**After:**
```nix
imports = [
  ../modules/security/init.nix
];
```

### Updating Configuration Paths

**Before:**
```nix
network-fabric.security-improved = {
  enable = true;
  # ...
};
```

**After:**
```nix
network-fabric.security = {
  enable = true;
  # ...
};
```

## Tools and Validation

### Linters and Formatters

```bash
# Check Nix syntax
nix-instantiate --eval -E 'import ./your-file.nix'

# Format Nix code (if using nixpkgs-fmt)
nixpkgs-fmt ./your-file.nix

# Check for undefined variables
nix-instantiate --eval --strict ./your-file.nix
```

### Validation Commands

```bash
# Validate module structure
tests/run-organized-tests.sh

# Check specific module
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Test example configuration
nix-instantiate --eval -E 'import ./examples/security-example.nix'
```

## Conclusion

Following these conventions ensures that the NixOS Fabric codebase remains:
- **Consistent** across all modules and files
- **Readable** for both new and experienced contributors
- **Maintainable** as the project grows and evolves
- **Professional** in quality and organization
- **Accessible** to the open-source community

By adhering to these standards, we create a codebase that is enjoyable to work with and easy to contribute to.