# NixOS Fabric Infrastructure

**Private Repository** - Network automation for spine/leaf architecture with WireGuard, BGP, OSPF, and EVPN/VXLAN.

## 📖 Documentation

- [Deployment Guide](docs/deployment/DEPLOYMENT.md) - Step-by-step deployment instructions
- [Troubleshooting](docs/troubleshooting/) - Common issues and solutions
- [Reference](docs/reference/) - Configuration reference

## 🚀 Quick Start

```bash
# Clone the repository (master branch)
git clone git@github.com:franck01081991/nixos-fabric.git
cd nixos-fabric

# Build and evaluate configurations
nix flake show
nix eval .#nixosConfigurations.vm-sapinet.config.networking.hostName
nix eval .#nixosConfigurations.rtr-noisy.config.networking.hostName
```

## 📦 Hosts

| Host | Role | Configuration |
|------|------|---------------|
| **vm-sapinet** | Spine Router | WireGuard, OSPF, BGP, Security Hardening |
| **rtr-noisy** | Leaf Router | WireGuard, BGP, EVPN/VXLAN |

## 🔒 Security

⚠️ **IMPORTANT**: This repository MUST remain PRIVATE

- **No secrets in git** - WireGuard keys stored in `/etc/wireguard/` on hosts
- **Secrets management** - Use `/etc/nixos/secrets/` (not committed)
- **Public keys** - Shared securely between hosts

## 🛠️ Deployment

```bash
# Generate WireGuard keys
./scripts/deploy-wireguard.sh vm-sapinet 45.90.162.251
./scripts/deploy-wireguard.sh rtr-noisy RTR_NOISY_IP

# Deploy configurations
sudo nixos-rebuild switch --flake .#vm-sapinet
sudo nixos-rebuild switch --flake .#rtr-noisy

# Verify connectivity
./scripts/check-fabric.sh
```

## 📂 Structure

```
nixos-fabric/
├── docs/                  # Documentation
│   ├── deployment/        # Deployment guides
│   ├── troubleshooting/   # Issue resolution
│   └── reference/         # Configuration reference
├── hosts/                 # Host configurations
│   ├── vm-sapinet/        # Spine router
│   └── rtr-noisy/         # Leaf router
├── modules/               # Shared NixOS modules
├── scripts/               # Deployment tools
└── flake.nix              # Flake configuration
```

## 🔧 Tools

- `scripts/deploy-wireguard.sh` - Generate WireGuard keys
- `scripts/check-fabric.sh` - Verify fabric connectivity
- `scripts/deploy-and-verify.sh` - Interactive deployment tool

## 📞 Support

For issues, check:
- System logs: `journalctl -f`
- WireGuard: `sudo wg show`
- BGP: `vtysh -c "show ip bgp summary"`
- OSPF: `vtysh -c "show ip ospf neighbor"`
