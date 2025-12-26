# Configuration Examples for Modular Structure

This document provides practical examples for working with the new modular architecture.

## 📋 Table of Contents

1. [Basic Host Configuration](#basic-host-configuration)
2. [Adding a New Peer](#adding-a-new-peer)
3. [Customizing Security Settings](#customizing-security-settings)
4. [Advanced FRR Configuration](#advanced-frr-configuration)
5. [Network Interface Examples](#network-interface-examples)
6. [Troubleshooting Examples](#troubleshooting-examples)

## Basic Host Configuration

### Minimal Host Setup

```nix
# hosts/new-host/variables.nix
{ ... }:
{
  network-fabric = {
    networking = {
      enable = true;
      hostName = "new-host";
      timeZone = "Europe/Paris";
      
      loopback = {
        enable = true;
        ipv4 = [ { address = "10.254.0.50"; prefixLength = 32; } ];
      };
    };

    wireguard = {
      enable = true;
      interfaceName = "wgtransport";
      listenPort = 51820;
      privateKeyFile = "/etc/wireguard/new-host.key";
      ips = [ "10.255.0.50/24" ];
      
      peers = {
        spine1 = {
          publicKey = "SPINE1_PUBLIC_KEY";
          endpoint = "spine1.example.com:51820";
          allowedIPs = [ "10.255.0.1/32" "10.254.0.1/32" ];
          persistentKeepalive = 25;
        };
      };
    };

    frr = {
      enable = true;
      
      bgp = {
        enable = true;
        as = 65000;
        routerId = "10.254.0.50";
        
        neighbors = {
          spine1 = {
            ip = "10.254.0.1";
            as = 65000;
            updateSource = "lo";
            ebgpMultihop = 5;
          };
        };
        
        networks = [ "10.254.0.50/32" ];
      };
    };

    security = {
      enable = true;
      
      ssh = {
        enable = true;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host"
        ];
      };
      
      hardening = {
        enable = true;
      };
    };
  };
}
```

### Corresponding default.nix

```nix
# hosts/new-host/default.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./base-variables.nix
    ./variables.nix
    ../../modules/base.nix
    ../../modules/networking.nix
    ../../modules/wireguard.nix
    ../../modules/frr.nix
    ../../modules/security.nix
  ];

  # Host-specific kernel parameters
  boot.kernelParams = [
    "lockdown=confidentiality"
    "slab_nomerge"
  ];

  # Host-specific services
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=512M
  '';
}
```

## Adding a New Peer

### WireGuard Peer Example

```nix
# In hosts/vm-sapinet/variables.nix
{
  network-fabric.wireguard.peers.new-peer = {
    publicKey = "NEW_PEER_PUBLIC_KEY";
    endpoint = "new-peer.example.com:51820";
    allowedIPs = [
      "10.255.0.51/32"  # WireGuard IP
      "10.254.0.51/32"  # Loopback IP
    ];
    persistentKeepalive = 25;
  };
}
```

### BGP Neighbor Example

```nix
# In hosts/vm-sapinet/variables.nix
{
  network-fabric.frr.bgp.neighbors.new-peer = {
    ip = "10.254.0.51";
    as = 65001;
    updateSource = "lo";
    ebgpMultihop = 5;
    description = "New peer connection";
    addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
  };
}
```

### Complete Peer Setup

```nix
# Add to both WireGuard and BGP
{
  network-fabric = {
    wireguard.peers.new-peer = {
      publicKey = "NEW_PEER_PUB_KEY";
      endpoint = "1.2.3.4:51820";
      allowedIPs = [ "10.255.0.51/32" "10.254.0.51/32" ];
      persistentKeepalive = 25;
    };
    
    frr.bgp = {
      neighbors.new-peer = {
        ip = "10.254.0.51";
        as = 65001;
        updateSource = "lo";
        ebgpMultihop = 5;
      };
      networks = [ "10.254.0.1/32" "10.254.0.51/32" ];
    };
  };
}
```

## Customizing Security Settings

### SSH Configuration

```nix
# Custom SSH port and settings
{
  network-fabric.security.ssh = {
    enable = true;
    port = 2222;  # Custom port
    permitRootLogin = "no";
    passwordAuthentication = false;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... key1"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... key2"
    ];
  };
}
```

### Firewall Customization

```nix
# Custom firewall rules
{
  network-fabric.security.firewall = {
    enable = true;
    allowedServices = [ "ssh" "wireguard" "http" "https" ];
    rateLimits.ssh = {
      enable = true;
      rate = "10/minute";
      burst = 15;
    };
  };
}
```

### Fail2Ban Configuration

```nix
# Enhanced Fail2Ban settings
{
  network-fabric.security.fail2ban = {
    enable = true;
    jails = {
      sshd = {
        enabled = true;
        maxretry = 3;
        findtime = "5m";
        bantime = "2h";
      };
      # Additional jail for repeated offenders
      recidive = {
        enabled = true;
        findtime = "1d";
        bantime = "1w";
      };
    };
  };
}
```

### Custom Hardening

```nix
# Custom kernel hardening
{
  network-fabric.security.hardening = {
    enable = true;
    kernel = {
      kptr_restrict = 2;
      dmesg_restrict = 1;
      yama_ptrace_scope = 2;
      unprivileged_bpf_disabled = 1;
      kexec_load_disabled = 1;
      sysrq = 0;
    };
    fs = {
      protected_fifos = 2;
      protected_regular = 2;
      suid_dumpable = 0;
    };
  };
}
```

## Advanced FRR Configuration

### OSPF Configuration

```nix
# Complete OSPF setup
{
  network-fabric.frr.ospf = {
    enable = true;
    routerId = "10.254.0.1";
    area = 0;
    networks = [
      "10.254.0.1/32"
      "10.255.0.0/24"
    ];
    passiveInterfaces = [ "default" "wgtransport" ];
  };
}
```

### BGP with Multiple Address Families

```nix
# BGP with IPv4 and EVPN
{
  network-fabric.frr.bgp = {
    enable = true;
    as = 65000;
    routerId = "10.254.0.1";
    clusterId = "10.254.0.1";
    
    neighbors = {
      leaf1 = {
        ip = "10.254.0.11";
        as = 65000;
        updateSource = "lo";
        ebgpMultihop = 5;
        addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
      };
    };
    
    networks = [ "10.254.0.1/32" ];
    addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
  };
  
  frr.evpn = {
    enable = true;
    neighbors = [ "10.254.0.11" ];
  };
}
```

### Route Maps and Prefix Lists

```nix
# Advanced BGP with route filtering
{
  network-fabric.frr.bgp = {
    enable = true;
    as = 65000;
    routerId = "10.254.0.1";
    
    neighbors = {
      upstream = {
        ip = "10.254.0.254";
        as = 65001;
        updateSource = "lo";
        ebgpMultihop = 5;
        # Route map for filtering
        routeMapIn = "FILTER-IN";
        routeMapOut = "FILTER-OUT";
      };
    };
    
    # Additional FRR configuration can be extended
    # through the module system
  };
}
```

## Network Interface Examples

### Multiple Interfaces

```nix
# Complex network interface setup
{
  network-fabric.networking = {
    enable = true;
    interfaces = {
      eth0 = {
        ipv4 = [
          { address = "192.168.1.10"; prefixLength = 24; }
        ];
      };
      eth1 = {
        ipv4 = [
          { address = "10.0.0.10"; prefixLength = 24; }
        ];
        ipv6 = [
          { address = "fd00::10"; prefixLength = 64; }
        ];
      };
    };
    
    defaultGateway = {
      enable = true;
      address = "192.168.1.1";
      interface = "eth0";
    };
  };
}
```

### VLAN Interfaces

```nix
# VLAN interface configuration
{
  network-fabric.networking = {
    enable = true;
    # Note: VLANs are typically configured via systemd-networkd
    # in the host's default.nix for complex setups
  };
}
```

### DNS Configuration

```nix
# Custom DNS servers
{
  network-fabric.networking = {
    enable = true;
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
      "8.8.8.8"
      "2606:4700:4700::1111"
      "2620:fe::fe"
    ];
  };
}
```

## Troubleshooting Examples

### Testing Module Configuration

```bash
# Test a specific module
nix repl
:l <nixpkgs/nixos/lib/eval-config.nix>
config = evalModules { 
  modules = [./modules/wireguard.nix]; 
} {}
config.options.network-fabric.wireguard
```

### Checking Generated Configuration

```bash
# Check what will be deployed
sudo nixos-rebuild dry-activate --flake .#vm-sapinet

# Check specific configuration values
nix eval .#nixosConfigurations.vm-sapinet.config.networking.hostName
nix eval .#nixosConfigurations.vm-sapinet.config.network-fabric.wireguard.peers
```

### Debugging Module Options

```bash
# List all available options for a module
nix eval .#nixosConfigurations.vm-sapinet.config.options.network-fabric.wireguard
```

### Testing WireGuard Configuration

```bash
# Check WireGuard configuration
nix eval .#nixosConfigurations.vm-sapinet.config.networking.wireguard.interfaces.wgtransport

# Check peers
nix eval .#nixosConfigurations.vm-sapinet.config.networking.wireguard.interfaces.wgtransport.peers
```

### Building Without Deploying

```bash
# Build configuration without deploying
nix build .#nixosConfigurations.vm-sapinet.config.system.build.toplevel --no-link
```

## Common Patterns

### Overriding Module Defaults

```nix
# Override a module default in host variables
{
  network-fabric.wireguard.listenPort = 51821;  # Change from default 51820
  network-fabric.security.ssh.port = 2222;      # Change SSH port
}
```

### Adding Custom Packages

```nix
# Add host-specific packages in base-variables.nix
{
  network-fabric.base.packages = [
    "git"
    "curl"
    "vim"
    "htop"
    "tmux"
    "wireguard-tools"
    "frr"
  ];
}
```

### Custom System Services

```nix
# Add custom services in default.nix
{
  systemd.services.custom-service = {
    description = "Custom application service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.myapp}/bin/myapp";
      Restart = "always";
    };
  };
}
```

### Environment Variables

```nix
# Set environment variables in default.nix
{
  environment.variables = {
    EDITOR = "vim";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}
```

## Migration from Old Structure

### Before (Old Structure)

```nix
# Old monolithic default.nix (250+ lines)
{
  networking.hostName = "vm-sapinet";
  networking.wireguard.interfaces.wgtransport = { ... };
  services.frr = { ... };
  services.openssh = { ... };
  # ... hundreds of lines of mixed configuration
}
```

### After (New Structure)

```nix
# New modular approach

# 1. variables.nix - Configuration data
{
  network-fabric = {
    networking.hostName = "vm-sapinet";
    wireguard = { ... };
    frr = { ... };
    security = { ... };
  };
}

# 2. default.nix - Minimal host-specific tweaks
{
  imports = [ ... ];  # Module imports
  # Only host-specific overrides here
}
```

### Migration Steps

1. **Identify configuration domains**: Networking, WireGuard, FRR, Security
2. **Move to variables.nix**: Extract configuration data into the new format
3. **Update default.nix**: Replace direct configuration with module imports
4. **Test incrementally**: Validate each module separately
5. **Clean up**: Remove redundant configuration

## Best Practices

### 1. Keep default.nix Minimal

✅ **Good**: Only host-specific tweaks that can't go in variables
❌ **Bad**: Putting configuration data in default.nix

### 2. Use Variables for Configuration

✅ **Good**: All standard settings in `variables.nix`
❌ **Bad**: Hardcoding values in module files

### 3. Follow Module Patterns

✅ **Good**: Each logical component in its own module
❌ **Bad**: Mixing different concerns in one module

### 4. Document Overrides

✅ **Good**: Comment why you're overriding a default
❌ **Bad**: Silent overrides without explanation

### 5. Test Incrementally

✅ **Good**: Add one module at a time and test
❌ **Bad**: Big bang migration without testing

### 6. Use Consistent Naming

✅ **Good**: Follow existing patterns for peer names
❌ **Bad**: Invent new naming schemes

## Summary

These examples demonstrate the flexibility and power of the new modular architecture. The key benefits are:

1. **Separation of concerns**: Each module handles one domain
2. **Reusability**: Modules can be shared across hosts
3. **Maintainability**: Changes are localized
4. **Scalability**: Easy to add new hosts
5. **Testability**: Modules can be validated independently

For complete documentation, see the [Structure Reference](STRUCTURE.md).