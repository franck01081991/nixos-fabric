# NixOS Fabric Architecture - Comprehensive Guide

## 🎯 Overview

This document provides a comprehensive architectural overview of the NixOS Fabric system, explaining the design principles, component interactions, and deployment strategies.

## 🏗️ High-Level Architecture

```mermaid
graph TD
    A[NixOS Fabric] --> B[Core Modules]
    A --> C[Role System]
    A --> D[Ansible Integration]
    A --> E[Configuration Management]
    
    B --> B1[network-fabric.nix]
    B --> B2[networking.nix]
    B --> B3[security.nix]
    B --> B4[frr.nix]
    B --> B5[wireguard.nix]
    
    C --> C1[Spine Role]
    C --> C2[Leaf Role]
    C --> C3[Hybrid Role]
    
    D --> D1[Inventory Generation]
    D --> D2[Playbook Management]
    D --> D3[Variable Synchronization]
    
    E --> E1[Host Configurations]
    E --> E2[External Submodules]
    E --> E3[Bidirectional Sync]
```

## 🧩 Core Components

### 1. Central Fabric Module (`network-fabric.nix`)

The central module provides:
- **Unified Configuration Interface**: Single point for all fabric settings
- **Role Management**: Spine, Leaf, and Hybrid role definitions
- **Network Configuration**: IPv4/IPv6, DNS, routing
- **Security Settings**: SSH, firewall, access control
- **Environment Management**: Production/staging/development modes

### 2. Role System

```mermaid
classDiagram
    class FabricRole {
        +enable: Boolean
        +roleId: String
        +description: String
        +applyConfiguration()
    }
    
    class SpineRole {
        +routingProtocol: OSPF/BGP
        +meshTopology: Full
        +coreServices: Routing
    }
    
    class LeafRole {
        +routingProtocol: BGP/EVPN
        +meshTopology: Point-to-Spine
        +edgeServices: VXLAN
    }
    
    class HybridRole {
        +spineConfig: SpineRole
        +leafConfig: LeafRole
        +conflictResolution: PriorityBased
    }
    
    FabricRole <|-- SpineRole
    FabricRole <|-- LeafRole
    SpineRole <|-- HybridRole
    LeafRole <|-- HybridRole
```

### 3. Configuration Management Strategy

```mermaid
flowchart LR
    A[Host Configs] -- Bidirectional Sync --> B[External Submodules]
    A -- Nix Modules --> C[System Configuration]
    B -- Git Versioning --> D[Change Tracking]
    C -- System Activation --> E[Runtime Environment]
    E -- Service Management --> F[Fabric Services]
```

## 🔧 Technical Implementation

### Module Hierarchy

```
network-fabric.nix       # Central configuration
├── lib.nix              # Utility functions
├── dynamic.nix          # Runtime configuration
├── base.nix             # Common settings
├── networking.nix       # Network interfaces
├── security.nix         # Firewall & SSH
├── frr.nix              # Routing protocols
├── wireguard.nix        # VPN overlay
└── ansible.nix          # Configuration management
```

### Configuration Flow

1. **Nix Evaluation**: `flake.nix` → Module imports → Configuration merging
2. **System Activation**: Configuration → Activation scripts → Runtime environment
3. **Service Management**: systemd → Service configuration → Process supervision
4. **Runtime Configuration**: Environment variables → Service discovery → Dynamic updates

### Role-Based Configuration

```nix
# Example: Hybrid node configuration
{
  network-fabric.roles = {
    spine = {
      enable = true;
      roleId = "spine1";
      # OSPF + BGP configuration
    };
    leaf = {
      enable = true;
      roleId = "leaf1";
      # EVPN + VXLAN configuration
    };
  };
}
```

## 🌐 Network Topology

### Physical Topology

```mermaid
graph LR
    subgraph Spine Layer
        S1[rtr-sapinet] -->|OSPF/BGP| S2[Future Spine]
    end
    
    subgraph Leaf Layer
        L1[rtr-noisy] -->|BGP/EVPN| S1
        L2[Future Leaf] -->|BGP/EVPN| S1
    end
    
    subgraph Hybrid Layer
        H1[rtr-noisy Hybrid] -->|OSPF| S1
        H1 -->|BGP/EVPN| L1
    end
```

### Logical Topology

```mermaid
graph TD
    A[Control Plane] --> B[OSPF Area 0]
    A --> C[BGP AS 65000]
    A --> D[EVPN Control]
    
    B --> E[Spine Nodes]
    C --> F[Leaf Nodes]
    D --> G[VXLAN Overlay]
    
    E --> H[Full Mesh]
    F --> I[Point-to-Spine]
    G --> J[Virtual Networks]
```

## 🔄 Synchronization Architecture

### Bidirectional Sync System

```mermaid
sequenceDiagram
    participant Developer
    participant Local as Local Config
    participant External as External Submodule
    participant Git as Git Repository
    
    Developer->>Local: Modify configuration
    Local->>External: sync-bidirectional.sh to-external
    External->>Git: git commit & push
    
    Developer->>Git: git pull
    Git->>External: Update submodule
    External->>Local: sync-bidirectional.sh from-external
    
    alt Conflict Detection
        Local->>External: Check timestamps
        External->>Local: Compare content
        Local->>Developer: Report conflicts
    end
```

### Sync Workflow

```mermaid
flowchart TD
    A[Start] --> B{Change Location}
    
    B -->|Local| C[Modify hosts/*]
    C --> D[Run sync to-external]
    D --> E[Commit both repos]
    
    B -->|External| F[Modify external/*]
    F --> G[Run sync from-external]
    G --> H[Commit local changes]
    
    E --> I[Push to Git]
    H --> I
    I --> J[Team Sync]
```

