# NixOS Fabric Structure Reference - Hybrid Architecture

This document explains the modular structure of the NixOS fabric repository with hybrid node capabilities, designed for maximum flexibility and resilience.

## 🎯 Design Goals

1. **Hybrid Capability**: Nodes can simultaneously act as spine and leaf
2. **Role-Based Configuration**: Clear separation between spine, leaf, and hybrid roles
3. **Modularity**: Each network component is isolated and reusable
4. **Consistency**: All nodes with same role have identical base configuration
5. **Flexibility**: Easy per-host customization when needed
6. **Scalability**: Simple to add new nodes with any role combination

## 📂 Directory Structure

```
nixos-fabric/
├── docs/                  # Documentation
│   ├── deployment/        # Deployment guides
│   ├── reference/         # Architecture & examples
│   │   ├── STRUCTURE.md   # This file - structure reference
│   │   ├── ROLES.md       # Role system documentation
│   │   └── EXAMPLES.md    # Configuration examples
│   └── troubleshooting/   # Issue resolution guides
│
├── hosts/                 # Host configurations
│   ├── vm-sapinet/        # Pure spine node
│   │   ├── hardware-configuration.nix  # Hardware-specific (generated)
│   │   ├── base-variables.nix         # Base configuration overrides
│   │   ├── role-variables.nix          # Spine role variables
│   │   └── default.nix                # Minimal host-specific tweaks (15-20 lines)
│   │
│   └── rtr-noisy/         # Hybrid node (spine + leaf)
│       ├── hardware-configuration.nix  # Hardware-specific (generated)
│       ├── base-variables.nix         # Base configuration overrides
│       ├── role-variables.nix          # BOTH spine AND leaf role variables
│       └── default.nix                # Minimal host-specific tweaks (15-20 lines)
│
├── modules/               # Modular configuration system
│   ├── base.nix            # Common base configuration (users, packages, system)
│   ├── networking.nix      # Network configuration module (interfaces, DNS, gateways)
│   ├── wireguard.nix       # WireGuard configuration module (interfaces, peers, firewall)
│   ├── frr.nix             # FRR configuration module (BGP, OSPF, EVPN)
│   ├── security.nix        # Security configuration module (SSH, firewall, hardening)
│   └── roles/              # Role-based configuration system
│       ├── spine.nix       # Spine role definition (OSPF + BGP + IPv6)
│       └── leaf.nix        # Leaf role definition (BGP + EVPN)
│
├── scripts/               # Deployment and management scripts
│   ├── deploy-wireguard.sh # WireGuard key generation
│   ├── check-fabric.sh     # Connectivity verification
│   └── deploy-and-verify.sh # Interactive deployment tool
│
└── flake.nix              # Flake configuration (host definitions)
```

## 🔧 Module System

### Base Module (`modules/base.nix`)

Handles common configuration across all hosts:
- Package management (git, curl, vim, etc.)
- User creation and SSH keys
- System settings (state version, console keymap)
- Basic services (journald, apparmor, auditd)

### Networking Module (`modules/networking.nix`)

Manages all networking aspects:
- Hostname and timezone configuration
- DNS servers and search domains
- Interface configuration (including loopback)
- Default gateways and routing
- IP forwarding settings

### WireGuard Module (`modules/wireguard.nix`)

Encapsulates WireGuard configuration:
- Interface creation and IP addressing
- Peer management with public keys and endpoints
- Firewall rules for WireGuard traffic
- Key management paths and permissions

### FRR Module (`modules/frr.nix`)

Handles routing protocols:
- BGP configuration (neighbors, address families)
- OSPF configuration (areas, networks, passive interfaces)
- EVPN/VXLAN support for overlay networks
- Router IDs and AS numbers
- Route maps and prefix lists

### Security Module (`modules/security.nix`)

Centralizes security configuration:
- SSH server settings (port, authentication, keys)
- Firewall rules (nftables) with rate limiting
- Fail2ban configuration with multiple jails
- System hardening (sysctl settings for kernel, FS, network)
- AppArmor and auditd integration

## 🗃️ Role System

The role system enables nodes to have specific configurations based on their network function.

### Spine Role (`modules/roles/spine.nix`)

**Pure spine nodes** (like vm-sapinet):
- Core routing functionality
- OSPF for dynamic routing
- BGP IPv4/IPv6 for inter-domain routing
- Full mesh WireGuard connectivity
- IPv4 + IPv6 dual stack
- Fail2ban for security

