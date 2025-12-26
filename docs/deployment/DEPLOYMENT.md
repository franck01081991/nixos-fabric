# NixOS Fabric Deployment Guide - Hybrid Architecture

This guide provides step-by-step instructions for deploying the hybrid network fabric infrastructure with nodes that can simultaneously act as both spine and leaf routers.

## 🎯 Architecture Overview

The current deployment implements a **hybrid fabric architecture** where:
- **vm-sapinet**: Pure spine node (OSPF + BGP)
- **rtr-noisy**: Hybrid node (OSPF + BGP as spine, BGP + EVPN as leaf)

## 📋 Prerequisites

### On Each Host
1. NixOS installed (version 25.11 recommended)
2. Git installed
3. SSH access configured
4. WireGuard kernel module available
5. FRR routing suite installed

### Repository Setup

```bash
# Clone the repository (master branch)
git clone git@github.com:franck01081991/nixos-fabric.git
cd nixos-fabric

# Initialize git submodules if any
git submodule update --init --recursive
```

## 🚀 Deployment Steps

### 1. Generate WireGuard Keys

**On vm-sapinet (pure spine):**
```bash
./scripts/deploy-wireguard.sh vm-sapinet 45.90.162.251
```

**On rtr-noisy (hybrid node):**
```bash
./scripts/deploy-wireguard.sh rtr-noisy RTR_NOISY_PUBLIC_IP
```

**Note**: The hybrid architecture uses WireGuard for both spine (full mesh) and leaf (point-to-spine) connectivity.

### 2. Exchange Public Keys

After generating keys on each host:

1. Copy `/etc/nixos/secrets/wireguard.nix` from vm-sapinet to rtr-noisy
2. Copy `/etc/nixos/secrets/wireguard.nix` from rtr-noisy to vm-sapinet

**For hybrid nodes**, ensure both spine and leaf public keys are exchanged.

### 3. Update Configurations

**With the modular role system**, edit the role variables files:

**On vm-sapinet (pure spine):**
```bash
# Edit hosts/vm-sapinet/role-variables.nix
nano hosts/vm-sapinet/role-variables.nix
```

Update the peer configuration:
```nix
# In network-fabric.roles.spine.wireguard.peers.rtr-noisy
{
  publicKey = "RTR_NOISY_PUBLIC_KEY";  # From rtr-noisy
  endpoint = "RTR_NOISY_IP:51820";      # rtr-noisy's public IP
  allowedIPs = [
    "10.255.0.11/32"      # rtr-noisy WireGuard IP
    "fd42:1337:255::11/128"  # rtr-noisy IPv6
    "10.254.0.11/32"      # rtr-noisy loopback
    "fd42:1337:254::11/128"  # rtr-noisy IPv6 loopback
  ];
  persistentKeepalive = 25;
}

# In network-fabric.roles.spine.frr.bgp.neighbors.rtr-noisy
{
  ip = "10.254.0.11";        # rtr-noisy loopback
  as = 65000;
  updateSource = "lo";
  ebgpMultihop = 5;
  addressFamilies = [ "ipv4 unicast" ];
}
```

**On rtr-noisy (hybrid node):**
```bash
# Edit hosts/rtr-noisy/role-variables.nix
nano hosts/rtr-noisy/role-variables.nix
```

Update both spine and leaf role configurations:

**Spine role (for core routing):**
```nix
# In network-fabric.roles.spine.wireguard.peers.vm-sapinet
{
  publicKey = "VM_SAPINET_PUBLIC_KEY";  # From vm-sapinet
  endpoint = "45.90.162.251:51820";      # vm-sapinet's public IP
  allowedIPs = [
    "10.255.0.1/32"      # vm-sapinet WireGuard IP
    "fd42:1337:255::1/128"  # vm-sapinet IPv6
    "10.254.0.1/32"      # vm-sapinet loopback
    "fd42:1337:254::1/128"  # vm-sapinet IPv6 loopback
  ];
  persistentKeepalive = 25;
}

# In network-fabric.roles.spine.frr.ospf
{
  enable = true;
  routerId = "10.254.0.11";
  area = 0;
  networks = [
    "10.254.0.11/32"      # This node's loopback
    "10.255.0.0/24"       # WireGuard network
  ];
}

# In network-fabric.roles.spine.frr.bgp.neighbors.vm-sapinet
{
  ip = "10.254.0.1";        # vm-sapinet loopback
  as = 65000;
  updateSource = "lo";
  ebgpMultihop = 5;
  addressFamilies = [ "ipv4 unicast" ];
}
```