## 🛡️ Security Architecture

### Security Layers

```mermaid
graph LR
    A[Network Layer] --> B[WireGuard Encryption]
    A --> C[nftables Firewall]
    
    B[System Layer] --> D[SSH Hardening]
    B --> E[Fail2ban]
    B --> F[AppArmor]
    
    C[Application Layer] --> G[FRR Security]
    C --> H[Service Isolation]
    
    D[Data Layer] --> I[Secret Management]
    D --> J[Configuration Validation]
```

### Access Control Matrix

| Component | Access Level | Authentication | Encryption |
|-----------|--------------|----------------|------------|
| SSH | Admin | Key-based | AES-256 |
| WireGuard | Fabric | PSK | ChaCha20 |
| FRR | Service | None | None |
| Ansible | Admin | SSH Keys | SSH Tunnel |

## 🚀 Deployment Architecture

### Deployment Pipeline

```mermaid
flowchart LR
    A[Development] -->|nix flake check| B[Testing]
    B -->|nix build| C[Staging]
    C -->|nixos-rebuild dry-activate| D[Production]
    D -->|nixos-rebuild switch| E[Runtime]
    E -->|systemctl| F[Services]
```

### Deployment Strategies

1. **Blue-Green Deployment**: Parallel environments with instant switch
2. **Rolling Updates**: Gradual node-by-node updates
3. **Canary Releases**: Test on subset before full deployment
4. **A/B Testing**: Route traffic between versions

## 📊 Monitoring Architecture

### Monitoring Stack

```mermaid
graph TD
    A[Fabric Nodes] -->|Metrics| B[Prometheus]
    A -->|Logs| C[Loki]
    A -->|Traces| D[Tempo]
    
    B --> E[Grafana]
    C --> E
    D --> E
    
    E --> F[Alertmanager]
    F --> G[Notifications]
```

### Key Metrics

- **Network**: Bandwidth, latency, packet loss
- **Routing**: OSPF neighbors, BGP sessions, route count
- **System**: CPU, memory, disk I/O
- **Services**: FRR status, WireGuard tunnels, SSH connections

## 🔧 Configuration Examples

### Hybrid Node Configuration

```nix
# hosts/rtr-noisy/default.nix
{
  network-fabric = {
    enable = true;
    name = "production-fabric";
    environment = "production";
    
    roles = {
      spine = {
        enable = true;
        roleId = "spine2";
      };
      leaf = {
        enable = true;
        roleId = "leaf1";
      };
    };
    
    network = {
      domain = "fabric.prod";
      dnsServers = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}
```

### Spine Node Configuration

```nix
# hosts/rtr-sapinet/default.nix
{
  network-fabric = {
    enable = true;
    name = "production-fabric";
    environment = "production";
    
    roles = {
      spine = {
        enable = true;
        roleId = "spine1";
      };
      leaf = {
        enable = false;
      };
    };
  };
}
```

## 🛠️ Best Practices

### Configuration Management

1. **Single Source of Truth**: Always modify in one location, sync to others
2. **Atomic Changes**: Make related changes together
3. **Validation**: Test configurations before deployment
4. **Documentation**: Document all non-obvious settings

### Role Configuration

1. **Clear Separation**: Keep spine/leaf configurations distinct
2. **Conflict Resolution**: Define priority for hybrid nodes
3. **Testing**: Validate role combinations before deployment
4. **Monitoring**: Monitor role-specific metrics

### Deployment

1. **Phased Rollouts**: Deploy to staging before production
2. **Rollback Plan**: Always have a fallback strategy
3. **Change Tracking**: Document all configuration changes
4. **Team Communication**: Coordinate deployments across team

## 📚 Reference Architecture

### Standard Fabric Configuration

```yaml
# Standard fabric configuration reference
fabric:
  name: "production-fabric"
  environment: "production"
  version: "25.11"
  
  roles:
    spine:
      count: 2-4
      protocol: "OSPF+BGP"
      topology: "full-mesh"
    leaf:
      count: "as-needed"
      protocol: "BGP+EVPN"
      topology: "point-to-spine"
  
  network:
    ipv4_prefix: "10.254.0.0/16"
    ipv6_prefix: "fd42:1337:254::/64"
    dns_servers: ["1.1.1.1", "8.8.8.8"]
  
  security:
    ssh_port: 22
    fail2ban: true
    firewall: true
```

## 🎯 Future Architecture Evolution

### Planned Enhancements

1. **Automated Testing**: CI/CD pipeline with validation
2. **Secret Management**: Integration with Vault/age
3. **Configuration Drift Detection**: Automated compliance checking
4. **Multi-Region Support**: Geographic distribution
5. **Autoscaling**: Dynamic node provisioning

### Roadmap

```mermaid
gantt
    title NixOS Fabric Roadmap
    dateFormat  YYYY-MM
    section Core Features
    Hybrid Role System       :a1, 2023-01, 60d
    Ansible Integration     :after a1, 30d
    
    section Enhancements
    Automated Testing       :2024-01, 90d
    Secret Management       :2024-03, 60d
    
    section Future
    Multi-Region Support    :2024-06, 120d
    Autoscaling             :2024-09, 90d
```

## 📖 Additional Resources

- [Deployment Guide](DEPLOYMENT.md): Step-by-step deployment instructions
- [Role System](ROLES.md): Detailed role configuration guide
- [Ansible Integration](ANSIBLE_INTEGRATION.md): Ansible workflow documentation
- [Troubleshooting Guide](TROUBLESHOOTING.md): Common issues and solutions

This architecture provides a flexible, scalable, and maintainable foundation for building advanced network fabrics with NixOS.