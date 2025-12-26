# NixOS Fabric Infrastructure

**Private Repository** - Advanced network automation with hybrid spine/leaf architecture, WireGuard, BGP, OSPF, and EVPN/VXLAN.

## 🎯 Architecture Overview

This repository implements a **hybrid network fabric** where nodes can simultaneously act as both **spine** (core) and **leaf** (edge) routers, providing unprecedented flexibility and resilience.

### Current Network Topology

```
┌───────────────────────────────────────────────────────┐
│                   Hybrid Fabric Network                │
├───────────────────┬───────────────────┬───────────────┤
│   rtr-sapinet     │    rtr-noisy      │   (future)     │
│  (Pure Spine)     │  (Hybrid Node)    │   nodes        │
├───────────────────┼───────────────────┼───────────────┤
│ - OSPF + BGP      │ - OSPF + BGP      │ - Spine/Leaf   │
│ - IPv4 + IPv6     │ - IPv4 + IPv6     │ - Hybrid       │
│ - Full mesh       │ - Full mesh       │ - Roles        │
│ - Core routing    │ - Core + Edge     │ - Modular      │
└───────────────────┴───────────────────┴───────────────┘
```

## 📖 Documentation

### Individual Host Documentation

Each host has comprehensive documentation:

- **rtr-sapinet-README.md** - Pure spine node configuration guide
  - Configuration structure and files
  - Usage instructions (standalone and with main repository)
  - Update process and best practices
  - Security recommendations

- **rtr-noisy-README.md** - Hybrid node configuration guide
  - Hybrid role configuration (spine + leaf)
  - Dual-protocol setup (OSPF + BGP + EVPN)
  - Configuration management
  - Deployment workflow

### Architecture and Deployment

- [Deployment Guide](docs/deployment/DEPLOYMENT.md) - Step-by-step deployment
- [Structure Reference](docs/reference/STRUCTURE.md) - Modular architecture
- [Role System](docs/reference/ROLES.md) - Hybrid role configuration
- [Troubleshooting](docs/troubleshooting/) - Common issues
- [Examples](docs/reference/EXAMPLES.md) - Configuration examples

## 🚀 Quick Start

```bash
# Clone the repository
git clone git@github.com:franck01081991/nixos-fabric.git
cd nixos-fabric

# Build and evaluate configurations
nix flake show
nix eval .#nixosConfigurations.rtr-sapinet.config.networking.hostName
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles

# Generate WireGuard keys
./scripts/deploy-wireguard.sh rtr-sapinet 45.90.162.251
./scripts/deploy-wireguard.sh rtr-noisy RTR_NOISY_IP

# Deploy configurations
sudo nixos-rebuild switch --flake .#rtr-sapinet
sudo nixos-rebuild switch --flake .#rtr-noisy

# Verify connectivity
./scripts/check-fabric.sh
```

## 🔗 External Configurations

### Option 1: Git Submodules (Recommended)

This repository supports Git submodules for external configurations:

```bash
# Setup submodules (after creating external repos)
./scripts/setup-submodules.sh

# Update all submodules
git submodule update --remote --init

# Check submodule status
git submodule status
```

The `.gitmodules` file contains the configuration for external repositories.

### Option 2: Individual Git Repositories

For advanced use cases, individual host configurations are available in separate repositories:

📚 **New! Organized documentation is available in [docs/](docs/):**
- [Architecture Overview](docs/architecture/OVERVIEW.md)
- [Quick Start Guide](docs/architecture/QUICKSTART.md)
- [Role System](docs/reference/ROLES.md)
- [Synchronization Strategy](docs/development/SYNC_STRATEGY.md)