**Leaf role (for edge services):**
```nix
# In network-fabric.roles.leaf.wireguard.peers.vm-sapinet
{
  publicKey = "VM_SAPINET_PUBLIC_KEY";  # From vm-sapinet
  endpoint = "45.90.162.251:51820";      # vm-sapinet's public IP
  allowedIPs = [
    "10.255.0.1/32"      # vm-sapinet WireGuard IP
    "fd42:1337:255::1/128"  # vm-sapinet IPv6
    "10.254.0.1/32"      # vm-sapinet loopback
    "fd42:1337:254::1/128"  # vm-sapinet IPv6 loopback
  ];
  persistentKeepalive = 25;
}

# In network-fabric.roles.leaf.frr.bgp.neighbors.vm-sapinet
{
  ip = "10.254.0.1";        # vm-sapinet loopback
  as = 65000;
  updateSource = "lo";
  ebgpMultihop = 5;
  addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
}

# In network-fabric.roles.leaf.frr.evpn
{
  enable = true;
  neighbors = [ "10.254.0.1" ];  # vm-sapinet loopback
}
```

### 4. Deploy Configurations

**Option A: Manual Deployment**

**On vm-sapinet (pure spine):**
```bash
sudo nixos-rebuild switch --flake .#vm-sapinet
```

**On rtr-noisy (hybrid node):**
```bash
sudo nixos-rebuild switch --flake .#rtr-noisy
```

**Option B: Using Deployment Script**
```bash
./scripts/deploy-and-verify.sh
```
Then select option 5 for full deployment

### 5. Verify Connectivity

**Using the verification script:**
```bash
./scripts/deploy-and-verify.sh
```
Then select option 6 for full verification

**Manual verification:**

Check WireGuard:
```bash
# On both hosts
sudo wg show wgtransport
ip addr show wgtransport
```

Check routing protocols:
```bash
# On vm-sapinet (spine only)
vtysh -c "show ip bgp summary"

# On rtr-noisy (hybrid - both OSPF and BGP)
vtysh -c "show ip ospf neighbor"  # Spine role
vtysh -c "show ip bgp summary"    # Both roles
vtysh -c "show evpn vni"          # Leaf role
```

Test connectivity:
```bash
# From vm-sapinet to rtr-noisy
ping 10.255.0.11  # WireGuard IP
ping 10.254.0.11  # Loopback IP

# From rtr-noisy to vm-sapinet
ping 10.255.0.1  # WireGuard IP
ping 10.254.0.1  # Loopback IP

# Test IPv6 connectivity
ping6 fd42:1337:255::1
ping6 fd42:1337:254::1
```

## 🔧 Hybrid Node Specifics

### Understanding Hybrid Roles

The hybrid node (rtr-noisy) runs **both spine and leaf roles simultaneously**:

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

### Verifying Hybrid Configuration

```bash
# Check both roles are active
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.spine.enable
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles.leaf.enable

# Check FRR has both OSPF and BGP+EVPN
vtysh -c "show running-config"

# Check WireGuard has appropriate peers
sudo wg show wgtransport
```

### Hybrid Node Benefits

1. **Resilience**: Can route at multiple network layers
2. **Flexibility**: Adapts to different network conditions
3. **Efficiency**: Single node handles multiple roles
4. **Redundancy**: Provides backup routing paths

## 📦 Adding New Nodes

### Adding a Pure Spine Node

