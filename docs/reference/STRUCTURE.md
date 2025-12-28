# Structure de Référence du Projet 🏗️

## Vue d'ensemble

Ce document décrit la structure organisée du projet NixOS Fabric après la refactorisation.

## Structure du Projet

```
nixos-fabric/
├── docs/                  # Documentation principale
│   ├── basics/            # Concepts de base
│   │   ├── what-is-this.md
│   │   ├── how-it-works.md
│   │   └── architecture.md
│   ├── setup/             # Guides d'installation et configuration
│   │   ├── quick-start.md
│   │   ├── basic-config.md
│   │   ├── networking.md
│   │   └── security.md
│   ├── examples/          # Exemples pratiques
│   │   ├── simple-config.md
│   │   ├── basic-network.md
│   │   ├── basic-security.md
│   │   └── simple-wireguard.md
│   ├── troubleshooting/   # Résolution de problèmes
│   │   ├── common-errors.md
│   │   ├── network-issues.md
│   │   └── security-issues.md
│   └── reference/         # Documentation de référence
│       └── STRUCTURE.md
├── modules/               # Modules NixOS
│   ├── core/              # Modules principaux
│   │   ├── base.nix
│   │   ├── lib.nix
│   │   └── network-fabric.nix
│   ├── networking/        # Modules réseau
│   │   ├── frr.nix
│   │   ├── wireguard.nix
│   │   ├── networking.nix
│   │   └── roles/
│   ├── security/          # Modules sécurité
│   │   ├── init.nix
│   │   ├── index.nix
│   │   ├── default.nix
│   │   ├── firewall.nix
│   │   ├── hardening.nix
│   │   ├── ssh.nix
│   │   ├── nftables-advanced.nix
│   │   ├── network-security.nix
│   │   ├── README.md
│   │   └── QUICKSTART.md
│   └── integration/       # Modules d'intégration
│       └── ansible.nix
├── hosts/                 # Configurations d'hôtes
│   ├── production/        # Environnement de production
│   ├── development/       # Environnement de développement
│   └── test-vm/           # Machines de test
├── examples/              # Exemples de configuration
│   ├── example-configuration.nix
│   ├── network-security-config.nix
│   ├── security-example.nix
│   └── security-improved-example.nix
├── tests/                 # Tests
│   ├── unit/              # Tests unitaires
│   ├── integration/       # Tests d'intégration
│   └── scripts/           # Scripts de test
├── scripts/               # Scripts utilitaires
│   ├── deployment/
│   ├── development/
│   ├── setup/
│   └── testing/
├── ansible/               # Configuration Ansible
│   ├── roles/
│   ├── playbooks/
│   └── inventory/
├── flakes/                # Configuration Flakes
│   ├── flake.nix
│   ├── flake.lock
│   └── flake-minimal.nix
├── .github/               # Configuration GitHub
│   └── workflows/
└── external/              # Configurations externes
    ├── rtr-noisy-config/
    └── rtr-sapinet-config/
```

## Modules Principaux

### Modules Core

- **base.nix** : Configuration de base pour tous les hôtes
- **lib.nix** : Fonctions utilitaires et helpers
- **network-fabric.nix** : Module principal du projet

### Modules Networking

