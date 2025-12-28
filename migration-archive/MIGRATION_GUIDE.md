# Guide de Migration vers l'Architecture Multi-Repo

Ce guide documente la migration du monorepo nixos-fabric vers une architecture multi-repo.

## Structure Cible

```
📁 nixos-fabric-core/          # Bibliothèque de modules
├── modules/                   # Modules NixOS
├── tests/unit/                # Tests unitaires
├── docs/examples/             # Exemples
└── scripts/                   # Scripts génériques

📁 nixos-fabric-fleet/         # Gestion de flotte
├── hosts/                     # Configurations hôtes
├── flakes/                    # Configurations flake
├── profiles/                  # Profils réutilisables
├── external/                  # Configs externes
├── gitops/                    # Configs GitOps
├── tests/integration/         # Tests d'intégration
└── .github/workflows/         # CI/CD

📁 nixos-fabric-secrets/       # Secrets chiffrés (privé)
└── secrets/                   # Fichiers secrets SOPS
```

## Étapes de Migration

### 1. Préparation

```bash
# Tagger la dernière version monorepo
git tag -a v0.10.0-monorepo -m "Last monorepo version"
git push origin v0.10.0-monorepo

# Créer une branche de compatibilité
git checkout -b monorepo-compat
git push origin monorepo-compat
```

### 2. Création des Repos

```bash
# Créer les repos sur GitHub
gh repo create franck01081991/nixos-fabric-core --private
gh repo create franck01081991/nixos-fabric-fleet --private
gh repo create franck01081991/nixos-fabric-secrets --private

# Cloner et initialiser
mkdir -p ~/src/nixos-fabric-{core,fleet,secrets}
cd ~/src/nixos-fabric-core && git init && git remote add origin git@github.com:franck01081991/nixos-fabric-core.git
# Répéter pour fleet et secrets
```

### 3. Migration des Fichiers

#### Core
```bash
# Modules
cp -r /path/to/monorepo/modules/* ~/src/nixos-fabric-core/modules/
cp /path/to/monorepo/flakes/flake-minimal.nix ~/src/nixos-fabric-core/modules/core/network-fabric.nix

# Tests unitaires
cp -r /path/to/monorepo/tests/unit ~/src/nixos-fabric-core/tests/

# Exemples
cp -r /path/to/monorepo/examples ~/src/nixos-fabric-core/docs/

# Scripts
cp -r /path/to/monorepo/scripts ~/src/nixos-fabric-core/scripts/
```

#### Fleet
```bash
# Configurations hôtes
cp -r /path/to/monorepo/hosts/* ~/src/nixos-fabric-fleet/hosts/

# Flakes
cp -r /path/to/monorepo/flakes/* ~/src/nixos-fabric-fleet/flakes/

# Configurations externes
cp -r /path/to/monorepo/external ~/src/nixos-fabric-fleet/

# GitOps
cp -r /path/to/monorepo/gitops ~/src/nixos-fabric-fleet/

# Tests d'intégration
cp -r /path/to/monorepo/tests/integration ~/src/nixos-fabric-fleet/tests/

# CI/CD
cp -r /path/to/monorepo/.github ~/src/nixos-fabric-fleet/
```

#### Secrets
```bash
# Structure de base
mkdir -p ~/src/nixos-fabric-secrets/secrets

# Configuration SOPS
cp .sops.yaml ~/src/nixos-fabric-secrets/

# Exemple de secret (à chiffrer)
cp secrets-template.yaml ~/src/nixos-fabric-secrets/secrets/production.yaml

# Chiffrer avec SOPS
sops --encrypt --age age1... ~/src/nixos-fabric-secrets/secrets/production.yaml
```

### 4. Configuration des Flakes

#### Core (flake.nix)
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = nixpkgs.lib;
      in {
        nixosModules = import ./modules { inherit lib pkgs; };
        checks = { unit-tests = ... };
        devShells.default = ...;
      }
    );
}
```

#### Fleet (flake.nix)
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    core.url = "git+ssh://git@github.com/franck01081991/nixos-fabric-core.git";
    secrets.url = "git+ssh://git@github.com/franck01081991/nixos-fabric-secrets.git";
  };

  outputs = { self, nixpkgs, core, secrets, ... }:
    {
      nixosConfigurations = {
        host1 = nixpkgs.lib.nixosSystem {
          modules = [
            core.nixosModules.fabric
            ./hosts/production/host1.nix
          ];
        };
      };
    };
}
```