**Default spine configuration:**
```nix
{
  networking = {
    loopback = { ipv4 = [ "10.254.0.X/32" ]; ipv6 = [ "fd42:1337:254::X/128" ] };
  };
  wireguard = { interfaceName = "wgtransport"; listenPort = 51820; };
  frr = {
    ospf = { enable = true; area = 0; };
    bgp = { enable = true; as = 65000; addressFamilies = [ "ipv4 unicast" ]; };
  };
  security = { fail2ban = { enable = true; }; };
}
```

### Leaf Role (`modules/roles/leaf.nix`)

**Pure leaf nodes**:
- Edge routing and services
- BGP IPv4 for core connectivity
- EVPN/VXLAN for overlay networks
- Point-to-spine WireGuard
- IPv4 primary (IPv6 optional)
- No Fail2ban by default

**Default leaf configuration:**
```nix
{
  networking = { loopback = { ipv4 = [ "10.254.0.X/32" ] } };
  wireguard = { interfaceName = "wgtransport"; listenPort = 51820; };
  frr = {
    bgp = { enable = true; as = 65000; addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ]; };
    evpn = { enable = true; };
  };
  security = { fail2ban = { enable = false; }; };
}
```

### Hybrid Nodes

**Nodes like rtr-noisy** can have **both roles simultaneously**:
```nix
{
  network-fabric.roles = {
    spine = { enable = true; roleId = "spine2"; };
    leaf = { enable = true; roleId = "leaf1"; };
  };
}
```

This creates a node that:
- Routes at the core layer (OSPF + BGP)
- Provides edge services (EVPN + VXLAN)
- Participates in full mesh (spine role)
- Connects to spine nodes (leaf role)

## 🗃️ Host Configuration Pattern

Each host follows this pattern:

### 1. `hardware-configuration.nix`
- **Purpose**: Hardware-specific settings
- **Content**: Disk layouts, filesystem configurations, hardware drivers
- **Note**: Generated by `nixos-generate-config`, typically not versioned

### 2. `base-variables.nix`
- **Purpose**: Host-specific overrides for base module
- **Content**:
  - Package lists (common + host-specific)
  - User configurations and SSH keys
  - System settings overrides
  - Console and localization settings

**Example (vm-sapinet):**
```nix
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

### 3. `role-variables.nix`
- **Purpose**: Role-specific configuration
- **Content**:
  - Role activation (spine, leaf, or both)
  - Networking settings (IPs, gateways, DNS)
  - WireGuard configuration (peers, keys, endpoints)
  - FRR settings (BGP neighbors, OSPF areas)
  - Security settings (SSH, firewall, hardening)

**Pure spine example (vm-sapinet):**
```nix
{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine1";
    networking = { loopback = { ipv4 = [ "10.254.0.1/32" ] } };
    wireguard = { peers = { rtr-noisy = { ... } } };
    frr = { bgp = { neighbors = { rtr-noisy = { ... } } } };
  };
}
```

**Hybrid example (rtr-noisy):**
```nix
{
  network-fabric.roles = {
    spine = { enable = true; roleId = "spine2"; };
    leaf = { enable = true; roleId = "leaf1"; };
  };
}
```

### 4. `default.nix`
- **Purpose**: Minimal main configuration
- **Content**:
  - Module imports (hardware, base, roles, networking, etc.)
  - Host-specific tweaks (kernel parameters, services)
  - Hardware-specific workarounds
  - **Should be as small as possible** (typically 15-20 lines)

**Example (vm-sapinet):**
```nix
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
    ../../modules/roles/spine.nix  # Pure spine
  ];

  # Host-specific kernel parameters
  boot.kernelParams = [ "lockdown=confidentiality" "slab_nomerge" "pti=on" ];
}
```

**Hybrid example (rtr-noisy):**
```nix
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
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
}
```

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

### Step 3: Choose Host Type

Decide whether the host will be:
- **Pure spine**: Core routing only
- **Pure leaf**: Edge services only
- **Hybrid**: Both core and edge routing

### Step 4: Create Base Variables

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

### Step 5: Create Role Variables

**Pure Spine:**
```nix
# hosts/new-host/role-variables.nix
{ ... }:
{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine3";
    
    networking = {
      loopback = {
        ipv4 = [ { address = "10.254.0.3"; prefixLength = 32; } ];
        ipv6 = [ { address = "fd42:1337:254::3"; prefixLength = 128; } ];
      };
    };
    
    wireguard = {
      privateKeyFile = "/etc/wireguard/new-spine.key";
      ips = [ "10.255.0.3/24" "fd42:1337:255::3/64" ];
      peers = {
        vm-sapinet = { ... };
        rtr-noisy = { ... };
      };
    };
    
    frr = {
      ospf = {
        routerId = "10.254.0.3";
        networks = [ "10.254.0.3/32" "10.255.0.0/24" ];
      };
      bgp = {
        routerId = "10.254.0.3";
        neighbors = {
          vm-sapinet = { ... };
          rtr-noisy = { ... };
        };
      };
    };
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
    
    networking = {
      loopback = {
        ipv4 = [ { address = "10.254.0.21"; prefixLength = 32; } ];
      };
    };
    
    wireguard = {
      privateKeyFile = "/etc/wireguard/new-leaf.key";
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
  };
}
```

**Hybrid (Spine + Leaf):**
```nix
# hosts/new-host/role-variables.nix
{ ... }:
{
  network-fabric.roles = {
    spine = {
      enable = true;
      roleId = "spine3";
      # Spine configuration...
    };
    leaf = {
      enable = true;
      roleId = "leaf2";
      # Leaf configuration...
    };
  };
}
```

### Step 6: Create Minimal default.nix

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

  # Host-specific tweaks
  boot.kernelParams = [ "lockdown=confidentiality" "slab_nomerge" "pti=on" ];

  # Host-specific services
  services.journald.extraConfig = ''
    Storage=persistent
    Compress=yes
    SystemMaxUse=512M
  '';
}
```

