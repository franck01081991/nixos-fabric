# Role-Based Configuration System

This document explains the role-based configuration system that ensures all spine nodes have consistent roles and configuration.

## 🎯 Overview

The role-based system provides a way to standardize configuration across different types of nodes in the network fabric. This ensures that:

1. **All spine nodes have identical base configuration**
2. **All leaf nodes have identical base configuration**
3. **Role-specific defaults are applied automatically**
4. **Host-specific customization is still possible**

## 📂 Role Structure

```
modules/roles/
├── spine.nix      # Spine role definition
└── leaf.nix       # Leaf role definition

hosts/<hostname>/
├── role-variables.nix  # Role-specific variables
└── default.nix         # Host configuration (imports role)
```

## 🔧 Spine Role

### Default Configuration

The spine role (`modules/roles/spine.nix`) provides standard configuration for all spine nodes:

- **Networking**: Loopback interfaces, IP addressing
- **WireGuard**: Standard WireGuard configuration
- **FRR**: OSPF + BGP routing
- **Security**: Fail2ban, hardening, SSH
- **System**: Journal, AppArmor, Audit

### Spine Characteristics

```nix
{
  # Standard spine networking
  networking = {
    loopback = {
      ipv4 = [ { address = "10.254.0.X"; prefixLength = 32; } ];
      ipv6 = [ { address = "fd42:1337:254::X"; prefixLength = 128; } ];
    };
  };

  # Standard spine WireGuard
  wireguard = {
    interfaceName = "wgtransport";
    listenPort = 51820;
    ips = [ "10.255.0.X/24" "fd42:1337:255::X/64" ];
  };

  # Standard spine FRR (OSPF + BGP)
  frr = {
    ospf = { enable = true; area = 0; };
    bgp = { enable = true; as = 65000; addressFamilies = [ "ipv4 unicast" ]; };
  };

  # Standard spine security
  security = {
    fail2ban = { enable = true; };
    hardening = { enable = true; };
  };
}
```

## 🌿 Leaf Role

### Default Configuration

The leaf role (`modules/roles/leaf.nix`) provides standard configuration for all leaf nodes:

- **Networking**: Loopback interfaces, IP addressing
- **WireGuard**: Standard WireGuard configuration
- **FRR**: BGP + EVPN routing
- **Security**: Hardening, SSH (no Fail2ban by default)

### Leaf Characteristics

```nix
{
  # Standard leaf networking
  networking = {
    loopback = {
      ipv4 = [ { address = "10.254.0.X"; prefixLength = 32; } ];
    };
  };

  # Standard leaf WireGuard
  wireguard = {
    interfaceName = "wgtransport";
    listenPort = 51820;
    ips = [ "10.255.0.X/24" ];
  };

  # Standard leaf FRR (BGP + EVPN)
  frr = {
    bgp = { enable = true; as = 65000; addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ]; };
    evpn = { enable = true; };
  };

  # Standard leaf security
  security = {
    fail2ban = { enable = false; };  # Typically not needed on leaf
    hardening = { enable = true; };
  };
}
```

## 🗃️ Host Configuration with Roles

### Spine Host Example (vm-sapinet)

```nix
# hosts/vm-sapinet/role-variables.nix
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
      peers = {
        rtr-noisy = { ... };
        bondy = { ... };
        lepre = { ... };
      };
    };
    
    frr = {
      bgp = {
        neighbors = {
          rtr-noisy = { ... };
          bondy = { ... };
          lepre = { ... };
        };
      };
    };
  };
}
```

```nix
# hosts/vm-sapinet/default.nix
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
    ../../modules/roles/spine.nix  # Import spine role
  ];
  
  # Host-specific tweaks only
  boot.kernelParams = [ "lockdown=confidentiality" "slab_nomerge" "pti=on" ];
  # ... other host-specific settings
}
```

### Leaf Host Example (rtr-noisy)

```nix
# hosts/rtr-noisy/role-variables.nix
{
  network-fabric.roles.leaf = {
    enable = true;
    roleId = "leaf1";
    
    # Override defaults for this specific leaf
    networking = {
      loopback = {
        ipv4 = [ { address = "10.254.0.11"; prefixLength = 32; } ];
      };
    };
    
    wireguard = {
      privateKeyFile = "/etc/wireguard/rtr-noisy.key";
      peers = {
        vm-sapinet = { ... };
      };
    };
    
    frr = {
      bgp = {
        neighbors = {
          vm-sapinet = { ... };
        };
      };
      evpn = {
        neighbors = [ "10.254.0.1" ];
      };
    };
  };
}
```

