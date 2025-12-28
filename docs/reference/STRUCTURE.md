# Repository Structure

**Note**: The repository has been **completely reorganized** for better clarity and maintainability.

## New Structure Documentation

The new organized structure is documented in:
- [`docs/reference/STRUCTURE.md`](docs/reference/STRUCTURE.md) - Complete structure documentation
- [`NEW_STRUCTURE_PLAN.md`](NEW_STRUCTURE_PLAN.md) - Migration plan and rationale

## Key Changes

### 1. Modules Reorganization
- **Before**: Mixed modules in root with inconsistent subdirectories
- **After**: Clear hierarchical structure by functional domain

### 2. Security Consolidation
- **Before**: `modules/security` and `modules/security-improved` with duplication
- **After**: Single unified security module in `modules/security/`

### 3. Ansible Simplification
- **Before**: `.ansible/` and `ansible/` with duplication
- **After**: Single `ansible/` directory with standard structure

### 4. Tests Organization
- **Before**: Tests mixed with other files
- **After**: Clear separation by test type (unit, integration, vm)

### 5. Documentation Centralization
- **Before**: Documentation scattered across repository
- **After**: Centralized in `docs/` with clear structure

## Migration Guide

If you're using the old structure, please see:
- [`docs/reference/STRUCTURE.md`](docs/reference/STRUCTURE.md) for the new structure
- Migration examples in the structure documentation

## Quick Reference

```
nixos-fabric/
├── modules/              # Reorganized modules
│   ├── core/             # Core modules
│   ├── networking/       # Networking modules
│   ├── security/         # Consolidated security
│   ├── integration/      # Integration modules
│   └── utils/            # Utility modules
│
├── hosts/               # Reorganized host configs
├── ansible/             # Simplified Ansible
├── tests/               # Organized tests
├── docs/                # Centralized docs
└── scripts/             # Organized scripts
```

For complete details, see the [full structure documentation](docs/reference/STRUCTURE.md).