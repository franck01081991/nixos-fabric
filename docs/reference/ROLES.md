# Role-Based Configuration System - Hybrid Architecture

This document explains the role-based configuration system that enables nodes to simultaneously act as both spine and leaf routers, providing maximum flexibility and resilience in network architectures.

## 🎯 Overview

The role-based system provides a way to standardize configuration across different types of nodes while allowing hybrid configurations where a single node can serve multiple roles.

### Key Concepts

1. **Pure Spine Nodes**: Core routing only (OSPF + BGP)
2. **Pure Leaf Nodes**: Edge services only (BGP + EVPN)
3. **Hybrid Nodes**: Both core and edge routing simultaneously
4. **Role Inheritance**: All nodes with same role share base configuration
5. **Role Customization**: Per-node overrides for specific requirements

## 📂 Role Structure

```
modules/roles/
├── spine.nix              # Spine role definition (core routing)
└── leaf.nix               # Leaf role definition (edge services)

hosts/<hostname>/
├── role-variables.nix     # Role activation and customization
└── default.nix            # Minimal host configuration (imports roles)
```

## 🔧 Spine Role

### Default Configuration

The spine role (`modules/roles/spine.nix`) provides standard configuration for all spine nodes:

- **Networking**: Loopback interfaces (IPv4 + IPv6), IP addressing
- **WireGuard**: Standard WireGuard configuration, full mesh topology
- **FRR**: OSPF (Area 0) + BGP IPv4/IPv6 routing
- **Security**: Fail2ban enabled, system hardening, SSH configuration
- **System**: Journal, AppArmor, Audit services

### Spine Characteristics

```nix
{
  # Standard spine networking (dual-stack)
  networking = {
    loopback = {
      ipv4 = [ { address = "10.254.0.X"; prefixLength = 32; } ];
      ipv6 = [ { address = "fd42:1337:254::X"; prefixLength = 128; } ];
    };
  };

  # Standard spine WireGuard (full mesh)
  wireguard = {
    interfaceName = "wgtransport";
    listenPort = 51820;
    ips = [ "10.255.0.X/24" "fd42:1337:255::X/64" ];
  };

  # Standard spine FRR (OSPF + BGP)
  frr = {
    ospf = { 
      enable = true; 
      area = 0;
      networks = [ "10.254.0.X/32" "10.255.0.0/24" ];
      passiveInterfaces = [ "default" "wgtransport" ];
    };
    bgp = { 
      enable = true; 
      as = 65000;
      routerId = "10.254.0.X";
      addressFamilies = [ "ipv4 unicast" ];
    };
  };

  # Standard spine security
  security = {
    fail2ban = { enable = true; };
    hardening = { enable = true; };
  };
}
```

### Pure Spine Example (vm-sapinet)

```nix
# hosts/vm-sapinet/role-variables.nix
{ ... }:
{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine1";
    
    # Override defaults for this specific spine
    networking = {
      loopback = {
        ipv4 = [ { address = "10.254.0.1"; prefixLength = 32; } ];
        ipv6 = [ { address = "fd42:1337:254::1"; prefixLength = 128; } ];
      };
    };
    
    wireguard = {
      privateKeyFile = "/etc/wireguard/vm-sapinet.key";
      ips = [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
      peers = {
        rtr-noisy = {
          publicKey = "__NOISY_PUB__";
          endpoint = "__NOISY_ENDPOINT__:51820";
          allowedIPs = [
            "10.255.0.11/32"      # rtr-noisy WireGuard IP
            "fd42:1337:255::11/128"  # rtr-noisy IPv6
            "10.254.0.11/32"      # rtr-noisy loopback
            "fd42:1337:254::11/128"  # rtr-noisy IPv6 loopback
          ];
          persistentKeepalive = 25;
        };
        # Additional peers...
      };
    };
    
    frr = {
      ospf = {
        routerId = "10.254.0.1";
      };
      bgp = {
        routerId = "10.254.0.1";
        neighbors = {
          rtr-noisy = {
            ip = "10.254.0.11";
            as = 65000;
            updateSource = "lo";
            ebgpMultihop = 5;
            addressFamilies = [ "ipv4 unicast" ];
          };
          # Additional neighbors...
        };
        networks = [ "10.254.0.1/32" ];
      };
    };
    
    security = {
      ssh = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
        ];
      };
    };
  };
}
```