### 5. CI/CD

#### Core CI (.github/workflows/ci.yml)
```yaml
name: CI
on: [push, pull_request]
jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
      - run: nix flake check
      - run: nix build .#checks.x86_64-linux.unit-tests
```

#### Fleet CI/CD (.github/workflows/ci-cd.yml)
```yaml
name: CI/CD
on:
  push:
    branches: [main, staging, canary]
  workflow_dispatch:
    inputs:
      hostname:
        description: 'Hostname to bootstrap'
        required: true
      target:
        description: 'Target IP/hostname'
        required: true

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
      - run: nix flake check
      - run: nix build .#nixosConfigurations.${{ github.event.inputs.hostname }}

  bootstrap:
    if: github.event_name == 'workflow_dispatch'
    needs: checks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
      - run: |
          nix run nixpkgs#nixos-anywhere -- \
            --flake .#${{ github.event.inputs.hostname }} \
            root@${{ github.event.inputs.target }}
```

### 6. GitOps Pull

Créer un profil `profiles/gitops-pull.nix`:

```nix
{ lib, pkgs, ... }:
{
  services.comin = {
    enable = true;
    interval = "15m";
    repositories.fleet = {
      url = "git@github.com:franck01081991/nixos-fabric-fleet.git";
      branch = "prod";
      path = "/var/src/fleet";
      deploy.command = ''
        ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake /var/src/fleet#${config.networking.hostName}
      '';
    };
  };
}
```

### 7. Bootstrap Day-0

```bash
# Depuis le repo fleet
nix run github:numtide/nixos-anywhere -- \
  --flake .#new-hostname \
  --option substituters "https://cache.nixos.org" \
  root@target-ip
```

### 8. Rollback

```bash
# Pour un hôte spécifique
ssh hostname "sudo nixos-rebuild switch --rollback"

# Pour toute la flotte
for host in $(nix eval --raw .#nixosConfigurations | jq -r 'keys[]'); do
  ssh $host "sudo nixos-rebuild switch --rollback"
done
```

## Vérification Post-Migration

1. **Core**:
   ```bash
   cd nixos-fabric-core
   nix flake check
   nix build .#checks.x86_64-linux.unit-tests
   ```

2. **Fleet**:
   ```bash
   cd nixos-fabric-fleet
   nix flake check
   nix build .#nixosConfigurations.rtr-prod-01
   ```

3. **Secrets**:
   ```bash
   cd nixos-fabric-secrets
   # Vérifier que les fichiers sont chiffrés
   head secrets/production.yaml | grep -q "sops:" && echo "✓ Fichier chiffré"
   ```

## Résolution des Problèmes

### Problème: Dépendance flake non résolue
**Solution**: Vérifier que les URLs des inputs sont correctes et que les repos sont accessibles.

### Problème: Échec du bootstrap
**Solution**:
1. Vérifier la connectivité réseau
2. Vérifier que la cible a SSH accessible
3. Utiliser `--debug` pour plus de détails

### Problème: Tests échouent
**Solution**:
1. Vérifier les dépendances des tests
2. Exécuter les tests individuellement
3. Mettre à jour les tests si nécessaire

## Maintenance Continue

### Ajouter un nouvel hôte
1. Créer un fichier dans `fleet/hosts/production/`
2. Ajouter au flake.nix
3. Pousser et déclencher le bootstrap via CI/CD

### Mettre à jour un module
1. Modifier dans `core/modules/`
2. Tester avec `nix build .#checks`
3. Pousser et mettre à jour la référence dans fleet

### Ajouter un secret
1. Modifier `secrets/secrets/production.yaml`
2. Chiffrer avec SOPS
3. Pousser (le flake fleet le récupérera automatiquement)