```nix
# hosts/rtr-noisy/default.nix
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
    ../../modules/roles/leaf.nix  # Import leaf role
  ];
  
  # Host-specific tweaks only
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
  # ... other host-specific settings
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

## ✨ Benefits of Role-Based System

### 1. Consistency
- All spine nodes automatically get the same base configuration
- All leaf nodes automatically get the same base configuration
- Reduces configuration drift

### 2. Maintainability
- Change spine behavior in one place (`modules/roles/spine.nix`)
- Change leaf behavior in one place (`modules/roles/leaf.nix`)
- No need to update multiple host configurations

### 3. Scalability
- Add new spine: just set `network-fabric.roles.spine.enable = true`
- Add new leaf: just set `network-fabric.roles.leaf.enable = true`
- Role handles all the standard configuration

### 4. Flexibility
- Hosts can still override role defaults
- Role variables allow per-host customization
- Host-specific tweaks in `default.nix`

## 🚀 Adding a New Spine Node

### Step 1: Create Host Directory

```bash
mkdir -p hosts/new-spine
```

### Step 2: Create Hardware Configuration

```bash
sudo nixos-generate-config --show-hardware-config > hosts/new-spine/hardware-configuration.nix
```

### Step 3: Create Role Variables

```nix
# hosts/new-spine/role-variables.nix
{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine2";  # Unique ID for this spine
    
    networking = {
      loopback = {
        ipv4 = [ { address = "10.254.0.2"; prefixLength = 32; } ];
        ipv6 = [ { address = "fd42:1337:254::2"; prefixLength = 128; } ];
      };
    };
    
    wireguard = {
      privateKeyFile = "/etc/wireguard/new-spine.key";
      ips = [ "10.255.0.2/24" "fd42:1337:255::2/64" ];
      peers = {
        # Define peers for this spine
        leaf1 = { ... };
        leaf2 = { ... };
      };
    };
    
    frr = {
      ospf = {
        routerId = "10.254.0.2";
      };
      bgp = {
        routerId = "10.254.0.2";
        neighbors = {
          leaf1 = { ... };
          leaf2 = { ... };
        };
        networks = [ "10.254.0.2/32" ];
      };
    };
  };
}
```

### Step 4: Create Base Variables

```nix
# hosts/new-spine/base-variables.nix
{
  network-fabric.base = {
    enable = true;
    packages = [ "git" "curl" "vim" "wireguard-tools" "frr" "apparmor-utils" ];
    users = {
      franck = {
        enable = true;
        sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host";
      };
    };
  };
}
```

### Step 5: Create Minimal default.nix

```nix
# hosts/new-spine/default.nix
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
    ../../modules/roles/spine.nix
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
    SystemMaxUse=512M
  '';
}
```

### Step 6: Add to Flake

```nix
# flake.nix
{
  nixosConfigurations = {
    "new-spine" = mkHost { system = "x86_64-linux"; hostname = "new-spine"; };
    # ... existing hosts
  };
}
```

## 🔄 Modifying Role Behavior

### Change All Spine Nodes

Edit `modules/roles/spine.nix` to change behavior for all spine nodes:

```nix
# Change WireGuard port for all spines
wireguard.listenPort = 51821;

# Add new OSPF network to all spines
frr.ospf.networks = [ "10.254.0.0/24" "10.255.0.0/24" ];

# Enable additional security for all spines
security.fail2ban.jails.recidive = { enable = true; };
```

### Change All Leaf Nodes

Edit `modules/roles/leaf.nix` to change behavior for all leaf nodes:

```nix
# Enable Fail2ban for all leaves
security.fail2ban.enable = true;

# Add additional address family to all leaves
frr.bgp.addressFamilies = [ "ipv4 unicast" "l2vpn evpn" "ipv6 unicast" ];

# Change default packages for all leaves
# (Note: packages are typically in base module)
```

## 📋 Role Comparison

| Feature | Spine Role | Leaf Role |
|---------|-----------|----------|
| **Primary Function** | Core routing | Edge routing + EVPN |
| **Routing Protocols** | OSPF + BGP | BGP + EVPN |
| **WireGuard** | Full mesh | Point-to-spine |
| **Fail2ban** | Enabled | Disabled (optional) |
| **IPv6** | Full support | Optional |
| **Loopback** | IPv4 + IPv6 | IPv4 only |
| **Address Families** | IPv4 unicast | IPv4 + EVPN |
| **Security** | High | Medium |

## 🎯 Best Practices

### 1. Use Roles for Common Configuration

✅ **Good**: Put shared spine configuration in `modules/roles/spine.nix`
❌ **Bad**: Duplicate configuration in each spine's `variables.nix`

### 2. Override Only When Necessary

✅ **Good**: Override role defaults only for host-specific needs
❌ **Bad**: Redefine entire configuration in host variables

### 3. Keep default.nix Minimal

✅ **Good**: Only host-specific tweaks in `default.nix`
❌ **Bad**: Put configuration data in `default.nix`

### 4. Document Role-Specific Settings

✅ **Good**: Comment why a spine/leaf has special configuration
❌ **Bad**: Silent overrides without explanation

### 5. Test Role Changes

✅ **Good**: Test role changes on one host before applying to all
❌ **Bad**: Apply untested role changes to all nodes

## 🔧 Advanced Patterns

### Multiple Roles per Host

While typically a host has one primary role, you can combine roles:

```nix
{
  network-fabric.roles = {
    spine = { enable = true; };
    monitoring = { enable = true; };  # Additional role
  };
}
```

### Role-Specific Modules

Create role-specific modules that only apply when a role is enabled:

```nix
# modules/roles/monitoring.nix
{
  config = lib.mkIf (config.network-fabric.roles.monitoring.enable) {
    services.prometheus = { enable = true; };
    services.grafana = { enable = true; };
  };
}
```

### Conditional Configuration

Use role information to make decisions:

```nix
{
  config = lib.mkIf (config.network-fabric.roles.spine.enable) {
    # Spine-specific configuration
    services.special-spine-service = { enable = true; };
  };
}
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

## 🎉 Summary

The role-based system provides:

1. **Consistency**: All spines/leaves have identical base configuration
2. **Maintainability**: Change behavior in one place
3. **Scalability**: Easy to add new nodes
4. **Flexibility**: Per-host customization still possible
5. **Clarity**: Clear separation of role vs host configuration

This system ensures that all spine nodes have the same roles and configuration by default, while still allowing for host-specific customization when needed.

For complete documentation on the modular architecture, see [STRUCTURE.md](STRUCTURE.md).