# Plan de Réorganisation du Dépôt NixOS Fabric

## Objectifs
- **Clarté** : Structure intuitive et facile à naviguer
- **Consistance** : Organisation cohérente entre les modules
- **Maintenabilité** : Facile à mettre à jour et étendre
- **Documentation unifiée** : Documentation centralisée et accessible
- **Séparation des préoccupations** : Modules, configuration, tests et docs bien séparés

## Nouvelle Structure Proposée

```
nixos-fabric/
├── modules/                  # Modules NixOS principaux (réorganisés)
│   ├── core/                 # Modules de base
│   │   ├── network-fabric.nix # Module principal du fabric
│   │   ├── base.nix           # Configuration de base
│   │   └── lib.nix            # Fonctions utilitaires
│   │
│   ├── networking/          # Modules réseau
│   │   ├── frr.nix           # FRR routing
│   │   ├── wireguard.nix      # WireGuard VPN
│   │   ├── networking.nix     # Configuration réseau générale
│   │   └── roles/            # Rôles réseau (spine, leaf, etc.)
│   │
│   ├── security/            # Modules de sécurité (consolidé)
│   │   ├── default.nix       # Module de sécurité principal
│   │   ├── firewall.nix      # Règles de firewall
│   │   ├── hardening.nix     # Durcissement système
│   │   ├── ssh.nix           # Configuration SSH sécurisée
│   │   ├── nftables-advanced.nix # Règles nftables avancées
│   │   └── README.md        # Documentation de sécurité
│   │
│   ├── integration/         # Modules d'intégration
│   │   ├── ansible.nix       # Intégration Ansible
│   │   └── monitoring.nix    # Intégration monitoring
│   │
│   └── utils/               # Utilitaires et helpers
│       └── lib.nix           # Fonctions utilitaires supplémentaires
│
├── hosts/                   # Configurations d'hôtes
│   ├── production/          # Environnement de production
│   │   ├── spine/           # Routeurs spine
│   │   ├── leaf/            # Routeurs leaf
│   │   └── edge/            # Routeurs edge
│   │
│   ├── staging/            # Environnement de staging
│   ├── development/         # Environnement de développement
│   ├── roles/               # Rôles d'hôtes (base, monitoring, etc.)
│   └── templates/           # Templates de configuration
│
├── ansible/                 # Configuration Ansible (simplifiée)
│   ├── inventories/         # Inventaires
│   │   ├── production/      # Inventaire production
│   │   ├── staging/         # Inventaire staging
│   │   └── development/     # Inventaire développement
│   │
│   ├── playbooks/          # Playbooks
│   │   ├── deploy-fabric.yml # Déploiement principal
│   │   ├── verify-fabric.yml # Vérification
│   │   └── roles/           # Playbooks par rôle
│   │
│   ├── roles/              # Rôles Ansible
│   │   ├── common/          # Rôle commun
│   │   ├── frr/             # Rôle FRR
│   │   ├── wireguard/       # Rôle WireGuard
│   │   └── security/        # Rôle sécurité
│   │
│   ├── templates/          # Templates
│   ├── group_vars/          # Variables de groupe
│   ├── host_vars/           # Variables d'hôte
│   └── README.md            # Documentation Ansible
│
├── examples/                # Exemples de configuration
│   ├── basic-fabric.nix     # Exemple de fabric basique
│   ├── secure-fabric.nix    # Exemple de fabric sécurisé
│   ├── wireguard-bgp.nix    # WireGuard + BGP
│   └── spine-leaf.nix       # Architecture spine-leaf
│
├── tests/                   # Tests (réorganisés)
│   ├── unit/                # Tests unitaires
│   │   ├── modules/         # Tests de modules
│   │   └── utils/           # Tests d'utilitaires
│   │
│   ├── integration/        # Tests d'intégration
│   │   ├── fabric/          # Tests de fabric complet
│   │   └── scenarios/       # Scénarios de test
│   │
│   ├── vm/                 # Tests VM
│   │   ├── configurations/  # Configurations de test
│   │   └── test-vm.nix      # Configuration VM de test
│   │
│   ├── scripts/           # Scripts de test
│   └── README.md            # Documentation des tests
│
├── docs/                    # Documentation (consolidée)
│   ├── architecture/        # Documentation d'architecture
│   ├── modules/             # Documentation des modules
│   ├── deployment/          # Guides de déploiement
│   ├── security/            # Documentation de sécurité
│   ├── development/         # Guides de développement
│   ├── examples/            # Exemples documentés
│   └── README.md            # Documentation principale
│
├── scripts/                 # Scripts utilitaires
│   ├── deployment/          # Scripts de déploiement
│   ├── development/         # Scripts de développement
│   ├── testing/             # Scripts de test
│   └── README.md            # Documentation des scripts
│
├── external/                # Configurations externes
│   └── README.md            # Documentation des configs externes
│
├── .github/                 # Configuration GitHub
│   └── workflows/           # Workflows CI/CD
│
├── .vscode/                 # Configuration VSCode (optionnel)
│   └── settings.json        # Paramètres recommandés
│
└── root files               # Fichiers racine
    ├── README.md            # Documentation principale
    ├── STRUCTURE.md         # Documentation de structure
    ├── CONTRIBUTING.md      # Guide de contribution
    ├── LICENSE              # Licence
    ├── flake.nix            # Configuration flake
    ├── flake.lock           # Verrouillage flake
    └── .gitignore           # Fichiers ignorés
```

## Changements Clés

### 1. Réorganisation des Modules
- **Avant** : Modules mélangés dans `modules/` avec des sous-dossiers incohérents
- **Après** : Structure claire par domaine fonctionnel
  - `core/` : Modules de base
  - `networking/` : Tout ce qui est réseau
  - `security/` : Tout ce qui est sécurité (consolidé)
  - `integration/` : Intégrations avec d'autres outils

### 2. Consolidation de la Sécurité
- **Problème** : `modules/security` et `modules/security-improved` en doublon
- **Solution** : Fusionner dans un seul dossier `modules/security/` avec une structure claire

### 3. Simplification Ansible
- **Problème** : `.ansible/` et `ansible/` en doublon
- **Solution** : Tout mettre dans `ansible/` avec une structure standard

### 4. Réorganisation des Tests
- **Problème** : Tests mélangés avec d'autres fichiers
- **Solution** : Structure claire par type de test (unit, integration, vm)

### 5. Documentation Centralisée
- **Problème** : Documentation éparpillée
- **Solution** : Documentation centralisée dans `docs/` avec des liens vers les modules

## Étapes de Migration

1. **Créer la nouvelle structure de dossiers**
2. **Déplacer les fichiers vers leurs nouveaux emplacements**
3. **Mettre à jour les imports et références**
4. **Consolider les modules de sécurité**
5. **Simplifier la structure Ansible**
6. **Réorganiser les tests**
7. **Mettre à jour la documentation**
8. **Nettoyer les fichiers obsolètes**
9. **Tester que tout fonctionne**

## Bénéfices Attendus

- **Navigation plus facile** : Structure logique et prévisible
- **Moins de duplication** : Élimination des doublons
- **Meilleure maintenabilité** : Organisation claire des responsabilités
- **Documentation plus accessible** : Tout au même endroit
- **Tests mieux organisés** : Plus facile à exécuter et maintenir
