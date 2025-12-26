# NixOS Fabric Deployment Guide

This guide provides step-by-step instructions for deploying the NixOS fabric infrastructure.

## Prerequisites

### On Each Host
1. NixOS installed
2. Git installed
3. SSH access configured
4. WireGuard kernel module available

### Repository Setup

**Note:** The default branch is `master`.

```bash
git clone git@github.com:franck01081991/nixos-fabric.git
cd nixos-fabric
```

## Deployment Steps

### 1. Generate WireGuard Keys

**On sapinet:**
```bash
./scripts/deploy-wireguard.sh sapinet 45.90.162.251
```

**On noisy-edge1:**
```bash
./scripts/deploy-wireguard.sh noisy-edge1 NOISY_PUBLIC_IP
```

### 2. Exchange Public Keys

After generating keys on each host:

1. Copy `/etc/nixos/secrets/wireguard.nix` from sapinet to noisy-edge1
2. Copy `/etc/nixos/secrets/wireguard.nix` from noisy-edge1 to sapinet

### 3. Update Configurations

**On sapinet:**
Edit `hosts/sapinet/default.nix` and replace:
- `__NOISY_PUB__` with noisy-edge1's public key
- `__NOISY_ENDPOINT__` with noisy-edge1's public IP

**On noisy-edge1:**
Edit `hosts/noisy-edge1/default.nix` and replace:
- `__SAPINET_PUB__` with sapinet's public key

### 4. Deploy Configurations

**Option A: Manual Deployment**

On sapinet:
```bash
sudo nixos-rebuild switch --flake .#sapinet
```

On noisy-edge1:
```bash
sudo nixos-rebuild switch --flake .#noisy-edge1
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

Check BGP (on sapinet):
```bash
vtysh -c "show ip bgp summary"
```

Check OSPF (on sapinet):
```bash
vtysh -c "show ip ospf neighbor"
```

Test connectivity:
```bash
ping 10.255.0.2  # From sapinet to noisy-edge1
ping 10.255.0.1  # From noisy-edge1 to sapinet
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
# For noisy-edge1
nixos-rebuild switch --flake .#noisy-edge1 --target-host root@noisy-edge1 --build-host localhost

# For sapinet
nixos-rebuild switch --flake .#sapinet --target-host root@sapinet --build-host localhost
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

When making changes:
```bash
# Edit configuration
git pull origin main
# Make changes
git add .
git commit -m "Update configuration"
git push origin main

# Deploy
sudo nixos-rebuild switch --flake .#HOSTNAME
```

## Security Notes

1. **Keep repository PRIVATE**
2. **Never commit secrets** to git
3. **WireGuard keys** should only exist on the hosts in `/etc/wireguard/`
4. **Public keys** can be shared between hosts via secure channels

## Expected Network Topology

```
Spine (sapinet):
- WAN: 45.90.162.251
- Loopback: 10.254.0.1/32
- WireGuard: 10.255.0.1/24
- Runs: OSPF + BGP

Leaf (noisy-edge1):
- Loopback: 10.254.0.11/32
- WireGuard: 10.255.0.11/24
- Runs: BGP + EVPN/VXLAN

WireGuard Transport:
- Port: 51820/UDP
- Encrypted overlay network
- Carries BGP/OSPF and data traffic
```

## Support

For issues, check:
- System logs: `journalctl -f`
- Service status: `sudo systemctl status`
- WireGuard status: `sudo wg show`
- BGP status: `vtysh -c "show ip bgp summary"`