- **frr.nix** : Configuration FRR (BGP, OSPF, EVPN)
- **wireguard.nix** : Configuration WireGuard VPN
- **networking.nix** : Configuration réseau de base
- **roles/** : Rôles réseau (spine, leaf, etc.)

### Modules Security

- **init.nix** : Point d'entrée principal pour la sécurité
- **index.nix** : Documentation et référence du module
- **default.nix** : Module de sécurité principal
- **firewall.nix** : Configuration du pare-feu
- **hardening.nix** : Durcissement système
- **ssh.nix** : Sécurité SSH
- **nftables-advanced.nix** : Règles avancées nftables
- **network-security.nix** : Sécurité réseau intégrée

### Modules Integration

- **ansible.nix** : Intégration avec Ansible

## Documentation

### Structure de la Documentation

La documentation est organisée en plusieurs sections :

1. **basics/** : Concepts fondamentaux et architecture
2. **setup/** : Guides d'installation et configuration
3. **examples/** : Exemples pratiques et configurations
4. **troubleshooting/** : Résolution de problèmes courants
5. **reference/** : Documentation de référence

### Conventions de Documentation

- **Format** : Markdown (.md)
- **Style** : Clair, concis, avec des exemples
- **Structure** : Titres hiérarchiques (#, ##, ###)
- **Code** : Blocs de code avec syntax highlighting
- **Liens** : Liens relatifs entre les documents

## Configuration des Hôtes

### Structure des Hôtes

```
hosts/
├── production/            # Environnement de production
│   ├── edge/              # Routeurs edge
│   ├── spine/             # Routeurs spine
│   └── leaf/              # Routeurs leaf
├── development/           # Environnement de développement
│   ├── test1/             # Machine de test 1
│   └── test2/             # Machine de test 2
└── test-vm/               # Machine virtuelle de test
    ├── default.nix        # Configuration principale
    └── hardware-configuration.nix
```

### Fichiers de Configuration

Chaque hôte doit avoir au minimum :

1. **default.nix** : Configuration principale
2. **hardware-configuration.nix** : Configuration matérielle spécifique

## Exemples de Configuration

### Structure des Exemples

```
examples/
├── example-configuration.nix       # Configuration de base
├── network-security-config.nix     # Sécurité réseau
├── security-example.nix            # Exemple de sécurité
└── security-improved-example.nix   # Sécurité avancée
```

### Utilisation des Exemples

Les exemples peuvent être utilisés comme :

1. **Point de départ** pour de nouvelles configurations
2. **Référence** pour des configurations spécifiques
3. **Template** pour des scénarios courants

## Tests

### Structure des Tests

```
tests/
├── unit/                  # Tests unitaires
│   ├── modules/           # Tests de modules
│   ├── security/          # Tests de sécurité
│   └── networking/        # Tests réseau
├── integration/           # Tests d'intégration
│   ├── fabric/           # Tests d'infrastructure
│   └── scenarios/         # Scénarios de test
└── scripts/               # Scripts de test
    ├── run-tests.sh       # Exécuteur principal
    └── run-organized-tests.sh
```

### Exécution des Tests

```bash
# Tests unitaires
cd tests/unit
nix-build default.nix

# Tests d'intégration
cd tests/integration
./run-tests.sh

# Tests organisés
./tests/scripts/run-organized-tests.sh
```

## Scripts Utilitaires

### Catégories de Scripts

1. **deployment/** : Scripts de déploiement
2. **development/** : Scripts de développement
3. **setup/** : Scripts de configuration
4. **testing/** : Scripts de test

### Scripts Importants

- **setup-submodules.sh** : Initialisation des sous-modules
- **deploy-and-verify.sh** : Déploiement et vérification
- **run-organized-tests.sh** : Tests organisés

## Ansible Integration

### Structure Ansible

```
ansible/
├── roles/                 # Rôles Ansible
│   ├── common/            # Configuration commune
│   ├── frr/               # Configuration FRR
│   └── wireguard/         # Configuration WireGuard
├── playbooks/             # Playbooks
│   ├── deploy-fabric.yml  # Déploiement principal
│   └── verify-fabric.yml  # Vérification
└── inventory/             # Inventaire
    ├── production/        # Production
    └── development/       # Développement
```

### Utilisation d'Ansible

```bash
# Déploiement
ansible-playbook -i inventory/production playbooks/deploy-fabric.yml

# Vérification
ansible-playbook -i inventory/production playbooks/verify-fabric.yml
```

## Flakes

### Configuration Flakes

```
flakes/
├── flake.nix             # Configuration principale
├── flake.lock            # Verrouillage des versions
└── flake-minimal.nix     # Configuration minimale
```

### Utilisation des Flakes

```bash
# Construire avec flakes
nix build .#package

# Déployer avec flakes
nixos-rebuild switch --flake .#host
```

## Bonnes Pratiques

### 1. Organisation

- **Séparez** les préoccupations en modules
- **Utilisez** des noms descriptifs
- **Documentez** chaque module
- **Testez** chaque configuration

### 2. Sécurité

- **Activez** toujours les modules de sécurité
- **Utilisez** des ports non standards
- **Désactivez** l'authentification par mot de passe
- **Limitez** les accès utilisateurs

### 3. Réseau

- **Documentez** les schémas d'adressage
- **Testez** avant déploiement
- **Surveillez** les performances
- **Sauvegardez** les configurations

### 4. Déploiement

- **Testez** en environnement de développement
- **Validez** avec les scripts de test
- **Déployez** progressivement
- **Surveillez** après déploiement

## Évolutions Futures

### Améliorations Prévues

1. **Documentation** : Plus d'exemples et de guides
2. **Tests** : Couverture de test plus complète
3. **Modules** : Plus de modules réseau et sécurité
4. **Intégration** : Meilleure intégration avec d'autres outils
5. **Performance** : Optimisation des performances

### Contributions Bienvenues

Nous accueillons les contributions dans tous les domaines :

- Documentation
- Tests
- Modules
- Exemples
- Intégration
- Performance

Voir [CONTRIBUTING.md](../CONTRIBUTING.md) pour plus d'informations.

## Historique des Changements

### Version 1.0 (Organized)

- **Structure** : Réorganisation complète du projet
- **Documentation** : Documentation complète et organisée
- **Modules** : Modules mieux organisés et documentés
- **Tests** : Tests organisés et complets
- **Exemples** : Exemples clairs et utiles

### Version 0.x (Initial)

- Structure initiale du projet
- Modules de base
- Documentation minimale
- Tests basiques

## Références

- [Documentation NixOS](https://nixos.org/manual/)
- [Documentation FRR](https://docs.frrouting.org/)
- [Documentation WireGuard](https://www.wireguard.com/)
- [Guide de Contribution](CONTRIBUTING.md)
- [Code de Conduite](CODE_OF_CONDUCT.md)