## 🌿 Leaf Role

### Default Configuration

The leaf role (`modules/roles/leaf.nix`) provides standard configuration for all leaf nodes:

- **Networking**: Loopback interfaces (IPv4), IP addressing
- **WireGuard**: Standard WireGuard configuration, point-to-spine
- **FRR**: BGP IPv4 + EVPN/VXLAN for overlay networks
- **Security**: System hardening, SSH (Fail2ban disabled by default)

### Leaf Characteristics

```nix
{
  # Standard leaf networking (IPv4 only)
  networking = {
    loopback = {
      ipv4 = [ { address = "10.254.0.X"; prefixLength = 32; } ];
    };
  };

  # Standard leaf WireGuard (point-to-spine)
  wireguard = {
    interfaceName = "wgtransport";
    listenPort = 51820;
    ips = [ "10.255.0.X/24" ];
  };

  # Standard leaf FRR (BGP + EVPN)
  frr = {
    bgp = { 
      enable = true; 
      as = 65000;
      routerId = "10.254.0.X";
      clusterId = "10.254.0.X";
      neighbors = {
        spine1 = {
          ip = "10.254.0.1";
          as = 65000;
          updateSource = "lo";
          ebgpMultihop = 5;
          addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
        };
      };
      networks = [ "10.254.0.X/32" ];
      addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
    };
    evpn = {
      enable = true;
      neighbors = [ "10.254.0.1" ];
    };
  };

  # Standard leaf security (no Fail2ban)
  security = {
    fail2ban = { enable = false; };
    hardening = { enable = true; };
  };
}
```

### Pure Leaf Example

```nix
# hosts/pure-leaf/role-variables.nix
{ ... }:
{
  network-fabric.roles.leaf = {
    enable = true;
    roleId = "leaf1";
    
    networking = {
      loopback = {
        ipv4 = [ { address = "10.254.0.21"; prefixLength = 32; } ];
      };
    };
    
    wireguard = {
      privateKeyFile = "/etc/wireguard/pure-leaf.key";
      ips = [ "10.255.0.21/24" ];
      peers = {
        vm-sapinet = { ... };
        rtr-noisy = { ... };
      };
    };
    
    frr = {
      bgp = {
        routerId = "10.254.0.21";
        clusterId = "10.254.0.21";
        neighbors = {
          vm-sapinet = { ... };
          rtr-noisy = { ... };
        };
        addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
      };
      evpn = {
        neighbors = [ "10.254.0.1" "10.254.0.11" ];
      };
    };
    
    security = {
      ssh = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
        ];
      };
    };
  };
}
```

## 🤖 Hybrid Nodes

### Hybrid Architecture

Hybrid nodes (like rtr-noisy) can simultaneously act as both spine and leaf routers:

**Spine Role (Core Routing):**
- OSPF for dynamic routing
- BGP IPv4 unicast
- Full mesh WireGuard
- IPv4 + IPv6 support

**Leaf Role (Edge Services):**
- BGP IPv4 unicast + EVPN
- VXLAN overlay networks
- Point-to-spine WireGuard
- IPv4 primary

### Hybrid Node Benefits

1. **Resilience**: Can route at multiple network layers
2. **Flexibility**: Adapts to different network conditions
3. **Efficiency**: Single node handles multiple roles
4. **Redundancy**: Provides backup routing paths

### Hybrid Node Example (rtr-noisy)

