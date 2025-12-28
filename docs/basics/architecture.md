# Architecture de NixOS Fabric 🏗️

## Vue d'ensemble

NixOS Fabric est conçu avec une architecture modulaire et sécurisée pour les infrastructures réseau. Voici les principaux composants :

## Composants Principaux

### 1. Couche de Configuration

```
config/
├── hardware-configuration.nix  # Configuration matérielle spécifique
├── configuration.nix           # Configuration principale
└── modules/                    # Modules personnalisés
```

### 2. Couche Réseau

```
modules/networking/
├── frr.nix                     # Configuration FRR (BGP, OSPF)
├── wireguard.nix               # Configuration WireGuard VPN
├── networking.nix              # Configuration réseau de base
└── roles/                      # Rôles réseau (spine, leaf)
```

### 3. Couche Sécurité

```
modules/security/
├── firewall.nix                # Règles de pare-feu
├── ssh.nix                     # Sécurité SSH
├── hardening.nix               # Durcissement système
└── network-security.nix        # Sécurité réseau intégrée
```

### 4. Couche Intégration

```
modules/integration/
└── ansible.nix                 # Intégration Ansible
```

## Flux de Configuration

1. **Définition des hôtes** : Configuration dans `hosts/`
2. **Import des modules** : Modules réseau et sécurité
3. **Génération de configuration** : NixOS génère la configuration système
4. **Déploiement** : Via NixOS ou Ansible
5. **Vérification** : Tests et validation

## Intégration avec NixOS

Le projet utilise le système de modules NixOS pour :

- **Configuration déclarative** : Tout est défini dans des fichiers .nix
- **Reproductibilité** : Même configuration = même résultat
- **Modularité** : Modules indépendants et réutilisables
- **Sécurité** : Configuration vérifiable et auditable

## Exemple d'Architecture Réseau

```
Internet
   │
   ▼
┌───────────────────────────────────────────────────────┐
│                   Pare-feu Périphérique                │
└───────────────────────────────────────────────────────┘
   │
   ▼
┌───────────────────────────────────────────────────────┐
│                   Routeurs Spine (BGP)                 │
└───────────────────────────────────────────────────────┘
   │
   ▼
┌───────────────────────────────────────────────────────┐
│                   Routeurs Leaf (OSPF)                 │
└───────────────────────────────────────────────────────┘
   │
   ▼
┌───────────────────────────────────────────────────────┐
│                   Serveurs et Services                 │
└───────────────────────────────────────────────────────┘
```

## Bonnes Pratiques

1. **Séparation des préoccupations** : Modules dédiés pour chaque fonction
2. **Configuration minimale** : Commencez simple, ajoutez des fonctionnalités
3. **Tests réguliers** : Validez chaque changement
4. **Documentation** : Documentez vos configurations personnalisées
5. **Sécurité par défaut** : Activez toujours les modules de sécurité