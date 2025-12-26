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

## Secrets Management

### WireGuard Keys
1. On each host, generate private key:
   ```bash
   wg genkey | sudo tee /etc/wireguard/${HOSTNAME}.key
   ```

2. Extract public key for peers:
   ```bash
   sudo cat /etc/wireguard/${HOSTNAME}.key | wg pubkey
   ```

3. Store public keys in `/etc/nixos/secrets/wireguard-pubkeys.nix`:
   ```nix
   { 
     sapinetPub = "BASE64_PUBLIC_KEY";
     noisyEdge1Pub = "BASE64_PUBLIC_KEY";
   }
   ```

### Deployment Workflow
1. Build config:
   ```bash
   sudo nixos-rebuild switch --flake .#noisy-edge1
   ```

2. For remote deployment:
   ```bash
   nixos-rebuild switch --flake .#noisy-edge1 --target-host root@noisy-edge1 --build-host localhost
   ```

## Hardware Configuration
Replace `hosts/<host>/hardware-configuration.nix` with content from `/etc/nixos/hardware-configuration.nix` on each host.

## Usage
```bash
# Build a host configuration
nix build .#nixosConfigurations.sapinet.config.system.build.toplevel

# Check hostname
nix eval .#nixosConfigurations.sapinet.config.networking.hostName
```