```nix
# hosts/rtr-noisy/role-variables.nix
{ ... }:
{
  network-fabric.roles = {
    # Spine role for core routing
    spine = {
      enable = true;
      roleId = "spine2";
      
      networking = {
        loopback = {
          ipv4 = [ { address = "10.254.0.11"; prefixLength = 32; } ];
          ipv6 = [ { address = "fd42:1337:254::11"; prefixLength = 128; } ];
        };
      };
      
      wireguard = {
        privateKeyFile = "/etc/wireguard/rtr-noisy.key";
        ips = [ "10.255.0.11/24" "fd42:1337:255::11/64" ];
        peers = {
          vm-sapinet = {
            publicKey = "__SAPINET_PUB__";
            endpoint = "45.90.162.251:51820";
            allowedIPs = [
              "10.255.0.1/32"      # vm-sapinet WireGuard IP
              "fd42:1337:255::1/128"  # vm-sapinet IPv6
              "10.254.0.1/32"      # vm-sapinet loopback
              "fd42:1337:254::1/128"  # vm-sapinet IPv6 loopback
            ];
            persistentKeepalive = 25;
          };
        };
      };
      
      frr = {
        ospf = {
          enable = true;
          routerId = "10.254.0.11";
          area = 0;
          networks = [
            "10.254.0.11/32"      # This node's loopback
            "10.255.0.0/24"       # WireGuard network
          ];
          passiveInterfaces = [ "default" "wgtransport" ];
        };
        
        bgp = {
          enable = true;
          as = 65000;
          routerId = "10.254.0.11";
          neighbors = {
            vm-sapinet = {
              ip = "10.254.0.1";
              as = 65000;
              updateSource = "lo";
              ebgpMultihop = 5;
              addressFamilies = [ "ipv4 unicast" ];
            };
          };
          networks = [ "10.254.0.11/32" ];
        };
      };
      
      security = {
        ssh = {
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
          ];
        };
      };
    };
    
    # Leaf role for edge services
    leaf = {
      enable = true;
      roleId = "leaf1";
      
      networking = {
        loopback = {
          ipv4 = [ { address = "10.254.0.11"; prefixLength = 32; } ];
        };
      };
      
      wireguard = {
        privateKeyFile = "/etc/wireguard/rtr-noisy.key";
        ips = [ "10.255.0.11/24" ];
        peers = {
          vm-sapinet = {
            publicKey = "__SAPINET_PUB__";
            endpoint = "45.90.162.251:51820";
            allowedIPs = [
              "10.255.0.1/32"      # vm-sapinet WireGuard IP
              "fd42:1337:255::1/128"  # vm-sapinet IPv6
              "10.254.0.1/32"      # vm-sapinet loopback
              "fd42:1337:254::1/128"  # vm-sapinet IPv6 loopback
            ];
            persistentKeepalive = 25;
          };
        };
      };
      
      frr = {
        bgp = {
          enable = true;
          as = 65000;
          routerId = "10.254.0.11";
          clusterId = "10.254.0.11";
          neighbors = {
            vm-sapinet = {
              ip = "10.254.0.1";
              as = 65000;
              updateSource = "lo";
              ebgpMultihop = 5;
              addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
            };
          };
          networks = [ "10.254.0.11/32" ];
          addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
        };
        
        evpn = {
          enable = true;
          neighbors = [ "10.254.0.1" ];
        };
      };
      
      security = {
        ssh = {
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
          ];
        };
      };
    };
  };
}
```

### Corresponding default.nix for Hybrid Node

```nix
# hosts/rtr-noisy/default.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./base-variables.nix
    ./role-variables.nix
    ../../modules/base.nix
    ../../modules/networking.nix
    ../../modules/wireguard.nix
    ../../modules/frr.nix
    ../../modules/security.nix
    ../../modules/roles/spine.nix  # Spine role
    ../../modules/roles/leaf.nix   # Leaf role
  ];

  # Host-specific settings
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Fix systemd-networkd credentials issue
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = lib.mkForce [ ];
    LoadCredentialEncrypted = lib.mkForce [ ];
    SetCredential = lib.mkForce [ ];
    SetCredentialEncrypted = lib.mkForce [ ];
  };
}
```

## 🗃️ Host Configuration Pattern

Each host follows this pattern:

### 1. `hardware-configuration.nix`
- **Purpose**: Hardware-specific settings that shouldn't be versioned
- **Content**: Disk layouts, filesystem configurations, hardware-specific drivers
- **Note**: This file is typically generated by `nixos-generate-config`

### 2. `base-variables.nix`
- **Purpose**: Host-specific overrides for base module
- **Content**:
  - Package lists
  - User configurations
  - System settings overrides
  - Console configurations

