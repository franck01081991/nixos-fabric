# Quick Start Guide

Get up and running with the NixOS Fabric in 5 minutes!

## 🚀 Prerequisites

### System Requirements

- **Hardware**: x86_64 server with 2+ CPU cores, 4GB+ RAM, 20GB+ disk
- **OS**: Any Linux distribution (NixOS recommended)
- **Network**: Internet access for downloads
- **Tools**: git, curl

### Software Requirements

- **Nix**: Version 2.13+ with flakes support
- **Git**: Version 2.30+
- **GitHub CLI** (optional): For submodule management

## 📥 Installation

### 1. Install Nix

```bash
# Multi-user installation (recommended)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Enable flakes and experimental features
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### 2. Clone the Repository

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric
```

### 3. Verify Installation

```bash
# Check Nix version
nix --version

# Check flake support
nix flake --version

# Validate the configuration
nix flake check
```

## 🛠️ Basic Usage

### Build a Configuration

```bash
# Build rtr-sapinet configuration
nix build .#nixosConfigurations.rtr-sapinet.config.system.build.toplevel

# Build rtr-noisy configuration
nix build .#nixosConfigurations.rtr-noisy.config.system.build.toplevel
```

### Evaluate Configuration

```bash
# Check hostname
nix eval .#nixosConfigurations.rtr-sapinet.config.networking.hostName

# Check IP address
nix eval .#nixosConfigurations.rtr-sapinet.config.networking.interfaces

# Check services
nix eval .#nixosConfigurations.rtr-sapinet.config.services.frr.enable
```

### Deploy to a Machine

```bash
# Switch to rtr-sapinet configuration
sudo nixos-rebuild switch --flake .#rtr-sapinet

# Or test without switching
sudo nixos-rebuild test --flake .#rtr-sapinet
```

## 📦 Development Workflow

### 1. Make Changes

```bash
# Edit a configuration file
nano hosts/rtr-sapinet/role-variables.nix

# Or edit a module
nano modules/roles/spine.nix
```

### 2. Test Changes

```bash
# Validate the flake
nix flake check

# Build the configuration
nix build .#nixosConfigurations.rtr-sapinet

# Check specific values
nix eval .#nixosConfigurations.rtr-sapinet.config.networking.hostName
```

### 3. Commit Changes

```bash
# Add changes
git add .

# Commit with message
git commit -m "feat: Update spine configuration"

# Push to GitHub
git push origin master
```

## 🔄 Synchronization

### Automatic Synchronization

The system automatically synchronizes between `hosts/` and `external/`:

```bash
# Changes in hosts/ are automatically pushed to external/
git commit -m "Update config"

# Changes in external/ are automatically pulled to hosts/
git pull origin master
```

### Manual Synchronization

```bash
# Check synchronization status
./scripts/sync-bidirectional.sh status

# Sync in both directions
./scripts/sync-bidirectional.sh both

# Sync from external to local
./scripts/sync-bidirectional.sh from-external

# Sync from local to external
./scripts/sync-bidirectional.sh to-external
```

## 📖 Common Tasks

### Add a New Host

```bash
# 1. Create host directory
mkdir -p hosts/new-host

# 2. Create base configuration
nano hosts/new-host/base-variables.nix

# 3. Define role
nano hosts/new-host/role-variables.nix

# 4. Add to flake.nix
nano flake.nix
```

### Update a Module

```bash
# Edit the module
nano modules/roles/spine.nix

# Validate
nix flake check

# Test
nix build .#nixosConfigurations.rtr-sapinet
```

### Debug Issues

```bash
# Check flake metadata
nix flake metadata

# Show available outputs
nix flake show

# Evaluate specific attribute
nix eval .#nixosConfigurations.rtr-sapinet.config.networking
```

## 🚀 Deployment

### 1. Build Configuration

```bash
nix build .#nixosConfigurations.rtr-sapinet.config.system.build.toplevel
```

### 2. Copy to Target Machine

```bash
scp result root@target-machine:/tmp/nixos-system
```

### 3. Activate Configuration

```bash
# On target machine
sudo nixos-rebuild switch --flake /tmp/nixos-system
```

### 4. Verify

```bash
# Check hostname
hostname

# Check services
systemctl status frr

# Check networking
ip a
```

## 📚 Next Steps

1. **Read the Architecture Overview**: Understand how the system works
2. **Explore the Role System**: Learn about spine and leaf roles
3. **Review the Modules**: See what functionality is available
4. **Check the CI/CD Pipeline**: See how deployments are automated

## 🆘 Troubleshooting

### Flake Check Fails

```bash
# See detailed error
nix flake check --show-trace

# Check specific configuration
nix eval .#nixosConfigurations.rtr-sapinet
```

### Build Fails

```bash
# Try with more details
nix build --verbose .#nixosConfigurations.rtr-sapinet

# Check logs
journalctl -u nix-daemon
```

### Synchronization Issues

```bash
# Check status
./scripts/sync-bidirectional.sh status

# Force sync
./scripts/sync-bidirectional.sh both
```

## 📖 Additional Resources

- [NixOS Manual](https://nixos.org/manual/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [FRR Documentation](https://frrouting.org/)
- [WireGuard Guide](https://www.wireguard.com/)

## 🎯 Summary

You've learned how to:
- ✅ Install and configure the system
- ✅ Build and evaluate configurations
- ✅ Deploy to machines
- ✅ Work with the synchronization system
- ✅ Troubleshoot common issues

**Next**: Explore the [Architecture Overview](OVERVIEW.md) to understand the system design!