```bash
# Create host directory
mkdir -p hosts/new-spine

# Generate hardware config (on the new host)
sudo nixos-generate-config --show-hardware-config > hosts/new-spine/hardware-configuration.nix

# Create role variables
cat > hosts/new-spine/role-variables.nix <<EOF
{ ... }:
{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine2";
    
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
        vm-sapinet = { ... };
        rtr-noisy = { ... };
      };
    };
    
    frr = {
      ospf = {
        routerId = "10.254.0.2";
        networks = [ "10.254.0.2/32" "10.255.0.0/24" ];
      };
      bgp = {
        routerId = "10.254.0.2";
        neighbors = {
          vm-sapinet = { ... };
          rtr-noisy = { ... };
        };
      };
    };
  };
}
EOF

# Create base variables
cat > hosts/new-spine/base-variables.nix <<EOF
{ ... }:
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
EOF

# Create minimal default.nix
cat > hosts/new-spine/default.nix <<EOF
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
    ../../modules/roles/spine.nix
  ];

  # Host-specific tweaks
  boot.kernelParams = [ "lockdown=confidentiality" "slab_nomerge" "pti=on" ];
}
EOF

# Add to flake.nix
nano flake.nix
```

### Adding a Pure Leaf Node

```bash
# Create host directory
mkdir -p hosts/new-leaf

# Generate hardware config
sudo nixos-generate-config --show-hardware-config > hosts/new-leaf/hardware-configuration.nix

# Create role variables
cat > hosts/new-leaf/role-variables.nix <<EOF
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
EOF

# Create base variables and default.nix (similar to pure spine)
# ...

# Add to flake.nix
nano flake.nix
```

### Adding a Hybrid Node

```bash
# Create host directory
mkdir -p hosts/new-hybrid

# Create role variables with BOTH roles
cat > hosts/new-hybrid/role-variables.nix <<EOF
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
      roleId = "leaf3";
      # Leaf configuration...
    };
  };
}
EOF

# Import both role modules in default.nix
cat > hosts/new-hybrid/default.nix <<EOF
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
    ../../modules/roles/spine.nix
    ../../modules/roles/leaf.nix  # Both roles!
  ];

  # Host-specific tweaks
}
EOF

# Add to flake.nix
nano flake.nix
```

## 🔄 Updating Existing Nodes

### Modifying Role Behavior

**Change all spine nodes:**
```bash
# Edit modules/roles/spine.nix
nano modules/roles/spine.nix

# Changes will automatically apply to all spine nodes
# including hybrid nodes' spine role
```

**Change all leaf nodes:**
```bash
# Edit modules/roles/leaf.nix
nano modules/roles/leaf.nix

# Changes will automatically apply to all leaf nodes
# including hybrid nodes' leaf role
```

### Updating Host-Specific Configuration

**For pure spine nodes:**
```bash
# Edit hosts/<hostname>/role-variables.nix
nano hosts/vm-sapinet/role-variables.nix

# Update spine-specific settings
```

**For hybrid nodes:**
```bash
# Edit hosts/<hostname>/role-variables.nix
nano hosts/rtr-noisy/role-variables.nix

# Update both spine and leaf configurations
```

## 📊 Expected Network Topology

```
Hybrid Fabric Architecture:
┌───────────────────────────────────────────────────────┐
│                   Hybrid Fabric Network                │
├───────────────────┬───────────────────┬───────────────┤
│   vm-sapinet      │    rtr-noisy      │   new-spine   │
│  (Pure Spine)     │  (Hybrid Node)    │  (Pure Spine) │
├───────────────────┼───────────────────┼───────────────┤
│ - OSPF + BGP      │ - OSPF + BGP      │ - OSPF + BGP  │
│ - IPv4 + IPv6     │ - IPv4 + IPv6     │ - IPv4 + IPv6 │
│ - Full mesh       │ - Full mesh       │ - Full mesh   │
│ - Core routing    │ - Core + Edge     │ - Core routing│
└───────────────────┴───────────────────┴───────────────┘
                      │
                      │
                      ▼
┌───────────────────────────────────────────────────────┐
│                    Leaf Nodes                        │
│  ┌─────────────┐          ┌─────────────┐            │
│  │  leaf1      │          │  leaf2      │            │
│  ├─────────────┤          ├─────────────┤            │
│  │ - BGP+EVPN  │          │ - BGP+EVPN  │            │
│  │ - IPv4      │          │ - IPv4      │            │
│  │ - Edge      │          │ - Edge      │            │
│  └─────────────┘          └─────────────┘            │
└───────────────────────────────────────────────────────┘
```