### 3. `role-variables.nix`
- **Purpose**: Main host configuration variables
- **Content**:
  - Role activation (spine, leaf, or both)
  - Networking settings (IPs, gateways, DNS)
  - WireGuard configuration (peers, keys, endpoints)
  - FRR settings (BGP neighbors, OSPF areas)
  - Security settings (SSH, firewall, hardening)

### 4. `default.nix`
- **Purpose**: Minimal main configuration
- **Content**:
  - Module imports
  - Host-specific tweaks (kernel parameters, services)
  - Hardware-specific workarounds
  - **Should be as small as possible**

## 🚀 Adding a New Host

### Step 1: Create Host Directory

```bash
mkdir -p hosts/new-host
```

### Step 2: Create Hardware Configuration

On the new host, run:
```bash
sudo nixos-generate-config --show-hardware-config > hosts/new-host/hardware-configuration.nix
```

### Step 3: Create Base Variables

```nix
# hosts/new-host/base-variables.nix
{ ... }:
{
  network-fabric.base = {
    enable = true;
    
    packages = [
      "git"
      "curl"
      "vim"
      "wireguard-tools"
      "frr"
      "apparmor-utils"
    ];
    
    users = {
      franck = {
        enable = true;
        sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host";
      };
    };
    
    system = {
      stateVersion = "25.11";
      console = {
        keyMap = "fr";
      };
    };
  };
}
```

### Step 4: Create Role Variables

**Pure Spine:**
```nix
# hosts/new-host/role-variables.nix
{ ... }:
{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine3";
    # Spine configuration...
  };
}
```

**Pure Leaf:**
```nix
# hosts/new-host/role-variables.nix
{ ... }:
{
  network-fabric.roles.leaf = {
    enable = true;
    roleId = "leaf2";
    # Leaf configuration...
  };
}
```

**Hybrid (Spine + Leaf):**
```nix
# hosts/new-host/role-variables.nix
{ ... }:
{
  network-fabric.roles = {
    spine = { enable = true; roleId = "spine3"; };
    leaf = { enable = true; roleId = "leaf2"; };
  };
}
```

### Step 5: Create Minimal default.nix

```nix
# hosts/new-host/default.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./base-variables.nix
    ./role-variables.nix
    ../../modules/base.nix
    ../../modules/networking.nix
    ../../modules/wireguard.nix
    ../../modules/frr.nix
    ../../modules/security.nix
    ../../modules/roles/spine.nix  # For spine or hybrid
    ../../modules/roles/leaf.nix   # For leaf or hybrid
  ];

  # Host-specific kernel parameters
  boot.kernelParams = [
    "lockdown=confidentiality"
    "slab_nomerge"
    "pti=on"
  ];

  # Host-specific services
  services.journald.extraConfig = ''
    Storage=persistent
    Compress=yes
    SystemMaxUse=512M
  '';
}
```

### Step 6: Add to Flake

```nix
# flake.nix
{
  nixosConfigurations = {
    "new-host" = mkHost { system = "x86_64-linux"; hostname = "new-host"; };
    # ... existing hosts
  };
}
```

## 🎛️ Configuration Hierarchy

```
Module Defaults
    ↓
Role Defaults (spine/leaf)
    ↓
Role Variables (host-specific)
    ↓
Base Variables (host-specific)
    ↓
Host-Specific Tweaks (default.nix)
```

**Merge Strategy:**
- `lib.mkMerge` for deep merging of nested structures
- Later stages override earlier stages
- Explicit overrides in later stages take precedence

## ✨ Benefits of Role-Based System

### 1. Consistency
- All spine nodes automatically get the same base configuration
- All leaf nodes automatically get the same base configuration
- Hybrid nodes get both configurations automatically
- Reduces configuration drift across the network

### 2. Maintainability
- Change spine behavior in one place (`modules/roles/spine.nix`)
- Change leaf behavior in one place (`modules/roles/leaf.nix`)
- No need to update multiple host configurations
- Changes propagate automatically to all nodes with that role