### rtr-sapinet (Pure Spine)
- **Repository**: [franck01081991/rtr-sapinet-config](https://github.com/franck01081991/rtr-sapinet-config)
- **Purpose**: Pure spine node configuration
- **Content**: Complete NixOS configuration for core routing
- **Usage**: Can be used standalone or as reference

### rtr-noisy (Hybrid)
- **Repository**: [franck01081991/rtr-noisy-config](https://github.com/franck01081991/rtr-noisy-config)
- **Purpose**: Hybrid node configuration
- **Content**: Dual-role (spine + leaf) NixOS configuration
- **Usage**: Reference implementation for hybrid nodes

### Using Individual Repositories

```bash
# Clone individual host configuration
git clone https://github.com/franck01081991/rtr-sapinet-config.git
cd rtr-sapinet-config

# Review configuration
cat README.md
ls -la *.nix

# Use as reference for new spine nodes
cp -r rtr-sapinet-config/ hosts/new-spine-node/
```

## 📦 Network Nodes

### rtr-sapinet (Pure Spine)

| Role | Configuration |
|------|---------------|
| **Primary Role** | Spine (Core Router) |
| **Routing** | OSPF + BGP IPv4/IPv6 |
| **WireGuard** | Full mesh topology |
| **Security** | Fail2ban + Hardening |
| **IP Addressing** | 10.254.0.1/32 + fd42:1337:254::1/128 |

### rtr-noisy (Hybrid Node)

| Role | Configuration |
|------|---------------|
| **Primary Roles** | Spine + Leaf (Hybrid) |
| **Routing** | OSPF (Spine) + BGP + EVPN (Leaf) |
| **WireGuard** | Full mesh (Spine) + Point-to-spine (Leaf) |
| **Security** | Fail2ban (Spine) + Hardening |
| **IP Addressing** | 10.254.0.11/32 + fd42:1337:254::11/128 |

## 🔒 Security Policy

⚠️ **IMPORTANT**: This repository MUST remain PRIVATE

- **No secrets in git** - WireGuard keys stored in `/etc/wireguard/` on hosts
- **Secrets management** - Use `/etc/nixos/secrets/` (not committed)
- **Public keys** - Shared securely between hosts
- **Role-based access** - Different security profiles per role

## 🛠️ Deployment

### Hybrid Node Configuration

```bash
# rtr-noisy runs both spine and leaf roles
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.spine
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.leaf

# Verify both roles are active
sudo systemctl status frr  # Should show OSPF + BGP + EVPN
vtysh -c "show ip ospf neighbor"  # Spine role
vtysh -c "show ip bgp summary"    # Both roles
vtysh -c "show evpn vni"          # Leaf role
```

### Adding New Nodes

See [Structure Reference](docs/reference/STRUCTURE.md) for complete guide on adding:
- Pure spine nodes
- Pure leaf nodes
- Hybrid nodes (spine + leaf)

## 📂 Project Structure

```
nixos-fabric/
├── docs/                  # Documentation
│   ├── deployment/        # Deployment guides
│   ├── reference/         # Architecture & examples
│   └── troubleshooting/   # Issue resolution
├── hosts/                 # Host configurations
│   ├── rtr-sapinet/       # Pure spine node
│   │   ├── hardware-configuration.nix
│   │   ├── base-variables.nix
│   │   ├── role-variables.nix  # spine role only
│   │   └── default.nix        # Minimal config
│   └── rtr-noisy/         # Hybrid node (spine + leaf)
│       ├── hardware-configuration.nix
│       ├── base-variables.nix
│       ├── role-variables.nix  # spine + leaf roles
│       └── default.nix        # Minimal config
├── modules/               # Modular system
│   ├── base.nix            # Common configuration
│   ├── networking.nix      # Network module
│   ├── wireguard.nix       # WireGuard module
│   ├── frr.nix             # FRR module
│   ├── security.nix        # Security module
│   └── roles/              # Role system
│       ├── spine.nix       # Spine role
│       └── leaf.nix        # Leaf role
├── scripts/               # Deployment tools
├── rtr-sapinet-README.md  # rtr-sapinet documentation
├── rtr-noisy-README.md    # rtr-noisy documentation
└── flake.nix              # Flake configuration
```

## 🔧 Key Features

### Hybrid Role System
- **Pure Spine** (rtr-sapinet): Core routing only
- **Hybrid Node** (rtr-noisy): Core + Edge routing
- **Pure Leaf**: Edge routing only (template available)

### Modular Configuration
- **Networking**: Interfaces, DNS, gateways
- **WireGuard**: Secure overlay network
- **FRR**: OSPF, BGP, EVPN routing
- **Security**: SSH, firewall, hardening
- **Roles**: Spine, Leaf, or Hybrid

### Advanced Capabilities
- **IPv6 Support**: Full dual-stack networking
- **EVPN/VXLAN**: Overlay network virtualization
- **OSPF + BGP**: Hybrid routing protocols
- **Role-Based Security**: Different profiles per role
- **Modular Design**: Easy to extend

## 📊 Network Services

### Routing Protocols
- **OSPF**: Area 0, passive interfaces
- **BGP**: AS 65000, eBGP multihop
- **EVPN**: VXLAN overlay networks

### Overlay Networks
- **WireGuard**: UDP 51820, full mesh
- **VXLAN**: Bridge-based virtual networks
- **EVPN**: BGP-based overlay control

### Security Services
- **Fail2ban**: SSH protection
- **nftables**: Stateful firewall
- **AppArmor**: Mandatory access control
- **Auditd**: System auditing

## 🔧 Configuration Examples

### Check Hybrid Node Configuration

```bash
# Verify rtr-noisy has both roles
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.spine.enable
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.leaf.enable

# Check FRR configuration
nix eval .#nixosConfigurations.rtr-noisy.config.services.frr.config

# Check WireGuard peers
nix eval .#nixosConfigurations.rtr-noisy.config.networking.wireguard.interfaces.wgtransport.peers
```

### Test Connectivity

```bash
# Test WireGuard connectivity
ping 10.255.0.1    # rtr-sapinet
ping 10.255.0.11   # rtr-noisy

# Test BGP sessions
vtysh -c "show ip bgp summary"

# Test OSPF neighbors (rtr-noisy only)
vtysh -c "show ip ospf neighbor"
```

## 📚 Advanced Topics

### Hybrid Node Benefits

1. **Resilience**: Node can route at multiple layers
2. **Flexibility**: Adapt to changing network conditions
3. **Efficiency**: Single node handles multiple roles
4. **Scalability**: Grow network without adding nodes

### Role-Based Configuration

- **Spine Role**: Core routing, OSPF, full mesh
- **Leaf Role**: Edge services, EVPN, point-to-spine
- **Hybrid**: Both roles simultaneously

### Adding New Hybrid Nodes

```nix
# In role-variables.nix
{
  network-fabric.roles = {
    spine = { enable = true; roleId = "spine3"; };
    leaf = { enable = true; roleId = "leaf2"; };
  };
}
```

## 🛠️ Tools & Scripts

- `scripts/deploy-wireguard.sh` - Generate WireGuard keys
- `scripts/check-fabric.sh` - Verify network connectivity
- `scripts/deploy-and-verify.sh` - Interactive deployment

## 📞 Support & Troubleshooting

### Common Commands

```bash
# System logs
journalctl -f
journalctl -u frr -f
journalctl -u wg-quick@wgtransport -f

# Network status
sudo wg show
ip route
vtysh -c "show running-config"

# Service status
sudo systemctl status frr
sudo systemctl status wg-quick@wgtransport
sudo systemctl status nftables
```

### Debugging Hybrid Nodes

```bash
# Check which roles are active
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles

# Check FRR configuration
sudo cat /etc/frr/frr.conf

# Check role merging
nix repl
:l <nixpkgs/nixos/lib/eval-config.nix>
config = evalModules { modules = [./modules/roles/spine.nix ./modules/roles/leaf.nix]; } {}
```

## 🎯 Architecture Benefits

1. **Modularity**: Each component is isolated and reusable
2. **Consistency**: All nodes with same role have identical base config
3. **Flexibility**: Easy to customize per-host when needed
4. **Scalability**: Add new nodes with minimal configuration
5. **Maintainability**: Changes propagate automatically
6. **Hybrid Capability**: Nodes can serve multiple roles

## 📖 Documentation Index

- [Deployment Guide](docs/deployment/DEPLOYMENT.md): Step-by-step deployment
- [Structure Reference](docs/reference/STRUCTURE.md): Modular architecture
- [Role System](docs/reference/ROLES.md): Hybrid role configuration
- [Configuration Examples](docs/reference/EXAMPLES.md): Practical examples
- [Troubleshooting Guide](docs/troubleshooting/README.md): Common issues

This architecture provides a flexible, scalable, and maintainable network fabric with hybrid node capabilities for advanced networking scenarios.