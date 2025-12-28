# Guide de Contribution à NixOS Fabric 🐒

Merci de votre intérêt pour contribuer à NixOS Fabric ! Ce guide vous aidera à comprendre comment contribuer efficacement au projet.

## Table des Matières

- [Code de Conduite](#code-de-conduite)
- [Comment Contribuer](#comment-contribuer)
- [Configuration du Projet](#configuration-du-projet)
- [Structure du Projet](#structure-du-projet)
- [Conventions de Code](#conventions-de-code)
- [Processus de Contribution](#processus-de-contribution)
- [Tests et Validation](#tests-et-validation)
- [Documentation](#documentation)
- [Support et Communication](#support-et-communication)
- [Licence](#licence)

## Code de Conduite

En participant à ce projet, vous acceptez de respecter notre [Code de Conduite](CODE_OF_CONDUCT.md). Veuillez le lire attentivement avant de contribuer.

## Comment Contribuer

### Types de Contributions

Nous accueillons plusieurs types de contributions :

- **Bug Reports** : Signaler des bugs et problèmes
- **Feature Requests** : Proposer de nouvelles fonctionnalités
- **Code Contributions** : Corriger des bugs, ajouter des fonctionnalités
- **Documentation** : Améliorer ou traduire la documentation
- **Tests** : Ajouter ou améliorer des tests
- **Exemples** : Fournir des exemples de configuration
- **Reviews** : Revoir les pull requests des autres

### Pour les Débutants

Si vous êtes nouveau dans le projet, voici quelques bonnes premières contributions :

- Corriger des fautes de frappe dans la documentation
- Améliorer les exemples existants
- Ajouter des tests pour des fonctionnalités existantes
- Traduire la documentation
- Signaler des bugs avec des étapes de reproduction claires

## Configuration du Projet

### Prérequis

- NixOS ou Nix installé
- Git
- Connaissance de base de Nix
- Connaissance des réseaux (pour les contributions réseau)

### Configuration Initial

```bash
# Cloner le dépôt
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric

# Initialiser les sous-modules
./scripts/setup-submodules.sh

# Configurer l'environnement
direnv allow
```

### Configuration pour le Développement

```bash
# Créer un environnement de développement
nix-shell

# Ou utiliser direnv
echo "use nix" > .envrc
direnv allow
```

## Structure du Projet

```
nixos-fabric/
├── docs/                  # Documentation
│   ├── basics/            # Concepts de base
│   ├── setup/             # Guides d'installation
│   ├── examples/          # Exemples pratiques
│   └── troubleshooting/   # Résolution de problèmes
├── modules/               # Modules NixOS
│   ├── core/              # Modules principaux
│   ├── networking/        # Modules réseau
│   ├── security/          # Modules sécurité
│   └── integration/       # Modules d'intégration
├── hosts/                 # Configurations d'hôtes
│   ├── production/        # Environnement de production
│   ├── development/       # Environnement de développement
│   └── test-vm/           # Machines de test
├── examples/              # Exemples de configuration
├── tests/                 # Tests
├── scripts/               # Scripts utilitaires
└── ansible/               # Configuration Ansible
```

## Conventions de Code

### Conventions Nix

- **Indentation** : 2 espaces (pas de tabulations)
- **Noms de modules** : en minuscules avec des tirets (ex: `frr.nix`)
- **Noms de variables** : en camelCase (ex: `enableBgp`)
- **Commentaires** : Utilisez `#` pour les commentaires
- **Documentation** : Ajoutez des commentaires clairs pour les configurations complexes

### Conventions de Commit

Nous utilisons les [Conventional Commits](https://www.conventionalcommits.org/) :

- `feat:` - Nouvelle fonctionnalité
- `fix:` - Correction de bug
- `docs:` - Changements dans la documentation
- `style:` - Changements de formatage
- `refactor:` - Refactorisation de code
- `perf:` - Amélioration de performance
- `test:` - Ajout ou modification de tests
- `chore:` - Changements divers

**Exemples** :
```bash
git commit -m "feat: ajouter support BGP pour FRR"
git commit -m "fix: corriger bug de routage inter-VLAN"
git commit -m "docs: ajouter guide de démarrage rapide"
```

### Conventions de Branches

- `master` - Branche principale (stable)
- `develop` - Branche de développement
- `feature/*` - Nouvelles fonctionnalités
- `bugfix/*` - Corrections de bugs
- `docs/*` - Mises à jour de documentation
- `refactor/*` - Refactorisation

## Processus de Contribution

### 1. Signaler un Bug

1. Vérifiez que le bug n'a pas déjà été signalé
2. Créez un nouveau issue avec :
   - Titre clair et descriptif
   - Étapes pour reproduire le bug
   - Comportement attendu vs comportement actuel
   - Version de NixOS et du projet
   - Logs pertinents

### 2. Proposer une Fonctionnalité

1. Vérifiez que la fonctionnalité n'a pas déjà été proposée
2. Créez un nouveau issue avec :
   - Description claire de la fonctionnalité
   - Cas d'utilisation
   - Avantages pour le projet
   - Exemples de configuration si applicable

### 3. Soumettre une Pull Request

1. Forkez le dépôt
2. Créez une nouvelle branche :
   ```bash
   git checkout -b feature/ma-nouvelle-fonctionnalite
   ```
3. Faites vos changements
4. Testez vos changements
5. Commitez avec des messages clairs
6. Poussez votre branche :
   ```bash
   git push origin feature/ma-nouvelle-fonctionnalite
   ```
7. Créez une Pull Request avec :
   - Titre clair
   - Description des changements
   - Référence à l'issue si applicable
   - Instructions de test

### 4. Processus de Review

1. Votre PR sera revue par les mainteneurs
2. Des commentaires et suggestions peuvent être faits
3. Apportez les corrections nécessaires
4. Une fois approuvée, votre PR sera mergée

## Tests et Validation

### Tests Unitaires

```bash
# Exécuter les tests unitaires
cd tests/unit
nix-build default.nix
```

### Tests d'Intégration

```bash
# Exécuter les tests d'intégration
cd tests/integration
./run-tests.sh
```

### Tests de Configuration

```bash
# Tester une configuration spécifique
nix-instantiate --eval -E 'import ./hosts/test-vm/default.nix'
```

### Validation avant Commit

Avant de soumettre une PR, assurez-vous que :

1. Le code compile sans erreurs
2. Les tests passent
3. La documentation est à jour
4. Les exemples fonctionnent
5. Les commits suivent les conventions

## Documentation

### Ajouter de la Documentation

1. La documentation est dans le dossier `docs/`
2. Utilisez le format Markdown
3. Suivez la structure existante
4. Ajoutez des exemples clairs
5. Utilisez des liens relatifs

### Traduire la Documentation

1. Forkez le dépôt
2. Traduisez les fichiers Markdown
3. Conservez la structure et le formatage
4. Soumettez une PR avec vos traductions

### Conventions de Documentation

- Utilisez des titres clairs avec `#`, `##`, `###`
- Ajoutez des exemples de code avec des blocs de code
- Utilisez des listes pour les étapes
- Ajoutez des notes et avertissements si nécessaire
- Documentez les options de configuration

## Support et Communication

### Où Obtenir de l'Aide

- **GitHub Issues** : Pour les bugs et feature requests
- **GitHub Discussions** : Pour les questions générales
- **Email** : franck01081991@gmail.com (pour les questions privées)

### Comment Aider les Autres

- Répondez aux questions sur les issues
- Revoir les PR des autres
- Participez aux discussions
- Aidez à améliorer la documentation

## Licence

En contribuant à ce projet, vous acceptez que vos contributions soient licenciées sous la [Licence MIT](LICENSE).

## Remerciements

Merci de prendre le temps de contribuer à NixOS Fabric ! Votre contribution aide à améliorer le projet pour tout le monde.

**Happy Hacking!** 🐒