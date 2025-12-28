# Plan de Réorganisation pour NixOS Fabric

## Objectifs
1. Simplifier le déploiement basé sur les flakes Nix
2. Supprimer les scripts redondants ou obsolètes
3. Optimiser la structure pour le déploiement à distance
4. Conserver Ansible uniquement pour les cas où Nix n'est pas suffisant

## Structure Proposée

```
nixos-fabric/
├── flakes/                          # Configuration principale des flakes
│   ├── flake.nix                    # Flake principal
│   ├── inventory/                   # Inventaire pour déploiement distant
│   ├── modules/                     # Modules Nix réutilisables
│   └── configurations/              # Configurations spécifiques
│
├── scripts/                         # Scripts simplifiés
│   ├── deploy/                      # Scripts de déploiement
│   │   ├── deploy-flake.sh          # Déploiement principal des flakes
│   │   ├── deploy-remote.sh         # Déploiement distant
│   │   └── verify-deployment.sh     # Vérification post-déploiement
│   │
│   ├── utils/                      # Utilitaires
│   │   ├── generate-inventory.sh    # Génération d'inventaire
│   │   └── validate-config.sh       # Validation des configurations
│   │
│   └── legacy/                     # Scripts obsolètes (à supprimer)
│
├── ansible/                         # Ansible simplifié (optionnel)
│   ├── playbooks/                   # Playbooks minimaux
│   │   └── deploy-fabric.yml        # Playbook principal
│   │
│   ├── roles/                      # Rôles Ansible
│   │   └── common/                  # Configuration commune
│   │
│   └── inventory/                  # Inventaire Ansible
│
├── docs/                            # Documentation
│   ├── deployment/                  # Documentation de déploiement
│   └── flakes/                      # Documentation des flakes
│
└── README.md                        # Documentation principale
```

## Scripts à Supprimer

Les scripts suivants sont redondants ou obsolètes et peuvent être supprimés :

1. `scripts/deploy-ansible-nix.sh` - Remplacé par `deploy-unified.sh`
2. `scripts/deploy-with-ansible.sh` - Remplacé par `deploy-unified.sh`
3. `scripts/deploy-and-verify.sh` - Remplacé par `deploy-and-verify-improved.sh`
4. `scripts/deploy-wireguard.sh` - Fonctionnalité incluse dans `deploy-wireguard-bgp.sh`
5. `scripts/generate-ansible-docs.sh` - Peu utile pour le déploiement
6. `scripts/create-ansible-role.sh` - Peu utile pour le déploiement
7. `scripts/setup-ansible.sh` - Configuration mieux gérée par les flakes
8. `scripts/sync-configs.sh` - Redondant
9. `scripts/sync-bidirectional.sh` - Redondant
10. `scripts/setup-submodules.sh` - Peu utile
11. `scripts/update-submodules.sh` - Peu utile

## Scripts à Conserver et Améliorer

1. **`scripts/deploy-flake.sh`** - Script principal pour le déploiement des flakes
   - Améliorer la gestion des erreurs
   - Ajouter le support pour plusieurs cibles
   - Meilleure intégration avec le déploiement distant

2. **`scripts/deploy-unified.sh`** - Script unifié pour flakes + ansible
   - Simplifier la logique
   - Meilleure séparation des préoccupations
   - Documentation améliorée

3. **`scripts/deploy-wireguard-bgp.sh`** - Script spécifique pour wireguard/BGP
   - Conserver mais simplifier
   - Meilleure intégration avec les flakes

4. **`scripts/generate-flake-inventory.sh`** - Génération d'inventaire
   - Améliorer pour supporter plusieurs formats
   - Meilleure documentation

5. **`scripts/validate-external-configs.sh`** - Validation des configurations
   - Étendre pour supporter plus de cas d'utilisation
   - Meilleure intégration avec CI/CD

## Ansible Simplifié

Conserver Ansible uniquement pour les cas où Nix n'est pas suffisant :

1. **Gestion des secrets** - Certains secrets peuvent être mieux gérés avec Ansible Vault
2. **Configuration dynamique** - Pour les configurations qui changent fréquemment
3. **Intégration avec l'existant** - Pour les systèmes non-NixOS

Supprimer les rôles et playbooks redondants qui peuvent être remplacés par Nix.

## Étapes de Réorganisation

1. **Créer une sauvegarde** des scripts actuels dans `scripts/legacy/`
2. **Supprimer les scripts redondants** identifiés ci-dessus
3. **Réorganiser les scripts restants** dans la nouvelle structure
4. **Mettre à jour la documentation** pour refléter les changements
5. **Tester le déploiement** avec la nouvelle structure
6. **Nettoyer Ansible** en supprimant les rôles et playbooks redondants
7. **Mettre à jour le README** avec les nouvelles instructions de déploiement

## Bénéfices Attendus

1. **Simplicité** - Moins de scripts, moins de confusion
2. **Maintenabilité** - Structure claire et bien organisée
3. **Fiabilité** - Moins de redondance, moins d'erreurs
4. **Documentation** - Meilleure documentation pour le déploiement
5. **Déploiement distant** - Meilleure prise en charge du déploiement à distance

## Prochaines Étapes

1. Créer une branche pour la réorganisation
2. Implémenter les changements par étapes
3. Tester chaque étape avant de passer à la suivante
4. Documenter les changements et les raisons
5. Faire une revue de code avant la fusion