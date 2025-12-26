# NixOS Fabric Deployment Guide

This guide provides step-by-step instructions for deploying the NixOS fabric infrastructure.

## Prerequisites

### On Each Host
1. NixOS installed
2. Git installed
3. SSH access configured
4. WireGuard kernel module available

### Repository Setup
```bash
git clone git@github.com:franck01081991/nixos-fabric.git
cd nixos-fabric
```

## Deployment Steps

### 1. Generate WireGuard Keys

**On vm-sapinet (spine):**
```bash
./scripts/deploy-wireguard.sh vm-sapinet 45.90.162.251
```

**On rtr-noisy (leaf):**
```bash
./scripts/deploy-wireguard.sh rtr-noisy RTR_NOISY_PUBLIC_IP
```

**Note**: The new modular structure automatically handles WireGuard configuration through the `wireguard.nix` module. Keys will be used by the variables files.

### 2. Exchange Public Keys

After generating keys on each host:

1. Copy `/etc/nixos/secrets/wireguard.nix` from vm-sapinet to rtr-noisy
2. Copy `/etc/nixos/secrets/wireguard.nix` from rtr-noisy to vm-sapinet

### 3. Update Configurations

**With the new modular structure**, edit the variables files instead:

**On vm-sapinet (spine):**
Edit `hosts/vm-sapinet/variables.nix` and update:
```nix
# In network-fabric.wireguard.peers.rtr-noisy
publicKey = "RTR_NOISY_PUBLIC_KEY";  # Replace with actual key
endpoint = "RTR_NOISY_IP:51820";      # Replace with actual IP
```

**On rtr-noisy (leaf):**
Edit `hosts/rtr-noisy/variables.nix` and update:
```nix
# In network-fabric.wireguard.peers.vm-sapinet
publicKey = "VM_SAPINET_PUBLIC_KEY";  # Replace with actual key
```

**For additional peers** (like bondy, lepre on vm-sapinet), update the corresponding sections in the variables files.

### 4. Deploy Configurations

**Option A: Manual Deployment**

On vm-sapinet (spine):
```bash
sudo nixos-rebuild switch --flake .#vm-sapinet
```

On rtr-noisy (leaf):
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
sudo wg show
ip addr show wgtransport
```

Check BGP (on vm-sapinet):
```bash
vtysh -c "show ip bgp summary"
```

Check OSPF (on vm-sapinet):
```bash
vtysh -c "show ip ospf neighbor"
```

Test connectivity:
```bash
ping 10.255.0.2  # From vm-sapinet to rtr-noisy
ping 10.255.0.1  # From rtr-noisy to vm-sapinet
```

## Troubleshooting

### WireGuard Issues

**Interface not coming up:**
```bash
sudo systemctl status wg-quick@wgtransport
journalctl -u wg-quick@wgtransport -f
```

**Check firewall:**
```bash
sudo nft list ruleset
```

### BGP/OSPF Issues

**FRR not starting:**
```bash
sudo systemctl status frr
journalctl -u frr -f
```

**Check configuration:**
```bash
sudo frr reload
vtysh -c "show running-config"
```

### General Issues

**Check system logs:**
```bash
journalctl -f
```

**Check service status:**
```bash
sudo systemctl status
```

## Remote Deployment

Deploy from development machine:

```bash
# For rtr-noisy (leaf)
nixos-rebuild switch --flake .#rtr-noisy --target-host root@rtr-noisy --build-host localhost

# For vm-sapinet (spine)
nixos-rebuild switch --flake .#vm-sapinet --target-host root@vm-sapinet --build-host localhost
```

## Post-Deployment

### Monitor Services
```bash
# Check service status
sudo systemctl status wg-quick@wgtransport frr nftables

# Monitor logs
journalctl -u wg-quick@wgtransport -u frr -f
```

### Update Configuration

**With the new modular structure**, follow these best practices:

```bash
# Pull latest changes
git pull origin master

# For host-specific changes, edit the appropriate variables file:
# - hosts/<hostname>/variables.nix (main configuration)
# - hosts/<hostname>/base-variables.nix (base overrides)

# For common changes, edit the relevant module:
# - modules/networking.nix
# - modules/wireguard.nix
# - modules/frr.nix
# - modules/security.nix

# Test configuration
nix eval .#nixosConfigurations.HOSTNAME.config.networking.hostName

# Commit changes
git add .
git commit -m "Update configuration"
git push origin master

# Deploy
sudo nixos-rebuild switch --flake .#HOSTNAME
```

**See the [Structure Reference](../reference/STRUCTURE.md) for complete documentation on the new modular system.**

## Security Notes

1. **Keep repository PRIVATE**
2. **Never commit secrets** to git
3. **WireGuard keys** should only exist on the hosts in `/etc/wireguard/`
4. **Public keys** can be shared between hosts via secure channels

## Expected Network Topology

```
Spine (vm-sapinet):
- WAN: 45.90.162.251
- Loopback: 10.254.0.1/32
- WireGuard: 10.255.0.1/24
- Runs: OSPF + BGP
- Modules: networking, wireguard, frr (ospf+bgp), security

Leaf (rtr-noisy):
- Loopback: 10.254.0.11/32
- WireGuard: 10.255.0.11/24
- Runs: BGP + EVPN/VXLAN
- Modules: networking, wireguard, frr (bgp+evpn), security

WireGuard Transport:
- Port: 51820/UDP
- Encrypted overlay network
- Carries BGP/OSPF and data traffic
- Configured via wireguard.nix module
```

## New Modular Architecture

The deployment now uses a modular architecture where each component is configured through dedicated modules:

- **networking.nix**: Handles all network interfaces, DNS, gateways
- **wireguard.nix**: Manages WireGuard interfaces and peers
- **frr.nix**: Configures BGP, OSPF, and EVPN
- **security.nix**: Centralizes SSH, firewall, and hardening
- **base.nix**: Common packages and users

**Configuration Flow**:
```
Module Defaults → Base Variables → Host Variables → Host-Specific Tweaks
```

This makes the system much more maintainable and scalable. See [Structure Reference](../reference/STRUCTURE.md) for complete details.

## Support

For issues, check:
- System logs: `journalctl -f`
- Service status: `sudo systemctl status`
- WireGuard status: `sudo wg show`
- BGP status: `vtysh -c "show ip bgp summary"`
