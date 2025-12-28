# Exemples de Configuration pour NixOS Fabric

Ce répertoire contient des exemples de configuration pour les nouveaux modules NixOS Fabric.

## Table des Matières

- [flake-ansible-example.nix](#flake-ansible-example-nix)
- [flake-secrets-example.nix](#flake-secrets-example-nix)
- [combined-flake-example.nix](#combined-flake-example-nix)
- [Utilisation](#utilisation)

## flake-ansible-example.nix

Exemple de configuration pour le module `flake-ansible` qui permet de déployer automatiquement des configurations NixOS en utilisant Ansible.

**Fonctionnalités :**
- Déploiement automatisé de flakes NixOS
- Stratégies de déploiement : local, remote, hybrid
- Vérification post-déploiement
- Intégration avec les playbooks Ansible

**Utilisation :**
```nix
network-fabric.flake-ansible = {
  enable = true;
  flakePath = ".";
  flakeTargets = [ "rtr-sapinet" "rtr-noisy" ];
  deploymentStrategy = "remote";
};
```

## flake-secrets-example.nix

Exemple de configuration pour le module `flake-secrets` qui gère les secrets de manière sécurisée.

**Fonctionnalités :**
- Gestion des clés WireGuard
- Gestion des clés SSH
- Support de plusieurs backends : file, age, sops, vault
- Génération automatique des clés
- Permissions sécurisées

**Utilisation :**
```nix
network-fabric.flake-secrets = {
  enable = true;
  backend = "file";
  flakeSecrets = {
    wireguard = { enable = true; };
    ssh = { enable = true; };
  };
};
```

## combined-flake-example.nix

Exemple complet combinant les deux modules pour une intégration complète.

**Fonctionnalités :**
- Déploiement automatisé + gestion des secrets
- Configuration réseau complète
- Intégration avec les services système
- Configuration de sécurité

**Utilisation :**
```nix
# Combinaison des deux modules
network-fabric.flake-ansible = { enable = true; ... };
network-fabric.flake-secrets = { enable = true; ... };
```

## Utilisation

### 1. Copier un exemple

```bash
cp examples/flake-ansible-example.nix /etc/nixos/my-config.nix
```

### 2. Intégrer dans votre configuration

```nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./my-config.nix ];
  
  # Votre configuration existante...
}
```

### 3. Appliquer la configuration

```bash
sudo nixos-rebuild switch
```

### 4. Utiliser les scripts de déploiement

```bash
# Pour flake-ansible
./scripts/deploy-unified.sh rtr-sapinet

# Pour flake-secrets
sudo /etc/nixos-fabric/secrets/scripts/deploy-secrets
```

## Bonnes Pratiques

1. **Tester avant de déployer** :
   ```bash
   ./scripts/deploy-unified.sh rtr-sapinet --check
   ```

2. **Utiliser le mode dry-run** :
   ```bash
   ./scripts/deploy-unified.sh rtr-sapinet --dry-run
   ```

3. **Déployer progressivement** :
   ```bash
   # Étape 1: Vérification
   ./scripts/deploy-unified.sh rtr-sapinet --check
   
   # Étape 2: Simulation
   ./scripts/deploy-unified.sh rtr-sapinet --dry-run
   
   # Étape 3: Déploiement réel
   ./scripts/deploy-unified.sh rtr-sapinet
   ```

## Dépannage

Si vous rencontrez des problèmes :

1. Vérifiez les logs : `journalctl -xe`
2. Testez la connectivité : `ping rtr-sapinet`
3. Vérifiez les secrets : `/etc/nixos-fabric/secrets/scripts/verify-secrets`
4. Consultez les logs Ansible : `/var/log/ansible.log`

## Documentation Complète

Pour plus d'informations, consultez la documentation complète dans `docs/setup/flake-deployment.md`.