### Step 7: Add to Flake

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
Module Defaults (modules/wireguard.nix, etc.)
    ↓
Role Defaults (modules/roles/spine.nix or leaf.nix)
    ↓
Role Variables (hosts/<host>/role-variables.nix)
    ↓
Base Variables (hosts/<host>/base-variables.nix)
    ↓
Host-Specific Tweaks (hosts/<host>/default.nix)
```

**Merge Strategy:**
- `lib.mkMerge` for deep merging of nested structures
- Later stages override earlier stages
- Explicit overrides in later stages take precedence

## 🔄 Common Configuration Patterns

### Adding a New Peer

**To a pure spine node:**
```nix
# In hosts/vm-sapinet/role-variables.nix
{
  network-fabric.roles.spine.wireguard.peers.new-peer = {
    publicKey = "NEW_PEER_PUB_KEY";
    endpoint = "NEW_PEER_IP:51820";
    allowedIPs = [ "10.255.0.X/32" "10.254.0.X/32" ];
    persistentKeepalive = 25;
  };
  
  network-fabric.roles.spine.frr.bgp.neighbors.new-peer = {
    ip = "10.254.0.X";
    as = 65000;
    updateSource = "lo";
    ebgpMultihop = 5;
  };
}
```

**To a hybrid node:**
```nix
# In hosts/rtr-noisy/role-variables.nix
{
  network-fabric.roles.spine.wireguard.peers.new-peer = { ... };
  network-fabric.roles.spine.frr.bgp.neighbors.new-peer = { ... };
  
  network-fabric.roles.leaf.wireguard.peers.new-peer = { ... };
  network-fabric.roles.leaf.frr.bgp.neighbors.new-peer = { ... };
}
```

### Customizing Security Settings

```nix
# In hosts/<host>/role-variables.nix
{
  network-fabric.roles.spine.security = {
    ssh = {
      port = 2222;
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... key" ];
    };
    fail2ban = {
      jails = {
        sshd = {
          maxretry = 3;
          bantime = "2h";
        };
      };
    };
  };
}
```

### Overriding Module Defaults

```nix
# In hosts/<host>/role-variables.nix
{
  network-fabric.roles.spine.wireguard.listenPort = 51821;
  network-fabric.roles.spine.frr.bgp.as = 65001;
}
```

## 📋 Best Practices

### 1. Keep `default.nix` Minimal

✅ **Good**: Only host-specific tweaks that can't go in variables
❌ **Bad**: Putting configuration data in default.nix

### 2. Use Roles for Common Configuration

✅ **Good**: Put shared spine configuration in `modules/roles/spine.nix`
❌ **Bad**: Duplicate configuration in each spine's `role-variables.nix`

### 3. Follow the Hierarchy

✅ **Good**: Module → Role → Variables → Host
❌ **Bad**: Skip levels or mix concerns

### 4. Document Overrides

✅ **Good**: Comment why you're overriding a default
❌ **Bad**: Silent overrides without explanation

### 5. Test Incrementally

✅ **Good**: Add one module at a time and test
❌ **Bad**: Big bang migration without testing

### 6. Use Consistent Naming

✅ **Good**: Follow existing patterns for peer names, interface names
❌ **Bad**: Invent new naming schemes

## 🔧 Debugging Tips

### Check Module Options

```bash
nix repl
:l <nixpkgs/nixos/lib/eval-config.nix>
config = evalModules { 
  modules = [./modules/roles/spine.nix]; 
} {}
config.options.network-fabric.roles.spine
```

### Test Configuration

```bash
nix eval .#nixosConfigurations.HOSTNAME.config.networking.hostName
nix build .#nixosConfigurations.HOSTNAME.config.system.build.toplevel --no-link
```

### Check Generated Configuration

```bash
sudo nixos-rebuild dry-activate --flake .#HOSTNAME
nix eval .#nixosConfigurations.HOSTNAME.config.services.frr.config
```

### Verify Hybrid Node Roles

```bash
# Check which roles are active
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles

