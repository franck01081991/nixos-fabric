# Architecture Overview

This document provides a high-level overview of the NixOS Fabric architecture, explaining the key components and design principles.

## 🎯 System Goals

1. **Reproducibility**: Identical configurations across all nodes
2. **Scalability**: Easy to add new nodes to the fabric
3. **Maintainability**: Centralized configuration management
4. **Flexibility**: Support for different node roles
5. **Reliability**: Robust networking and failover

## 📦 High-Level Architecture

```
┌───────────────────────────────────────────────────────┐
│                   NixOS Fabric System                  │
├───────────────────┬───────────────────┬───────────────┤
│   rtr-sapinet     │    rtr-noisy      │   (future)     │
│  (Pure Spine)     │  (Hybrid Node)    │   nodes        │
├───────────────────┼───────────────────┼───────────────┤
│ - OSPF + BGP      │ - OSPF + BGP      │ - Spine/Leaf   │
│ - IPv4 + IPv6     │ - IPv4 + IPv6     │ - Hybrid       │
│ - Full mesh       │ - Full mesh       │ - Roles        │
└───────────────────┴───────────────────┴───────────────┘
```

## 🔧 Key Components

### 1. Role System

The fabric uses a role-based architecture:

- **Spine Role** (`rtr-sapinet`):
  - Core routing only
  - High-speed interconnect
  - No direct server connections

- **Leaf Role** (future):
  - Server connectivity
  - Edge routing
  - Connects to spine nodes

- **Hybrid Role** (`rtr-noisy`):
  - Combines spine + leaf
  - Flexible deployment
  - Full mesh connectivity

### 2. Configuration Structure

```
configuration/
├── base-variables.nix      # Base network settings
├── role-variables.nix      # Role-specific configuration
├── variables.nix           # Detailed network config
└── default.nix             # Main entry point
```

### 3. Network Protocols

- **OSPF**: Interior Gateway Protocol
  - Area 0 for all nodes
  - Fast convergence
  - IPv4 + IPv6 support

- **BGP**: Border Gateway Protocol
  - AS 65000
  - Full mesh iBGP
  - EVPN for overlay networks

- **WireGuard**: Secure overlay
  - Full mesh topology
  - IPv4 + IPv6 tunnels
  - Persistent keepalive

### 4. Security Features

- **AppArmor**: Mandatory access control
- **Fail2ban**: Intrusion prevention
- **Auditd**: Security auditing
- **WireGuard**: Encrypted tunnels
- **NFTables**: Stateful firewall

## 🌐 Network Topology

### Physical Topology

```
[Server 1] -- [rtr-noisy] -- [rtr-sapinet] -- [Internet]
[Server 2] -- [rtr-noisy] -- [rtr-sapinet] -- [Internet]
```

### Logical Topology

```
┌───────────────────────────────────────────────────────┐
│                   Overlay Network (WireGuard)          │
│                                                       │
│  ┌─────────┐       ┌─────────┐       ┌─────────┐      │
│  │Server 1 │       │Server 2 │       │Internet│      │
│  └─────────┘       └─────────┘       └─────────┘      │
│       │               │               │             │
│       ▼               ▼               ▼             │
│  ┌─────────┐     ┌─────────┐     ┌─────────┐      │
│  │ rtr-noisy │ --- │ rtr-sapinet │ --- │  ...    │      │
│  └─────────┘     └─────────┘     └─────────┘      │
└───────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### Configuration Flow

```
Developer → Git → CI/CD → Deployment
    │       │       │       │
    ▼       ▼       ▼       ▼
Local → External → Build → Production
```

### Network Traffic Flow

```
Server → rtr-noisy → rtr-sapinet → Internet
    (Leaf)      (Hybrid)     (Spine)
```

## 📦 Module Architecture

### Core Modules

```
modules/
├── base.nix              # Base system configuration
├── frr.nix               # FRR routing daemon
├── networking.nix        # Network interfaces
├── nftables.nix          # Firewall rules
├── security.nix          # Security hardening
├── ssh.nix               # SSH configuration
└── wireguard.nix         # WireGuard VPN
```

### Role Modules

```
modules/roles/
├── spine.nix             # Spine role definition
└── leaf.nix              # Leaf role definition
```

## 🎯 Design Principles

### 1. Separation of Concerns

- **Roles**: Define node behavior
- **Modules**: Provide functionality
- **Hosts**: Configure specific instances

### 2. Convention over Configuration

- Standardized naming (`rtr-*`)
- Consistent file structure
- Predictable behavior

### 3. Infrastructure as Code

- Declarative configuration
- Version controlled
- Reproducible builds

### 4. Defense in Depth

- Multiple security layers
- Network segmentation
- Encryption everywhere

## 🚀 Deployment Strategy

### 1. Development Workflow

```
Code → Test → Build → Deploy → Verify
```

### 2. Update Process

```
Git Pull → Nix Build → System Switch → Health Check
```

### 3. Rollback Strategy

```
Current → New → (Verify) → Rollback if needed
```

## 📊 Performance Considerations

### Network Performance

- Full mesh WireGuard for low latency
- OSPF for fast convergence
- BGP for scalable routing

### Build Performance

- Nix caching for faster builds
- Binary caches for dependencies
- Parallel builds where possible

### System Performance

- Optimized kernel parameters
- Resource limits configured
- Monitoring in place

## 🔧 Maintenance

### Monitoring

- System metrics
- Network health
- Service status

### Logging

- Persistent logs
- Centralized aggregation
- Rotation policy

### Updates

- Regular NixOS updates
- Security patches
- Configuration reviews

## 🎓 Learning Resources

- [NixOS Manual](https://nixos.org/manual/)
- [FRR Documentation](https://frrouting.org/)
- [WireGuard Docs](https://www.wireguard.com/)
- [OSPF Guide](https://www.rfc-editor.org/rfc/rfc2328)
- [BGP Guide](https://www.rfc-editor.org/rfc/rfc4271)

## 📖 Next Steps

- Read the [Quick Start Guide](QUICKSTART.md)
- Explore the [Role System](../../reference/ROLES.md)
- Review the [Development Workflow](../../development/WORKFLOW.md)