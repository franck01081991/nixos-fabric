# NixOS Fabric - Guide d'Utilisation

## Table des Matières

1. [Introduction](#introduction)
2. [Structure du Dépôt](#structure-du-dépôt)
3. [Configuration de Base](#configuration-de-base)
4. [Utilisation des Modules](#utilisation-des-modules)
5. [Configuration Réseau](#configuration-réseau)
6. [Configuration de Sécurité](#configuration-de-sécurité)
7. [Déploiement avec Ansible](#déploiement-avec-ansible)
8. [Exécution des Tests](#exécution-des-tests)
9. [Développement et Contribution](#développement-et-contribution)
10. [Dépannage](#dépannage)

## Introduction

Bienvenue dans le dépôt NixOS Fabric réorganisé ! Ce guide vous aidera à comprendre comment utiliser le dépôt après la réorganisation complète.

## Structure du Dépôt

```
.
├── ansible/                  # Configuration Ansible
├── docs/                     # Documentation complète
├── examples/                 # Exemples de configuration
├── modules/                  # Modules NixOS (réorganisés)
│   ├── core/                 # Modules de base
│   ├── networking/           # Modules réseau
│   ├── security/             # Modules de sécurité
│   ├── integration/          # Modules d'intégration
│   └── utils/                # Modules utilitaires
├── tests/                    # Tests (réorganisés)
└── scripts/                  # Scripts utilitaires
```

## Configuration de Base

### Prérequis

- NixOS système
- Nix package manager installé
- Connaissance de base des concepts Nix

### Configuration Minimale

```nix
{ config, pkgs, ... }:

{
  imports = [
    ../modules/core/network-fabric.nix
    ../modules/security/init.nix
  ];
  
  network-fabric = {
    enable = true;
    name = "my-fabric";
    environment = "production";
  };
  
  security = {
    enable = true;
    firewall = {
      allowedTCP = [ 22 80 443 ];
    };
  };
}
```

## Utilisation des Modules

### Importer des Modules

```nix
{ config, pkgs, ... }:

{
  imports = [
    # Modules de base
    ../modules/core/network-fabric.nix
    ../modules/core/base.nix
    
    # Modules réseau
    ../modules/networking/frr.nix
    ../modules/networking/wireguard.nix
    
    # Modules de sécurité (import tous via init.nix)
    ../modules/security/init.nix
    
    # Modules d'intégration
    ../modules/integration/ansible.nix
  ];
}
```

### Module de Sécurité

Le module de sécurité est maintenant consolidé. Utilisez `init.nix` pour importer tous les composants :

```nix
# Avant (ancienne structure)
imports = [
  ../modules/security/default.nix
  ../modules/security/firewall.nix
  ../modules/security/hardening.nix
];

# Après (nouvelle structure)
imports = [
  ../modules/security/init.nix  # Import tout
];
```

## Configuration Réseau

### FRR (Routing)

```nix
{ config, pkgs, ... }:

{
  imports = [ ../modules/networking/frr.nix ];
  
  network-fabric.frr = {
    enable = true;
    bgp = {
      as = 65000;
      neighbors = {
        peer1 = { ip = "10.0.0.1"; as = 65001; };
      };
    };
  };
}
```

### WireGuard

```nix
{ config, pkgs, ... }:

{
  imports = [ ../modules/networking/wireguard.nix ];
  
  network-fabric.wireguard = {
    enable = true;
    peers = [
      {
        name = "peer1";
        publicKey = "...";
        allowedIPs = [ "10.0.0.2/32" ];
      }
    ];
  };
}
```

## Configuration de Sécurité

### Configuration SSH

```nix
{ config, pkgs, ... }:

{
  imports = [ ../modules/security/init.nix ];
  
  network-fabric.security = {
    enable = true;
    ssh = {
      port = 2222;
      passwordAuthentication = false;
      permitRootLogin = "no";
    };
  };
}
```

### Pare-feu

```nix
{ config, pkgs, ... }:

{
  imports = [ ../modules/security/init.nix ];
  
  network-fabric.security = {
    enable = true;
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 51820 ];
      allowedUDP = [ 51820 ];
      enableLogging = true;
    };
  };
}
```

## Déploiement avec Ansible

### Structure Ansible

```
ansible/
├── inventories/         # Fichiers d'inventaire
├── playbooks/           # Playbooks
│   ├── deploy-fabric.yml # Déploiement principal
│   └── verify-fabric.yml # Vérification
├── roles/               # Rôles
│   ├── common/          # Configuration commune
│   ├── frr/             # Configuration FRR
│   ├── wireguard/       # Configuration WireGuard
│   └── security/        # Configuration sécurité
└── README.md            # Documentation Ansible
```

### Déploiement de Base

```bash
# Déployer sur l'environnement de production
ansible-playbook -i ansible/inventories/production/hosts.ini \
  ansible/playbooks/deploy-fabric.yml

# Vérifier le déploiement
ansible-playbook -i ansible/inventories/production/hosts.ini \
  ansible/playbooks/verify-fabric.yml
```

### Exemple d'Inventaire

```ini
# ansible/inventories/production/hosts.ini

[spine]
rtr-sapinet ansible_host=192.168.1.100

[leaf]
rtr-noisy ansible_host=192.168.1.101

[fabric:children]
spine
leaf

[fabric:vars]
ansible_user=root
fabric_environment=production
```

## Exécution des Tests

### Tests Unitaires

```bash
# Exécuter tous les tests unitaires
./tests/scripts/run-local-tests.sh

# Exécuter un test unitaire spécifique
nix-instantiate tests/unit/modules/security/default.nix
```

### Tests d'Intégration

```bash
# Exécuter tous les tests d'intégration
./tests/scripts/run-organized-tests.sh

# Exécuter un test d'intégration spécifique
nix-instantiate tests/integration/fabric/wireguard-test.nix
```

### Tests VM

```bash
# Exécuter les tests VM
nix-build tests/vm/test-vm.nix
```

## Développement et Contribution

### Configuration de l'Environnement

```bash
# Installer les dépendances
nix-shell -p nix-info nixpkgs-fmt

# Formater le code
nixpkgs-fmt modules/**/*.nix
```

### Création de Modules

```bash
# Structure d'un nouveau module
modules/networking/new-module.nix

{ config, lib, pkgs, ... }:

{
  options.network-fabric.new-module = {
    enable = lib.mkEnableOption "Enable new module";
    
    options = {
      setting1 = lib.mkOption {
        type = lib.types.str;
        default = "default-value";
        description = "Description de l'option";
      };
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Configuration ici
  };
}
```

### Soumission de Contributions

1. Forker le dépôt
2. Créer une branche de fonctionnalité
3. Faire vos modifications
4. Tester vos modifications
5. Soumettre une pull request

## Dépannage

### Problèmes Courants

#### Erreurs d'Import

**Problème** : `error: file 'modules/network-fabric.nix' was not found`

**Solution** : Utiliser le nouveau chemin `modules/core/network-fabric.nix`

#### Échec des Tests

**Problème** : Les tests échouent après la réorganisation

**Solution** : Vérifier que tous les imports utilisent les nouveaux chemins

#### Problèmes Ansible

**Problème** : Les playbooks Ansible ne trouvent pas les rôles

**Solution** : Vérifier la structure des rôles dans `ansible/roles/`

### Commandes de Dépannage

```bash
# Vérifier la structure des modules
find modules/ -type f -name "*.nix"

# Tester un import de module
nix-instantiate --eval modules/core/network-fabric.nix

# Vérifier la syntaxe Ansible
ansible-playbook --syntax-check ansible/playbooks/deploy-fabric.yml

# Exécuter un test spécifique
nix-instantiate tests/unit/modules/security/default.nix
```

## Migration depuis l'Ancienne Structure

### Mise à Jour des Imports

**Ancien** :
```nix
imports = [
  ../modules/network-fabric.nix
  ../modules/security/default.nix
  ../modules/wireguard.nix
];
```

**Nouveau** :
```nix
imports = [
  ../modules/core/network-fabric.nix
  ../modules/security/init.nix  # Import tout
  ../modules/networking/wireguard.nix
];
```

### Mise à Jour des Chemins

| Ancien Chemin | Nouveau Chemin |
|---------------|----------------|
| `modules/network-fabric.nix` | `modules/core/network-fabric.nix` |
| `modules/frr.nix` | `modules/networking/frr.nix` |
| `modules/wireguard.nix` | `modules/networking/wireguard.nix` |
| `modules/security/*.nix` | `modules/security/init.nix` |
| `modules/networking.nix` | `modules/networking/networking.nix` |

## Documentation Supplémentaire

- **Structure du Dépôt** : `docs/reference/STRUCTURE.md`
- **Modules de Sécurité** : `modules/security/README.md`
- **Configuration Ansible** : `ansible/README.md`
- **Exécution des Tests** : `tests/README.md`

## Support

Pour obtenir de l'aide :
- Ouvrir une issue sur GitHub
- Consulter la documentation dans `docs/`
- Voir les exemples dans `examples/`

---

**Dernière Mise à Jour** : 2024-07-25
**Version** : 2.0 (Réorganisé)
**Mainteneur** : Franck
**Licence** : MIT