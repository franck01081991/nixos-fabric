# NixOS Fabric

Repository for managing NixOS hosts via flakes.

## Hosts
- `vm-sapinet`
- `rtr-noisy`

## Structure
- `flake.nix`: Main flake configuration
- `modules/`: Shared NixOS modules
- `hosts/<host>/`: Per-host configuration
- `secrets/`: **NEVER COMMIT SECRETS** (use `/etc/nixos/secrets/` on hosts)

## Privacy Policy
- This repository **MUST remain PRIVATE**
- **NEVER** commit secrets (WireGuard keys, passwords, etc.)
- WireGuard keys should be stored in `/etc/wireguard/` on hosts
- Use `secrets/` directory for sensitive files (but keep it out of git)

## Secrets Management

### WireGuard Keys
1. On each host, generate private key:
   ```bash
   wg genkey | sudo tee /etc/wireguard/${HOSTNAME}.key
   sudo chmod 600 /etc/wireguard/${HOSTNAME}.key
   ```

2. Extract public key for peers:
   ```bash
   sudo cat /etc/wireguard/${HOSTNAME}.key | wg pubkey
   ```

3. Store public keys and endpoints in `/etc/nixos/secrets/wireguard.nix`:
   ```nix
   { 
     # For vm-sapinet
     noisyPub = "BASE64_PUBLIC_KEY";
     noisyEndpoint = "IP_OR_DOMAIN";
     bondyPub = "BASE64_PUBLIC_KEY";
     bondyEndpoint = "IP_OR_DOMAIN";
     leprePub = "BASE64_PUBLIC_KEY";
     lepreEndpoint = "IP_OR_DOMAIN";

     # For rtr-noisy
     sapinetPub = "BASE64_PUBLIC_KEY";
   }
   ```

### Deployment Workflow
1. Build config:
   ```bash
   sudo nixos-rebuild switch --flake .#rtr-noisy
   ```

2. For remote deployment:
   ```bash
   nixos-rebuild switch --flake .#rtr-noisy --target-host root@rtr-noisy --build-host localhost
   ```

## Hardware Configuration
Replace `hosts/<host>/hardware-configuration.nix` with content from `/etc/nixos/hardware-configuration.nix` on each host.

## Deployment Guide

### Quick Start

**Note:** The default branch is `master` (not `main`).

```bash
# Build a host configuration
nix build .#nixosConfigurations.vm-sapinet.config.system.build.toplevel

# Check hostname
nix eval .#nixosConfigurations.vm-sapinet.config.networking.hostName
```

### Full Deployment Process

#### 1. Generate WireGuard Keys
On each host, run the deployment script:
```bash
# On vm-sapinet
./scripts/deploy-wireguard.sh vm-sapinet 45.90.162.251

# On rtr-noisy
./scripts/deploy-wireguard.sh rtr-noisy NOISY_PUBLIC_IP
```

#### 2. Exchange Public Keys
Copy the public keys from each host's `/etc/nixos/secrets/wireguard.nix` to the other hosts.

#### 3. Update Configuration
Edit the WireGuard configuration in `hosts/<host>/default.nix` to replace:
- `__SAPINET_PUB__` with the actual public key from vm-sapinet
- `__NOISY_PUB__` with the actual public key from rtr-noisy
- `__NOISY_ENDPOINT__` with the actual public IP/domain

#### 4. Deploy Configuration
```bash
# On vm-sapinet
sudo nixos-rebuild switch --flake .#vm-sapinet

# On rtr-noisy
sudo nixos-rebuild switch --flake .#rtr-noisy
```

#### 5. Verify Connectivity
```bash
# Check WireGuard interface
ip link show wgtransport

# Check WireGuard status
sudo wg show

# Check BGP sessions (on vm-sapinet)
vtysh -c "show ip bgp summary"

# Check OSPF neighbors (on vm-sapinet)
vtysh -c "show ip ospf neighbor"

# Ping over WireGuard
ping 10.255.0.2  # From vm-sapinet to rtr-noisy
```

### Remote Deployment
```bash
# Build locally and deploy to remote host
nixos-rebuild switch --flake .#rtr-noisy --target-host root@rtr-noisy --build-host localhost
```

### Troubleshooting

**WireGuard issues:**
```bash
# Check WireGuard status
sudo wg show

# Check interface
ip addr show wgtransport

# Check routes
ip route
```

**BGP/OSPF issues:**
```bash
# Check FRR status
sudo systemctl status frr

# Check BGP sessions
vtysh -c "show ip bgp summary"

# Check OSPF neighbors
vtysh -c "show ip ospf neighbor"
```

**Firewall issues:**
```bash
# Check nftables rules
sudo nft list ruleset

# Check dropped packets
sudo dmesg | grep nft
```
