# NixOS Fabric

Repository for managing NixOS hosts via flakes.

## Hosts
- `sapinet`
- `noisy-edge1`

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

## Usage
```bash
# Build a host configuration
nix build .#nixosConfigurations.sapinet.config.system.build.toplevel

# Check hostname
nix eval .#nixosConfigurations.sapinet.config.networking.hostName
```
