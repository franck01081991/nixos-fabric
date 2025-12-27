# Tutorial: Step-by-Step Guide

This tutorial will guide you through setting up a basic NixOS Fabric deployment.

## Prerequisites

- Basic knowledge of NixOS
- Nix package manager installed
- Git installed
- Virtualization software (for testing)

## Step 1: Clone the Repository

```bash
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric
```

## Step 2: Understand the Structure

```
nixos-fabric/
├── docs/              # Documentation (you're here!)
├── modules/           # NixOS modules
├── hosts/             # Host configurations
├── examples/          # Example configurations
└── scripts/           # Utility scripts
```

## Step 3: Set Up Your First Node

### Create a new host configuration

```bash
mkdir -p hosts/my-first-node
cd hosts/my-first-node
```

### Generate hardware configuration

```bash
# For a real machine
nixos-generate-config --dir .

# For a virtual machine
nixos-generate-config --dir . --root /dev/sda
```

### Create basic configuration

Create `hosts/my-first-node/default.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/security/init.nix
    ../../modules/networking.nix
  ];

  network-fabric.security-improved = {
    enable = true;
    ssh.enable = true;
    firewall.enable = true;
  };

  networking.hostName = "my-first-node";
  networking.domain = "fabric.local";
}
```

## Step 4: Configure Security

Edit `hosts/my-first-node/variables.nix`:

```nix
{
  # SSH Configuration
  ssh = {
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

  # Firewall Configuration
  firewall = {
    allowedTCP = [ 2222 80 443 ];
    allowedUDP = [ 53 ];
    enableLogging = true;
  };

  # Fail2ban Configuration
  fail2ban = {
    enable = true;
    bantime = 3600;
  };
}
```

## Step 5: Test Your Configuration

```bash
# Validate syntax
nix-instantiate --eval -E 'import ./hosts/my-first-node/default.nix'

# Check for errors
nix flake check
```

## Step 6: Deploy

### For testing (without reboot)

```bash
nix-build -E 'import ./hosts/my-first-node/default.nix {}'
```

### For production deployment

```bash
sudo nixos-rebuild switch --flake .#my-first-node
```

## Step 7: Verify Deployment

```bash
# Check running services
systemctl status sshd
systemctl status fail2ban

# Check firewall rules
nft list ruleset

# Check network configuration
ip addr show
```

## Step 8: Add Monitoring (Optional)

Create `hosts/my-first-node/monitoring.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = ["localhost:9100"] } ];
      }
    ];
  };

  services.node-exporter = {
    enable = true;
  };
}
```

## Step 9: Add to Flake Configuration

Edit `flake.nix`:

```nix
{
  outputs = { self, nixpkgs, ... }:
  {
    nixosConfigurations = {
      my-first-node = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/my-first-node/default.nix
          ./hosts/my-first-node/variables.nix
          ./hosts/my-first-node/monitoring.nix
        ];
      };
    };
  };
}
```

## Step 10: Scale Up

Now you can add more nodes by repeating the process:

```bash
# Add a second node
mkdir -p hosts/my-second-node
cd hosts/my-second-node
nixos-generate-config --dir .
# Edit configuration files
```

## Troubleshooting

If you encounter issues:

1. **Check logs**: `journalctl -xe`
2. **Validate configuration**: `nixos-rebuild dry-activate`
3. **Check our FAQ**: See [FAQ](../troubleshooting/faq.md)
4. **Debugging guide**: See [Debugging Guide](../troubleshooting/debugging.md)

## Next Steps

- [Security Module Documentation](../modules/security/README.md)
- [Networking Module Documentation](../modules/networking/README.md)
- [Roles System Documentation](../roles/README.md)
- [Production Deployment Guide](../deployment/production.md)