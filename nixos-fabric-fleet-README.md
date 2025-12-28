# Nixos-Fabric Fleet

Gestion de flotte NixOS pour l'infrastructure réseau.

## Structure

- `hosts/` - Configurations spécifiques par hôte
  - `production/` - Hôtes de production
  - `staging/` - Hôtes de staging
- `profiles/` - Profils réutilisables
- `.github/workflows/` - CI/CD

## Utilisation

### Ajouter un nouvel hôte

1. Créer un fichier dans `hosts/production/`:
   ```bash
   cp hosts/production/rtr-prod-01.nix hosts/production/new-host.nix
   ```

2. Modifier la configuration:
   ```nix
   { config, lib, pkgs, ... }:
   {
     networking.hostName = "new-host";
     # ... configuration spécifique
   }
   ```

3. Ajouter au flake.nix:
   ```nix
   nixosConfigurations."new-host" = nixpkgs.lib.nixosSystem {
     inherit system;
     modules = [
       nixosModules.fabric
       ./hosts/production/new-host.nix
     ];
   };
   ```

## Bootstrap Day-0

```bash
# Depuis la racine du repo
nix run github:numtide/nixos-anywhere -- \
  --flake .#new-host \
  --option substituters "https://cache.nixos.org" \
  root@1.2.3.4
```

## CI/CD

Le workflow GitHub Actions inclut:
- Vérification des flakes
- Build des configurations
- Job de bootstrap manuel (workflow_dispatch)

## Profils

- `gitops-pull.nix` - Configuration GitOps avec comin pour les mises à jour automatiques
