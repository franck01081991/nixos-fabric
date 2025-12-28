# Déploiement des Flakes NixOS

Ce guide explique comment déployer les configurations NixOS Fabric en utilisant les flakes. Le système a été conçu pour simplifier le déploiement et offrir plusieurs méthodes selon vos besoins.

## Table des matières

- [Prérequis](#prérequis)
- [Structure des Flakes](#structure-des-flakes)
- [Méthodes de Déploiement](#méthodes-de-déploiement)
  - [Déploiement Flake Simple](#déploiement-flake-simple)
  - [Déploiement à Distance](#déploiement-à-distance)
  - [Vérification Post-Déploiement](#vérification-post-déploiement)
- [Gestion des Secrets](#gestion-des-secrets)
- [Intégration Ansible (Optionnelle)](#intégration-ansible-optionnelle)
- [Bonnes Pratiques](#bonnes-pratiques)
- [Dépannage](#dépannage)

## Prérequis

Avant de commencer, assurez-vous que :

1. **Nix est installé** avec les flakes activés :
   ```bash
   # Vérifier que Nix est installé
   nix --version
   
   # Activer les flakes si ce n'est pas déjà fait
   mkdir -p ~/.config/nix
   echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
   ```

2. **Git est installé** pour la gestion des dépendances :
   ```bash
   git --version
   ```

3. **Les outils supplémentaires** sont disponibles :
   ```bash
   # Pour le déploiement unifié
   sudo nix-env -iA nixpkgs.ansible nixpkgs.jq
   ```

## Structure des Flakes

Le projet utilise une structure de flakes organisée dans le répertoire `flakes/` :

```
flakes/
├── flake.nix          # Configuration principale des flakes
├── flake-minimal.nix  # Configuration minimale pour les tests
└── flake-clean.nix    # Configuration propre pour les nouveaux déploiements
```

### Configuration des Flakes

Le fichier `flake.nix` principal définit :

- **Les entrées** (inputs) comme nixpkgs
- **Les sorties** (outputs) avec les configurations NixOS
- **Les modules** pour la configuration réseau
- **Les cibles** de déploiement (rtr-sapinet, rtr-noisy, etc.)

Exemple de cible dans le flake :

```nix
nixosConfigurations = {
  rtr-sapinet = mkRouter { name = "rtr-sapinet"; };
  rtr-noisy = mkRouter { name = "rtr-noisy"; };
  test = mkHost { hostname = "test"; };
};
```

## Méthodes de Déploiement

### Déploiement Flake Simple

Le script `scripts/deploy/deploy-flake.sh` permet de déployer uniquement les flakes NixOS.

**Usage :**
```bash
./scripts/deploy/deploy-flake.sh [TARGET] [OPTIONS]
```

**Options :**
- `--dry-run` : Simuler le déploiement
- `--check` : Vérifier la configuration sans l'appliquer
- `--build-only` : Construire sans déployer
- `--help` : Afficher l'aide

**Exemples :**

```bash
# Déploiement local sur rtr-sapinet
./scripts/deploy/deploy-flake.sh rtr-sapinet

# Simulation de déploiement
./scripts/deploy/deploy-flake.sh rtr-sapinet --dry-run

# Vérification de la configuration
./scripts/deploy/deploy-flake.sh rtr-sapinet --check

# Construction uniquement
./scripts/deploy/deploy-flake.sh rtr-sapinet --build-only
```

### Déploiement Unifié (Flake + Ansible)

Le script `scripts/deploy-unified.sh` combine les flakes NixOS et Ansible pour un déploiement complet.

**Usage :**
```bash
./scripts/deploy-unified.sh [TARGET] [OPTIONS]
```

**Options :**
- `--dry-run` : Simulation complète
- `--check` : Vérification sans déploiement
- `--no-flake` : Désactiver le déploiement des flakes
- `--no-ansible` : Désactiver le déploiement Ansible
- `--no-secrets` : Désactiver le déploiement des secrets
- `--remote HOST` : Déploiement distant

**Exemples :**

```bash
# Déploiement complet local
./scripts/deploy-unified.sh rtr-sapinet

# Déploiement sans Ansible
./scripts/deploy-unified.sh rtr-sapinet --no-ansible

# Déploiement distant complet
./scripts/deploy-unified.sh rtr-sapinet --remote rtr-sapinet.lan

# Simulation complète
./scripts/deploy-unified.sh rtr-sapinet --dry-run
```

### Déploiement à Distance

Pour déployer sur des machines distantes, utilisez le script dédié :

**Script de déploiement distant :**
```bash
./scripts/deploy/deploy-remote.sh [TARGET] [REMOTE_HOST] [OPTIONS]
```

**Options :**
- `--dry-run` : Simuler le déploiement
- `--check` : Vérifier la configuration sans l'appliquer
- `--build-only` : Construire sans déployer
- `--remote-user USER` : Utilisateur pour la connexion (défaut: root)
- `--help` : Afficher l'aide

**Exemples :**

```bash
# Déploiement distant simple
./scripts/deploy/deploy-remote.sh rtr-sapinet rtr-sapinet.lan

# Simulation de déploiement distant
./scripts/deploy/deploy-remote.sh rtr-sapinet rtr-sapinet.lan --dry-run

# Vérification à distance
./scripts/deploy/deploy-remote.sh rtr-sapinet rtr-sapinet.lan --check

# Avec un utilisateur différent
./scripts/deploy/deploy-remote.sh rtr-sapinet rtr-sapinet.lan --remote-user nixos
```

**Requirements pour le déploiement distant :**

1. Accès SSH configuré sur la machine cible
2. Nix installé sur la machine cible
3. Les flakes doivent être accessibles (via git ou copie locale)

## Vérification Post-Déploiement

Le script `scripts/deploy/verify-deployment.sh` permet de vérifier les déploiements locaux et distants.

**Usage :**
```bash
./scripts/deploy/verify-deployment.sh [TARGET] [OPTIONS]
```

**Options :**
- `--remote HOST` : Vérifier une machine distante
- `--remote-user USER` : Utilisateur pour la connexion distante (défaut: root)
- `--help` : Afficher l'aide

**Exemples :**

```bash
# Vérification locale
./scripts/deploy/verify-deployment.sh rtr-sapinet

# Vérification distante
./scripts/deploy/verify-deployment.sh rtr-sapinet --remote rtr-sapinet.lan

# Vérification avec un utilisateur différent
./scripts/deploy/verify-deployment.sh rtr-sapinet --remote rtr-sapinet.lan --remote-user nixos
```

Le script vérifie :
- L'état du système
- Les services critiques (SSH, DBus, systemd-journald)
- La connectivité réseau
- Les services spécifiques aux routeurs (FRR, WireGuard, BIRD)

## Gestion des Secrets

Le module `flake-secrets.nix` fournit une gestion sécurisée des secrets avec plusieurs backends.

### Configuration

Activez la gestion des secrets dans votre configuration NixOS :

```nix
{ config, lib, pkgs, ... }:
{
  network-fabric.flake-secrets.enable = true;
  network-fabric.flake-secrets.backend = "file"; # file, age, sops, vault
  
  network-fabric.flake-secrets.flakeSecrets = {
    wireguard.enable = true;
    ssh.enable = true;
  };
}
```

### Backends Supportés

1. **File** : Stockage simple dans des fichiers
2. **Age** : Chiffrement avec age
3. **Sops** : Gestion des secrets avec sops
4. **Vault** : Intégration avec HashiCorp Vault

### Utilisation

```bash
# Déployer les secrets
sudo /etc/nixos-fabric/secrets/scripts/deploy-secrets

# Vérifier les secrets
sudo /etc/nixos-fabric/secrets/scripts/verify-secrets

# Rotation des secrets
sudo /etc/nixos-fabric/secrets/scripts/rotate-secrets
```

## Intégration Ansible

### Génération d'Inventaire

Le script `scripts/utils/generate-flake-inventory.sh` génère automatiquement un inventaire Ansible à partir des cibles flake :

```bash
# Générer l'inventaire
./scripts/utils/generate-flake-inventory.sh

# L'inventaire est sauvegardé dans
# ansible/inventory/flake-hosts.ini
```

### Intégration avec les Flakes

Pour une intégration complète, vous pouvez utiliser le script unifié :

```bash
# Déploiement unifié (flakes + ansible)
./scripts/deploy/deploy-unified.sh rtr-sapinet

# Options disponibles
./scripts/deploy/deploy-unified.sh rtr-sapinet --dry-run  # Simulation
./scripts/deploy/deploy-unified.sh rtr-sapinet --check   # Vérification
./scripts/deploy/deploy-unified.sh rtr-sapinet --no-flake  # Ansible uniquement
./scripts/deploy/deploy-unified.sh rtr-sapinet --no-ansible  # Flakes uniquement
```

## Bonnes Pratiques

### 1. Utilisation des Environnements

```bash
# Pour les tests
./scripts/deploy-unified.sh test --check

# Pour la production
./scripts/deploy-unified.sh rtr-sapinet
```

### 2. Déploiement Progressif

```bash
# 1. Vérification
./scripts/deploy/deploy-flake.sh rtr-sapinet --check

# 2. Simulation
./scripts/deploy/deploy-flake.sh rtr-sapinet --dry-run

# 3. Déploiement réel
./scripts/deploy/deploy-flake.sh rtr-sapinet

# 4. Vérification post-déploiement
./scripts/deploy/verify-deployment.sh rtr-sapinet
```

### 3. Gestion des Erreurs

En cas d'échec :

1. Vérifiez les logs système : `journalctl -xe`
2. Testez la connectivité : `ping rtr-sapinet.lan`
3. Vérifiez les secrets : `/etc/nixos-fabric/secrets/scripts/verify-secrets`
4. Consultez les logs Ansible : `/var/log/ansible.log`

### 4. Mises à Jour

Pour mettre à jour les dépendances :

```bash
# Mettre à jour les flakes
nix flake update

# Reconstruire avec les nouvelles dépendances
./scripts/deploy-unified.sh rtr-sapinet
```

## Dépannage

### Problèmes Courants

**1. Erreur de flakes non activés :**
```
error: experimental Nix feature 'flakes' is disabled
```

**Solution :** Activez les flakes comme montré dans les prérequis.

**2. Cible flake introuvable :**
```
error: flake 'nixosConfigurations.rtr-unknown' was not found
```

**Solution :** Vérifiez les cibles disponibles avec `nix flake show` et utilisez une cible valide. Vous pouvez aussi utiliser le script de déploiement pour lister les cibles :

```bash
./scripts/deploy/deploy-flake.sh --help
```

**3. Échec de connexion SSH :**
```
fatal: [rtr-sapinet]: UNREACHABLE! => {"changed": false}
```

**Solution :** Vérifiez la connectivité SSH et que la clé est autorisée sur la machine cible.

**4. Problèmes de permissions sur les secrets :**
```
error: permission denied: /etc/nixos-fabric/secrets/wireguard/private.key
```

**Solution :** Vérifiez les permissions avec `ls -la /etc/nixos-fabric/secrets/` et corrigez avec `chmod 600`.

### Commandes de Diagnostic

```bash
# Vérifier l'état du système
systemctl status

# Vérifier les services critiques
systemctl status ssh dbus systemd-journald

# Vérifier la connectivité réseau
ip a
ping 8.8.8.8

# Vérifier les logs NixOS
journalctl -u nixos-rebuild

# Vérifier les logs Ansible
ansible all -m ping -i /etc/nixos-fabric/ansible/inventory/flake-hosts.ini
```

## Conclusion

Le système de déploiement des flakes NixOS Fabric offre :

- **Simplicité** : Scripts unifiés pour un déploiement facile
- **Flexibilité** : Plusieurs méthodes de déploiement selon les besoins
- **Sécurité** : Gestion intégrée des secrets
- **Automatisation** : Intégration complète avec Ansible
- **Robustesse** : Vérifications et validations intégrées

Choisissez la méthode qui correspond le mieux à votre workflow et à votre environnement.