# Check role merging
nix repl
config = evalModules { 
  modules = [
    ./modules/roles/spine.nix
    ./modules/roles/leaf.nix
  ]; 
} {}
```

## 📚 Module Reference

### Base Module Options

```nix
network-fabric.base = {
  enable = true/false;          # Enable base module
  packages = [ "pkg1" "pkg2" ]; # Package list
  users.franck = {              # User configuration
    enable = true/false;
    sshKey = "public_key";
  };
  system = {                    # System settings
    stateVersion = "version";
    console.keyMap = "keymap";
  };
}
```

### Networking Module Options

```nix
network-fabric.networking = {
  enable = true/false;
  hostName = "hostname";
  timeZone = "timezone";
  nameservers = [ "dns1" "dns2" ];
  defaultGateway = {
    enable = true/false;
    address = "gateway_ip";
    interface = "interface";
  };
  interfaces = { ... };        # Interface configurations
  loopback = { ... };          # Loopback configuration
}
```

### WireGuard Module Options

```nix
network-fabric.wireguard = {
  enable = true/false;
  interfaceName = "wg0";
  listenPort = 51820;
  privateKeyFile = "/path/to/key";
  ips = [ "ip1" "ip2" ];
  peers = {                    # Peer configurations
    peer1 = {
      publicKey = "pubkey";
      endpoint = "host:port";
      allowedIPs = [ "ip1" "ip2" ];
      persistentKeepalive = 25;
    };
  };
}
```

### FRR Module Options

```nix
network-fabric.frr = {
  enable = true/false;
  bgp = {
    enable = true/false;
    as = 65000;
    routerId = "10.0.0.1";
    neighbors = {              # BGP neighbors
      neighbor1 = {
        ip = "10.0.0.2";
        as = 65001;
        updateSource = "lo";
        ebgpMultihop = 5;
      };
    };
    networks = [ "10.0.0.0/24" ];
    addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
  };
  ospf = {
    enable = true/false;
    routerId = "10.0.0.1";
    area = 0;
    networks = [ "10.0.0.0/24" ];
    passiveInterfaces = [ "eth0" "eth1" ];
  };
}
```

### Security Module Options

```nix
network-fabric.security = {
  enable = true/false;
  ssh = {
    enable = true/false;
    port = 22;
    permitRootLogin = "prohibit-password";
    passwordAuthentication = false;
    authorizedKeys = [ "key1" "key2" ];
  };
  firewall = {
    enable = true/false;
    allowedServices = [ "ssh" "wireguard" ];
    rateLimits.ssh = {
      enable = true/false;
      rate = "15/minute";
      burst = 20;
    };
  };
  fail2ban = {
    enable = true/false;
    jails.sshd = {
      enabled = true/false;
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
    };
  };
  hardening = {
    enable = true/false;
    # Kernel, FS, and network hardening options
  };
}
```

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

## 🎉 Benefits of This Structure

1. **Hybrid Capability**: Nodes can serve multiple roles simultaneously
2. **Consistency**: All nodes with same role have identical base configuration
3. **Reusability**: Modules can be shared across multiple projects
4. **Maintainability**: Changes to common functionality are made in one place
5. **Scalability**: Adding new nodes requires minimal new code
6. **Clarity**: Separation of concerns makes configuration easier to understand
7. **Testability**: Modules can be tested independently
8. **Flexibility**: Easy to create new role types as needed

This structure provides a flexible, scalable, and maintainable network fabric with hybrid node capabilities for advanced networking scenarios. For complete documentation on the role system, see [ROLES.md](ROLES.md).