### WireGuard Transport
- **Port**: 51820/UDP
- **Encryption**: WireGuard (modern cryptography)
- **Topology**: Full mesh (spine) + Point-to-spine (leaf)
- **Carries**: BGP/OSPF/EVPN and data traffic

### Routing Protocols
- **Spine Nodes**: OSPF (Area 0) + BGP IPv4/IPv6
- **Leaf Nodes**: BGP IPv4 + EVPN
- **Hybrid Nodes**: OSPF + BGP + EVPN

## 📚 Post-Deployment

### Monitor Services

```bash
# Check service status
sudo systemctl status wg-quick@wgtransport
sudo systemctl status frr
sudo systemctl status nftables

# Monitor logs
journalctl -u wg-quick@wgtransport -u frr -f

# For hybrid nodes, check both OSPF and BGP
vtysh -c "show ip ospf neighbor"  # Spine role
vtysh -c "show ip bgp summary"    # Both roles
vtysh -c "show evpn vni"          # Leaf role
```

### Update Configuration

```bash
# Pull latest changes
git pull origin master

# For host-specific changes
# Edit the appropriate role-variables.nix file

# For common changes
# Edit the relevant module or role definition

# Test configuration
nix eval .#nixosConfigurations.HOSTNAME.config.networking.hostName

# Commit changes
git add .
git commit -m "Update configuration"
git push origin master

# Deploy
sudo nixos-rebuild switch --flake .#HOSTNAME
```

### Hybrid Node Management

```bash
# Check which roles are active on a hybrid node
nix eval .#nixosConfigurations.rtr-noisy.config.network-fabric.roles

# Verify role merging
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
```

## 🔧 Troubleshooting

### Hybrid Node Issues

**Symptom**: OSPF not starting on hybrid node
```bash
# Check FRR service
sudo systemctl status frr

# Check OSPF configuration
vtysh -c "show running-config" | grep router ospf

# Check interfaces
ip link show
```

**Symptom**: BGP sessions flapping
```bash
# Check BGP configuration
vtysh -c "show running-config" | grep router bgp

# Check WireGuard connectivity
sudo wg show
ping 10.255.0.1  # Test connectivity to peer
```

**Symptom**: EVPN not working on hybrid node
```bash
# Check EVPN configuration
vtysh -c "show running-config" | grep address-family l2vpn

# Check VXLAN interface
ip link show
```

### Role Conflict Resolution

If roles conflict, the merge order is:
```
Module Defaults → Role Defaults → Role Variables → Base Variables → Host Tweaks
```

Use `lib.mkMerge` for deep merging or override explicitly in role variables.

## 🎯 Security Notes

1. **Repository Privacy**: MUST remain PRIVATE
2. **WireGuard Keys**: Only on hosts in `/etc/wireguard/`
3. **Public Keys**: Shared via secure channels
4. **Role Security**: Different profiles per role
5. **Hybrid Nodes**: Inherit most restrictive security from both roles

## 📖 Support

For issues with hybrid nodes:
1. Check role activation: `nix eval .#nixosConfigurations.HOST.config.network-fabric.roles`
2. Verify FRR configuration: `vtysh -c "show running-config"`
3. Test connectivity: `ping 10.255.0.X`
4. Check logs: `journalctl -u frr -f`

This deployment guide covers the hybrid architecture where nodes can simultaneously act as both spine and leaf routers, providing maximum flexibility and resilience in your network fabric.