### 3. Scalability
- Add new spine: just set `network-fabric.roles.spine.enable = true`
- Add new leaf: just set `network-fabric.roles.leaf.enable = true`
- Add new hybrid: enable both roles
- Role handles all the standard configuration

### 4. Flexibility
- Hybrid nodes can serve multiple roles simultaneously
- Hosts can still override role defaults when needed
- Role variables allow per-host customization
- Host-specific tweaks in `default.nix`

### 5. Hybrid Capability
- Single node can route at multiple network layers
- Provides redundancy and resilience
- Adapts to changing network conditions
- Optimizes resource utilization

## 📋 Role Comparison

| Feature | Pure Spine | Pure Leaf | Hybrid Node |
|---------|-----------|----------|-------------|
| **Primary Function** | Core routing | Edge services | Core + Edge |
| **Routing Protocols** | OSPF + BGP | BGP + EVPN | OSPF + BGP + EVPN |
| **WireGuard** | Full mesh | Point-to-spine | Full mesh + Point-to-spine |
| **IPv6** | Full support | Optional | Full support |
| **Fail2ban** | Enabled | Disabled | Enabled (spine role) |
| **EVPN/VXLAN** | Disabled | Enabled | Enabled (leaf role) |
| **OSPF** | Enabled | Disabled | Enabled (spine role) |
| **Complexity** | Medium | Medium | High |
| **Use Case** | Core network | Edge network | Core + Edge |

## 🚀 Hybrid Node Management

### Verifying Hybrid Configuration

```bash
# Check which roles are active
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles

# Check FRR has both OSPF and BGP+EVPN
vtysh -c "show running-config"

# Verify OSPF neighbors (spine role)
vtysh -c "show ip ospf neighbor"

# Verify BGP sessions (both roles)
vtysh -c "show ip bgp summary"

# Verify EVPN (leaf role)
vtysh -c "show evpn vni"
```

### Debugging Hybrid Nodes

```bash
# Check role merging
nix repl
:l <nixpkgs/nixos/lib/eval-config.nix>
config = evalModules { 
  modules = [
    ./modules/roles/spine.nix
    ./modules/roles/leaf.nix
  ]; 
} {}

# Check FRR generated configuration
sudo cat /etc/frr/frr.conf

# Check WireGuard peers
sudo wg show wgtransport
```

### Modifying Hybrid Node Behavior

To change behavior for all hybrid nodes, modify the individual role definitions:

```bash
# Edit spine role (affects all spines including hybrids)
nano modules/roles/spine.nix

# Edit leaf role (affects all leaves including hybrids)
nano modules/roles/leaf.nix
```

## 📚 Module Reference

### Spine Role Options

```nix
network-fabric.roles.spine = {
  enable = true/false;          # Enable spine role
  roleId = "spine1";            # Unique spine identifier
  
  networking = { ... };        # Networking overrides
  wireguard = { ... };         # WireGuard overrides
  frr = { ... };               # FRR overrides
  security = { ... };          # Security overrides
}
```

### Leaf Role Options

```nix
network-fabric.roles.leaf = {
  enable = true/false;          # Enable leaf role
  roleId = "leaf1";             # Unique leaf identifier
  
  networking = { ... };        # Networking overrides
  wireguard = { ... };         # WireGuard overrides
  frr = { ... };               # FRR overrides
  security = { ... };          # Security overrides
}
```

### Hybrid Role Configuration

```nix
network-fabric.roles = {
  spine = { enable = true; roleId = "spineX"; };
  leaf = { enable = true; roleId = "leafY"; };
}
```

## 🎉 Summary

The role-based system provides:

1. **Consistency**: All nodes with same role have identical base configuration
2. **Maintainability**: Change behavior in one place for all nodes
3. **Scalability**: Easy to add new nodes with any role combination
4. **Flexibility**: Hybrid nodes can serve multiple roles simultaneously
5. **Clarity**: Clear separation of role vs host configuration
6. **Hybrid Capability**: Single node can route at multiple network layers

This system enables advanced network architectures where nodes can simultaneously act as both spine and leaf routers, providing maximum flexibility and resilience. For complete documentation on the modular architecture, see [STRUCTURE.md](STRUCTURE.md) and [EXAMPLES.md](EXAMPLES.md).