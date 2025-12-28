# External Configurations Workflow

## Overview

This document describes the new dynamic workflow for managing external configurations in the NixOS Fabric project. The workflow eliminates the need for Ansible in the validation process and provides automatic validation and synchronization of external machine configurations.

## Key Features

- **Automatic Validation**: All external configurations are automatically validated
- **Dynamic Detection**: New machines in `external/` are automatically detected and validated
- **Comprehensive Testing**: Integrated testing system for external configurations
- **CI/CD Integration**: Full integration with GitHub Actions pipeline
- **No Ansible Required**: Validation is done using pure Nix, Ansible is only needed for deployment

## Workflow Components

### 1. External Configuration Structure

External configurations are stored in the `external/` directory with the following structure:

```
external/
├── machine1-config/
│   ├── default.nix          # Main configuration
│   ├── variables.nix        # Network variables
│   ├── base-variables.nix   # Base configuration
│   ├── role-variables.nix   # Role-specific variables
│   ├── hardware-configuration.nix
│   └── README.md
└── machine2-config/
    ├── ...
```

### 2. Validation Script

The `scripts/validate-external-configs.sh` script performs the following checks:

- **Structure Validation**: Verifies all required files are present
- **Syntax Validation**: Ensures configurations can be evaluated
- **Content Validation**: Checks for common issues and best practices

### 3. Testing System

The `tests/integration/external-configs-test.nix` provides comprehensive testing:

- **Dynamic Detection**: Automatically finds all external configurations
- **Evaluation Testing**: Tests that configurations can be properly evaluated
- **Structure Testing**: Verifies required attributes are present
- **Security Checks**: Validates security-related configuration

### 4. Synchronization Script

The `scripts/sync-and-validate.sh` script provides a complete workflow:

1. **Validation**: Runs structure and syntax validation
2. **Testing**: Executes comprehensive tests
3. **Synchronization**: Copies validated configs to `hosts/` directory

## Usage Guide

### Adding a New Machine

1. **Create External Configuration**:
   ```bash
   # Create new directory in external/
   mkdir external/new-machine-config
   
   # Add required files
   touch external/new-machine-config/{default.nix,variables.nix,base-variables.nix,role-variables.nix,hardware-configuration.nix}
   ```

2. **Validate Configuration**:
   ```bash
   ./scripts/validate-external-configs.sh
   ```

3. **Run Comprehensive Tests**:
   ```bash
   ./tests/scripts/test-external-configs.sh
   ```

4. **Synchronize to Hosts**:
   ```bash
   ./scripts/sync-and-validate.sh
   ```

### Updating Existing Machines

1. **Update External Repository**:
   ```bash
   cd external/machine-config
   git pull origin master
   ```

2. **Re-run Validation and Sync**:
   ```bash
   cd ../..
   ./scripts/sync-and-validate.sh
   ```

### CI/CD Integration

The workflow is fully integrated with GitHub Actions:

1. **Automatic Validation**: All external configs are validated on every push/PR
2. **Testing**: Comprehensive tests run automatically
3. **Quality Gate**: Prevents invalid configurations from being merged

## Technical Details

### Validation Process

The validation script checks for:

- **Required Files**: `default.nix`, `variables.nix`, `base-variables.nix`, `role-variables.nix`
- **Nix Evaluation**: Configurations must be evaluable without errors
- **Network Fabric**: Configurations should reference `network-fabric`

### Testing Process

The testing system performs:

- **Dynamic Discovery**: Finds all `*-config` directories in `external/`
- **Evaluation Testing**: Uses `nix-instantiate` to test evaluation
- **Attribute Checking**: Verifies required attributes are present
- **Security Validation**: Checks for security-related configuration

### Synchronization Process

The synchronization process:

1. **Validates** all external configurations
2. **Tests** all configurations comprehensively
3. **Copies** validated configs to `hosts/` directory
4. **Updates** README files with synchronization info

## Ansible vs Nix Approach

### Why This Approach is Better

1. **No Ansible Dependency**: Validation uses pure Nix, reducing complexity
2. **Faster Validation**: Nix evaluation is faster than Ansible playbooks
3. **Better Integration**: Works seamlessly with Nix flakes and modules
4. **Automatic Detection**: Dynamically finds new configurations
5. **Comprehensive Testing**: Built-in testing system for all configurations

### When to Use Ansible

Ansible is still useful for:

- **Deployment**: Complex multi-machine deployments
- **Legacy Systems**: Systems not yet migrated to Nix
- **Hybrid Environments**: Mixed Nix/non-Nix environments

## Best Practices

### Configuration Structure

- Keep configurations modular and reusable
- Use clear naming conventions (`machine-role-config`)
- Document configuration purpose and requirements
- Follow NixOS module system best practices

### Validation Workflow

- Run validation before committing changes
- Use CI/CD for automatic validation
- Test configurations in isolation before integration
- Validate both syntax and semantics

### Synchronization Strategy

- Synchronize regularly from external repositories
- Validate before synchronization
- Test after synchronization
- Document synchronization process

## Troubleshooting

### Common Issues

**Validation Failures**:
- Missing required files
- Syntax errors in Nix code
- Missing dependencies

**Test Failures**:
- Evaluation errors
- Missing required attributes
- Security configuration issues

**Synchronization Issues**:
- Permission problems
- File conflicts
- Directory structure issues

### Debugging Commands

```bash
# Validate single configuration
nix-instantiate --eval external/machine-config/default.nix

# Test evaluation with context
nix-instantiate --eval -E "with import <nixpkgs> {}; callPackage ./external/machine-config/default.nix {}"

# Check file structure
ls -la external/machine-config/

# Run specific validation
./scripts/validate-external-configs.sh
```

## Migration Guide

### From Old Workflow

1. **Move Configurations**:
   ```bash
   mv old-external-configs/* external/
   ```

2. **Update Structure**:
   ```bash
   # Ensure each config has required files
   for config in external/*-config; do
       for file in default.nix variables.nix base-variables.nix role-variables.nix; do
           [ -f "$config/$file" ] || touch "$config/$file"
       done
   done
   ```

3. **Test and Validate**:
   ```bash
   ./scripts/validate-external-configs.sh
   ./tests/scripts/test-external-configs.sh
   ```

4. **Synchronize**:
   ```bash
   ./scripts/sync-and-validate.sh
   ```

## Examples

### Adding a New Spine Node

```bash
# Create new spine configuration
mkdir external/spine-node1-config
cd external/spine-node1-config

# Initialize with template
cat > default.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./base-variables.nix
    ./role-variables.nix
  ];

  network-fabric = {
    enable = true;
    networking = {
      role = "spine";
      hostname = "spine-node1";
    };
  };
}
EOF

# Validate and sync
cd ../..
./scripts/sync-and-validate.sh
```

### Updating from External Repository

```bash
# Update external config
cd external/spine-node1-config
git pull origin master

# Re-validate and sync
cd ../..
./scripts/sync-and-validate.sh
```

## Conclusion

This new workflow provides a robust, dynamic system for managing external configurations that:

- **Automates validation** of all external configurations
- **Eliminates manual processes** for configuration management
- **Integrates seamlessly** with CI/CD pipelines
- **Reduces complexity** by using pure Nix for validation
- **Scales easily** to handle many external machines

The system ensures that all configurations are validated before deployment, reducing errors and improving reliability.
