# Quick Start Guide

Get started with NixOS Fabric in 5 minutes!

## 🚀 Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric
```

### 2. Enable Security Module

Add to your `configuration.nix`:

```nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./modules/security/init.nix ];
  
  network-fabric.security-improved = {
    enable = true;
    
    ssh = {
      enable = true;
      port = 2222;
      passwordAuthentication = false;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 ];
    };
  };
}
```

### 3. Test Configuration

```bash
# Verify syntax
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Run flake check
nix flake check
```

### 4. Deploy

```bash
# For NixOS
sudo nixos-rebuild switch

# For testing
nix-build -E 'import ./modules/security/init.nix {}'
```

## 📖 Next Steps

- [Full Documentation](README.md) - Complete guide
- [Security Module](modules/security/README.md) - Detailed security config
- [Ansible Integration](modules/ansible/README.md) - Ansible setup

## 🎯 Common Configurations

### Minimal Security

```nix
network-fabric.security-improved = {
  enable = true;
  ssh.enable = true;
  firewall.enable = true;
};
```

### Production Security

```nix
network-fabric.security-improved = {
  enable = true;
  
  ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };
  
  firewall = {
    enable = true;
    allowedTCP = [ 2222 80 443 ];
    allowedUDP = [ 53 ];
    enableLogging = true;
  };
  
  fail2ban = {
    enable = true;
    bantime = 3600;
  };
  
  apparmor = {
    enable = true;
  };
};
```

## 🤝 Need Help?

- Check [FAQ](../troubleshooting/FAQ.md)
- Review [Troubleshooting Guide](../troubleshooting/DEBUGGING.md)
- Open an issue on GitHub
