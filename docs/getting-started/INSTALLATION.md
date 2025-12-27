# Installation Guide

## Prerequisites

- NixOS system or Nix package manager
- Git for version control
- Basic familiarity with Nix language

## Installation Methods

### Method 1: Using Nix Flakes (Recommended)

```bash
# Clone the repository
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric

# Enable flakes if not already enabled
nix shell nixpkgs#nixUnstable --command "nix flake init"

# Run flake check to verify
nix flake check
```

### Method 2: Traditional NixOS Configuration

```bash
# Clone the repository
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric

# Import in your configuration.nix
# imports = [ ./modules/network-fabric.nix ];
```

### Method 3: Using Nixpkgs Overlay

```bash
# Add to your flake.nix
{
  inputs.nixos-fabric.url = "github:franck01081991/nixos-fabric";
  
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [ nixos-fabric.modules.network-fabric.nix ];
    };
  };
}
```

## Post-Installation

After installation:

1. **Verify configuration**:
   ```bash
   nix-instantiate --eval -E 'import ./modules/security/init.nix'
   ```

2. **Run tests**:
   ```bash
   bash tests/run-security-tests.sh
   ```

3. **Check flake**:
   ```bash
   nix flake check
   ```

## Troubleshooting

See [Troubleshooting Guide](../troubleshooting/DEBUGGING.md) for common issues.
