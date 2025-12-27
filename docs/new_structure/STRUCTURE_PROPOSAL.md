# Proposition de Réorganisation de la Documentation

## Problèmes Actuels

1. **Structure désorganisée** : Les fichiers sont répartis dans trop de sous-dossiers
2. **Doublons** : Plusieurs fichiers QUICKSTART et README redondants
3. **Manque de hiérarchie claire** : Difficile de trouver l'information
4. **Documentation historique mélangée** : Les fichiers historiques sont avec la documentation active
5. **Manque de cohérence** : Certains dossiers ont des README, d'autres non

## Nouvelle Structure Proposée

```
docs/
├── README.md                          # Point d'entrée principal
├── getting-started/                   # Guide pour débutants
│   ├── installation.md                # Installation de base
│   ├── quickstart.md                  # Guide rapide
│   └── tutorial.md                    # Tutoriel pas à pas
├── architecture/                      # Architecture du système
│   ├── overview.md                    # Vue d'ensemble
│   ├── components.md                  # Composants clés
│   ├── network-topology.md            # Topologie réseau
│   └── design-principles.md           # Principes de conception
├── modules/                           # Documentation des modules
│   ├── security/                      # Module de sécurité
│   │   ├── README.md                  # Vue d'ensemble
│   │   ├── quickstart.md              # Guide rapide
│   │   ├── examples.md                # Exemples
│   │   └── reference.md               # Référence complète
│   ├── ansible/                       # Module Ansible
│   │   ├── README.md                  # Vue d'ensemble
│   │   ├── integration.md             # Intégration
│   │   └── examples.md                # Exemples
│   └── networking/                    # Module réseau
│       ├── README.md                  # Vue d'ensemble
│       ├── frr.md                     # FRR
│       ├── wireguard.md               # WireGuard
│       └── examples.md                # Exemples
├── roles/                             # Système de rôles
│   ├── README.md                      # Vue d'ensemble
│   ├── spine.md                       # Rôle Spine
│   ├── leaf.md                        # Rôle Leaf
│   ├── hybrid.md                      # Rôle Hybride
│   └── usage-guide.md                  # Guide d'utilisation
├── deployment/                        # Déploiement
│   ├── README.md                      # Vue d'ensemble
│   ├── production.md                  # Déploiement production
│   ├── testing.md                     # Tests
│   └── ci-cd.md                       # CI/CD
├── development/                       # Développement
│   ├── README.md                      # Vue d'ensemble
│   ├── contributing.md                # Contribution
│   ├── conventions.md                 # Conventions
│   ├── testing.md                     # Tests
│   └── workflow.md                    # Workflow
├── reference/                         # Référence technique
│   ├── api.md                         # API des modules
│   ├── configuration.md               # Options de configuration
│   ├── cli-commands.md                # Commandes CLI
│   └── structure.md                   # Structure du projet
├── troubleshooting/                   # Dépannage
│   ├── README.md                      # Vue d'ensemble
│   ├── faq.md                         # FAQ
│   ├── debugging.md                   # Débogage
│   └── common-issues.md               # Problèmes courants
├── examples/                          # Exemples complets
│   ├── README.md                      # Vue d'ensemble
│   ├── basic-config.nix               # Configuration basique
│   ├── production-config.nix          # Configuration production
│   └── security-config.nix            # Configuration sécurité
└── historical/                        # Documentation historique
    ├── README.md                      # Vue d'ensemble
    ├── changelog.md                   # Historique des changements
    ├── release-notes/                 # Notes de version
    │   ├── v1.0.md
    │   └── v2.0.md
    └── migration-guides/               # Guides de migration
        └── v1-to-v2.md
```

## Avantages de la Nouvelle Structure

1. **Hiérarchie claire** : Organisation logique par domaine fonctionnel
2. **Moins de doublons** : Un seul fichier par sujet
3. **Meilleure découvrabilité** : Structure prévisible
4. **Séparation claire** : Documentation active vs historique
5. **Cohérence** : Chaque dossier a un README d'introduction
6. **Évolutivité** : Facile à ajouter de nouveaux contenus

## Plan de Migration

1. **Créer la nouvelle structure de dossiers**
2. **Déplacer et renommer les fichiers existants**
3. **Mettre à jour les liens internes**
4. **Créer des redirections pour les anciens liens**
5. **Mettre à jour le README principal**
6. **Valider que tous les liens fonctionnent**

## Fichiers à Créer/Modifier

### Nouveaux fichiers à créer:
- `docs/getting-started/tutorial.md`
- `docs/architecture/components.md`
- `docs/architecture/network-topology.md`
- `docs/architecture/design-principles.md`
- `docs/modules/networking/README.md`
- `docs/modules/networking/frr.md`
- `docs/modules/networking/wireguard.md`
- `docs/roles/hybrid.md`
- `docs/roles/usage-guide.md`
- `docs/deployment/testing.md`
- `docs/development/workflow.md`
- `docs/reference/cli-commands.md`
- `docs/troubleshooting/common-issues.md`
- `docs/examples/README.md`

### Fichiers à renommer/déplacer:
- `docs/getting-started/INSTALLATION.md` → `docs/getting-started/installation.md`
- `docs/getting-started/QUICKSTART.md` → `docs/getting-started/quickstart.md`
- `docs/architecture/OVERVIEW.md` → `docs/architecture/overview.md`
- `docs/architecture/QUICKSTART.md` → (à intégrer dans overview.md)
- `docs/modules/security/README.md` → `docs/modules/security/README.md` (conserver)
- `docs/modules/security/QUICKSTART.md` → `docs/modules/security/quickstart.md`
- `docs/modules/security/EXAMPLES.md` → `docs/modules/security/examples.md`
- `docs/reference/ROLES.md` → `docs/roles/README.md` (à réorganiser)
- `docs/development/CONTRIBUTING.md` → `docs/development/contributing.md`
- `docs/development/CONVENTIONS.md` → `docs/development/conventions.md`
- `docs/troubleshooting/FAQ.md` → `docs/troubleshooting/faq.md`
- `docs/troubleshooting/DEBUGGING.md` → `docs/troubleshooting/debugging.md`

### Fichiers à archiver/supprimer:
- `docs/ansible/` → (à intégrer dans modules/ansible/)
- `docs/development/ANSIBLE_INTEGRATION.md` → (à intégrer dans modules/ansible/)
- `docs/development/SYNC_STRATEGY.md` → (à intégrer dans development/workflow.md)
- `docs/historical/` → (à réorganiser dans historical/)
- `docs/reference/API.md` → (à intégrer dans reference/api.md)
- `docs/reference/STRUCTURE.md` → (à intégrer dans reference/structure.md)
