# nixos-fabric

NixOS infra repo for:
- sapinet (VPS spine)
- noisy-edge1 (spine+leaf)

## Deploy
On a host:
```bash
sudo nixos-rebuild switch --flake .#<hostname>
