# Nixos-Fabric Core

Bibliothèque de modules NixOS pour infrastructure réseau.

## Utilisation

```nix
# Dans votre flake.nix
inputs.core.url = "git+ssh://git@github.com/franck01081991/nixos-fabric-core.git";

# Puis dans vos configurations
modules = [
  inputs.core.nixosModules.fabric
  # ... vos autres modules
];
```

## Structure

- `modules/` - Modules NixOS organisés par domaine
  - `core/` - Modules principaux
  - `networking/` - Configuration réseau
  - `security/` - Sécurité et durcissement
  - `system/` - Configuration système

## Développement

```bash
# Entrer dans l'environnement de dev
nix develop

# Exécuter les tests
nix build .#checks.x86_64-linux.unit-tests

# Formater le code
nix fmt
```

## Tests

Les tests unitaires sont dans `tests/unit/` et peuvent être exécutés avec:

```bash
nix build .#checks.x86_64-linux.unit-tests
```
